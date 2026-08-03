class_name DefenseChoiceResolver
extends RefCounted

## Given attack params and defender state, chooses parry vs dodge and computes parry capacity/timing.
## Footing: Tier 4.2 spacing/state mults here — Tier 4.4 PA stamp + geometry preview: **`apply_defender_step_*`**,
## **`parry_eval_step_deg_for_defender`**, **`dodge_eval_step_deg_for_defender`**, **`guard_angle_deg_with_step_deg`**,
## dodge-path **`clear_on_exchange_end`**. LIVE_PATHS **`#wf-tier-44-pa`** . **`#wf-layer-labels`**.
## Pure function: returns a dict of computed values; caller handles resolution and mutation.
## Tier 4.2: **`_guard_zone_modifier`** may treat the real hit line as the defender's guard focus when passive
## **`parry_readiness`**  -  stance **`feint_readthrough`** clears
## **`CombatConstants.FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** (omit extra arg '' ' harness compatibility / static
## calls).
## Tier 4.2 footwork: pair **`distance_to[attacker]`** scales **`parry_c_d`** (CLOSE / LONG vs MID) and
## **`dodge_chance`** at CLOSE / LONG (**`CombatConstants.DEFENSE_SPACING_*`**); **`STATE_RECOVERING`** / settled
## **`STATE_WAITING`** scale reported **`dodge_chance`** via **`defense_footwork_recovering_dodge_mult_for_cause`** /
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** (waiting skipped when off-balance); feint-only spacing on dodge telegraph
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**), AI feint-listing readiness
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**), and **`_guard_zone_modifier`** read-through
## (**`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**).
## Tier 4.2 tempo: non-empty **`feint_part`** on **`pa`** uses
## **`CombatConstants.commitment_fraction_for_pending_attack`** (larger committed fraction '' ' shorter
## **`effective_wind_up`** for passive parry timing vs plain attacks).
## Tier 4.2 telegraph delay: optional **`feint_target_reveal_at_progress`** on feint moves (stamped on **`pa`** in
## **`AttackWindUpStarter`**) scales feint read-through / dodge-telegraph readiness via
## **`CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT`** until wind-up progress reaches that fraction
## (**`_feint_readiness_reveal_mult`**).
## Incoming **`contact_type`** (stab/cut/blunt) scales passive parry readiness after
## **`PassiveParryContext.get_passive_parry_readiness`**
## (**`CombatConstants.passive_parry_readiness_incoming_contact_mult`**).
## Defender **`stamina`** scales the **readiness** used for feint read-through / guard-zone / dodge telegraph
## (**`_defender_passive_readiness_stamina_mult`** '' '
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`**) without folding into **`parry_c_d`'s**
## `pr_base` term (post-alignment stamina curve still applies once to **`parry_c_d`**). Reported **`choose_defense`**
## **`parry_readiness`** applies **`_feint_readiness_reveal_mult`** for non-empty **`feint_part`**; passive-parry
## **alignment wobble** uses the same (**`pr_guard_feint`** / **`pr_guard_feint_late`**) so
## **`DefenseResolutionHandler`** matches **`choose_defense`**. **`CombatAIActionPicker`** feint-move listing:
## defender-readiness lerp (**`read_m`**, incl. **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`** on **`pr_def`**)  -
## **`_feint_readiness_reveal_mult`** when live **`pending_attack`** targets the listed defender, then defender footwork
## (**`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** /
## **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** /
## **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**) — orthogonal to dodge footwork on **`dodge_chance`** above.


## Tier 3.1: `AttackResolver` / **`CombatStrikeStamping.stamp_attack_pair_geometry_on_dict`** set
## **`depth_polearm_attack`**, **`depth_polearm_allows_low_targets`**, and **`depth_polearm_lane_type`** when
## rank''deg'1 depth spear lane is live.
static func _depth_polearm_lane_is_open(pa: Dictionary) -> bool:
    ## `stamp_attack_pair_geometry_on_dict` always sets the key (often `""`). Empty / unknown '' ' `allows_low`
    ## (baseline `pa`); explicit ids match **`CombatConstants`** (`open` / `over_shoulder`).
    var lt: String = pa.get(DataKeys.PA_DEPTH_POLEARM_LANE, "").strip_edges()
    if lt == "open":
        return true
    if lt == "over_shoulder":
        return false
    return pa.get(DataKeys.PA_DEPTH_POLEARM_ALLOWS_LOW, true)


static func depth_spear_tight_lane_parry_c_d_mult(pa: Dictionary) -> float:
    if pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false) != true:
        return 1.0
    if _depth_polearm_lane_is_open(pa):
        return 1.0
    return CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT


static func depth_spear_open_lane_stab_parry_p_a_mult(pa: Dictionary, attack_type: String) -> float:
    if pa.get(DataKeys.PA_DEPTH_POLEARM_ATTACK, false) != true:
        return 1.0
    if not _depth_polearm_lane_is_open(pa):
        return 1.0
    var md: Dictionary = WeaponConstants.get_move(attack_type)
    var ct: String = str(md.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT)).to_lower()
    if ct != WeaponConstants.ATTACK_TYPE_STAB:
        return 1.0
    return CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT


## Returns dict with: defense, can_parry_in_time, parry_p_a, parry_c_d, parry_time_to_react,
## parry_readiness, parry_off_balance, late_parry, is_block_parry, m_a_parry, m_d_parry,
## s_atk_parry, s_d_parry, dodge_chance, dodge_eval_part (may track **`feint_part`** telegraph when not read-through),
## effective_redirect.
## **`parry_readiness`** (result): passive readiness  -  stamina curve  -  **`_feint_readiness_reveal_mult`** when
## **`feint_part`** is non-empty (else unchanged); matches feint dodge-telegraph / guard-zone reporting. Passive-parry
## **guard-angle wobble** uses **`pr_guard_feint`** / **`pr_guard_feint_late`** (same product) so angle noise tracks
## telegraph delay; **`parry_c_d`** still uses undamped **`pr_base`** in **`parry_capacity_mult * pr_base`**.
static func choose_defense(
    pa: Dictionary,
    atk: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    archetype: Dictionary,
    velocity_override: float,
    manager: Node = null
) -> Dictionary:
    var result: Dictionary = {
        "defense": "dodge",
        "can_parry_in_time": false,
        "parry_p_a": 0.0,
        "parry_c_d": 0.0,
        "parry_time_to_react": 0.0,
        "parry_readiness": 0.0,
        "parry_off_balance": false,
        "late_parry": false,
        "is_block_parry": false,
        "m_a_parry": 0.0,
        "m_d_parry": 0.0,
        "m_a_velocity": 0.0,
        "s_atk_parry": 100.0,
        "s_d_parry": 100.0,
        "dodge_chance": 0.0,
        "dodge_eval_part": "",
        "effective_redirect": 2.5
    }
    result.dodge_eval_part = BodyPartConstants.get_weighted_random_part(targetable) if not targetable.is_empty() else ""
    _apply_feint_telegraph_bias_to_dodge_eval_part(pa, tgt, atk, targetable, result, attack_type)
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)

    var dodge_chance: float = CombatantEntityAccess.get_dodge_chance(tgt)
    dodge_chance *= CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "evasion", CombatantEntityAccess.get_weapon(tgt)
    )
    dodge_chance *= pa.get(DataKeys.PA_TACTICAL_AMBUSH_MULT, 1.0)
    dodge_chance *= TacticalCombat.surround_defense_multiplier_from_pa(tgt, pa)
    dodge_chance *= _spacing_band_dodge_chance_mult(tgt, atk)
    dodge_chance *= CombatMuscleFatigue.dodge_chance_mult(tgt)
    if CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_RECOVERING:
        dodge_chance *= CombatConstants.defense_footwork_recovering_dodge_mult_for_cause(
            str(tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "skip"))
        )
    elif (
        CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_WAITING
        and not PassiveParryContext.is_off_balance(tgt)
    ):
        dodge_chance *= CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT
    elif CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_FORM_SWITCH:
        dodge_chance *= CombatFormSwitch.dodge_penalty_during_switch(CombatFormSwitch.transition_progress(tgt))
    result.dodge_chance = dodge_chance

    var already_used_defense: bool = pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
    var st_def: String = CombatantEntityAccess.state_str(tgt)
    if pa.get(DataKeys.PA_PARRY_CHOICE_BLOCKED, false):
        result.effective_redirect = _get_effective_redirect(tgt)
        return result
    if (
        already_used_defense
        or st_def == CombatConstants.STATE_WIND_UP
        or st_def == CombatConstants.STATE_MEDICAL_WIND_UP
    ):
        result.effective_redirect = _get_effective_redirect(tgt)
        return result

    var wind_up_duration: float = pa.get(DataKeys.PA_WIND_UP_DURATION, 0.5)
    var comm_frac: float = CombatConstants.commitment_fraction_for_pending_attack(pa)
    var effective_wind_up: float = wind_up_duration * (1.0 - comm_frac)
    var can_parry_in_time: bool = false
    var parry_p_a: float = 0.0
    var parry_c_d: float = 0.0
    var parry_time_to_react: float = 0.0
    var parry_capacity_mult: float = 0.0
    var parry_readiness: float = 0.0
    var parry_off_balance: bool = false
    var late_parry: bool = false

    if CombatantEntityAccess.has_weapon(tgt) and CombatantEntityAccess.has_passive_parry_reaction_time(tgt):
        var def_weapon = CombatantEntityAccess.get_weapon(tgt)
        if def_weapon != null and effective_wind_up > 0.0:
            var atk_weapon = CombatantEntityAccess.get_weapon(atk)
            var reaction_time: float = CombatantEntityAccess.get_passive_parry_reaction_time(tgt)
            if reaction_time < effective_wind_up and atk_weapon != null:
                can_parry_in_time = true
                var parry_eval_step_deg: float = CombatFootwork.parry_eval_step_deg_for_defender(
                    tgt, CombatantEntityAccess.id_int(atk), manager
                )
                var move_def: Dictionary = WeaponConstants.get_move(attack_type)
                var contact_type: String = str(move_def.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
                var m_a_striking: float = CombatantEntityAccess.weapon_striking_mass_kg(atk_weapon, contact_type)
                var attack_instance = AttackInstance.new(
                    attack_type, pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
                )
                attack_instance.archetype = archetype
                attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
                var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
                v_intent *= StrikeRealismProfile.velocity_intent_mult_from_pa(
                    pa,
                    atk_weapon,
                    attack_type,
                    float(pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)),
                    archetype
                )
                parry_time_to_react = effective_wind_up - reaction_time
                var parry_progress: float = 1.0 - clampf(parry_time_to_react / maxf(0.001, effective_wind_up), 0.0, 1.0)
                parry_p_a = m_a_striking * v_intent * CombatTiming.velocity_curve_factor(parry_progress)
                var c_d_full: float = _compute_parry_c_d(def_weapon, tgt, contact_type)
                parry_capacity_mult = _get_parry_capacity_mult(def_weapon, tgt, parry_time_to_react)
                parry_c_d = c_d_full
                var pr_base: float = PassiveParryContext.get_passive_parry_readiness(tgt)
                pr_base *= CombatConstants.passive_parry_readiness_incoming_contact_mult(contact_type)
                var st_rd: float = _defender_passive_readiness_stamina_mult(tgt)
                var ex_rd: float = _defender_passive_readiness_exhaustion_mult(tgt)
                var yomi_rd: float = CombatAttention.yomi_defense_readiness_mult(tgt, CombatantEntityAccess.id_int(atk))
                parry_readiness = clampf(
                    pr_base * st_rd * ex_rd * CombatAttention.focus_effective(tgt) * yomi_rd, 0.0, 1.0
                )
                var pr_guard_feint: float = (
                    parry_readiness
                    * _feint_readiness_reveal_mult(pa, atk)
                    * CombatAttention.focus_line_mult_for_feint(tgt, pa)
                )
                parry_off_balance = PassiveParryContext.is_off_balance(tgt)
                var v_par_diff_mult: float = _parry_velocity_difficulty_mult(v_intent if v_intent > 0 else WeaponConstants.VELOCITY_MAX_M_S * 0.7, pa)
                parry_c_d *= parry_capacity_mult * pr_base * v_par_diff_mult
                if parry_off_balance:
                    parry_c_d *= CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
                parry_c_d *= _parry_bonus_if_active(tgt)
                # Guard zone: parry bonus when target_part == guard_zone, penalty when unguarded (feint D).
                parry_c_d *= _guard_zone_modifier(
                    pa, tgt, targetable, attack_type, pr_guard_feint, CombatantEntityAccess.id_int(atk)
                )
                # BP2: angle-based alignment — parry capacity 'I  cos(). Use blade position at parry contact, not arc
                # end.
                # Arc tracking: weapon angle at parry_progress = where blade will be when defender meets it.
                var align_ctx: Dictionary = {}
                var arc_start: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, 0.0)
                var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
                if arc_end >= -900.0:
                    var attack_angle_at_contact: float = CombatConstants.get_arc_angle_at_progress(
                        arc_start, arc_end, parry_progress
                    )
                    attack_angle_at_contact = CombatFootwork.apply_offset_to_angle_deg(attack_angle_at_contact, atk)
                    var wobble: Dictionary = CombatantEntityAccess.parry_wobble_context(def_weapon, pr_guard_feint)
                    align_ctx = {
                        "attack_angle_deg": attack_angle_at_contact,
                        "guard_angle_deg":
                        CombatFootwork.guard_angle_deg_with_step_deg(tgt, wobble, parry_eval_step_deg),
                    }
                var al_raw: float = _get_line_alignment(
                    attack_type, tgt, pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""), align_ctx
                )
                var al: float = _alignment_with_arm_interpose(
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    al_raw,
                    targetable,
                    result
                )
                result[DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT] = al
                parry_c_d *= _get_contact_geometry(al, def_weapon)
                # Stamina: non-linear fatigue curve — parry capacity scales with stamina_factor
                var st_ratio: float = CombatantEntityAccess.stamina_ratio(tgt)
                parry_c_d *= lerpf(
                    CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(st_ratio)
                )
                parry_c_d *= CombatExhaustion.timing_mult_for_combatant(tgt)
                parry_c_d *= TacticalCombat.surround_defense_multiplier_from_pa(tgt, pa)
                parry_c_d *= pa.get(DataKeys.PA_TACTICAL_AMBUSH_MULT, 1.0)
                if CombatConstants.combat_debug_active():
                    var dbg_tgt: String = CombatantEntityAccess.get_display_name(tgt)
                    CombatDebug.log(
                        (
                            "parry_align %s guard=%s atk=%s raw=%.3f align=%.3f"
                            % [
                                dbg_tgt,
                                tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT),
                                move_def.get(DataKeys.PA_ATTACK_LINE, "high"),
                                al_raw,
                                al
                            ]
                        )
                    )
                var cal_suffix: String = ""
                if not align_ctx.is_empty():
                    cal_suffix = (
                        " atk_deg=%.0f guard_deg=%.0f"
                        % [align_ctx.get(DataKeys.ALIGNMENT_ATTACK_ANGLE_DEG, 0.0), align_ctx.get(DataKeys.ALIGNMENT_GUARD_ANGLE_DEG, 0.0)]
                    )
                var interpose_note: String = ""
                if result.has(DataKeys.RESULT_ARM_INTERPOSE_BOOST) and result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] > 0.0:
                    interpose_note = (
                        " interpose_arm=%s boost=%.3f"
                        % [result.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""), result[DataKeys.RESULT_ARM_INTERPOSE_BOOST]]
                    )
                CombatDebug.calibration_log(
                    (
                        "parry_pre atk_line=%s guard=%s raw=%.3f align=%.3f parry_c_d=%.2f%s%s"
                        % [
                            WeaponConstants.get_move(attack_type).get(DataKeys.PA_ATTACK_LINE, "high"),
                            tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT),
                            al_raw,
                            al,
                            parry_c_d,
                            cal_suffix,
                            interpose_note
                        ]
                    )
                )
            elif atk_weapon != null:
                # Late parry: reflexive/partial contact when "too late" (only if on-time branch did not run).
                can_parry_in_time = true
                late_parry = true
                var parry_eval_step_deg_late: float = CombatFootwork.parry_eval_step_deg_for_defender(
                    tgt, CombatantEntityAccess.id_int(atk), manager
                )
                var move_def_late: Dictionary = WeaponConstants.get_move(attack_type)
                var contact_type_late: String = str(move_def_late.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
                var m_a_striking_late: float = CombatantEntityAccess.weapon_striking_mass_kg(
                    atk_weapon, contact_type_late
                )
                var attack_instance = AttackInstance.new(
                    attack_type, pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
                )
                attack_instance.archetype = archetype
                attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
                var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
                v_intent *= StrikeRealismProfile.velocity_intent_mult_from_pa(
                    pa,
                    atk_weapon,
                    attack_type,
                    float(pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)),
                    archetype
                )
                parry_p_a = m_a_striking_late * v_intent * CombatTiming.velocity_curve_factor(1.0)
                parry_time_to_react = 0.0
                parry_c_d = _compute_parry_c_d(def_weapon, tgt, contact_type_late)
                parry_c_d *= CombatConstants.PARRY_LATE_CAPACITY_FLOOR
                # Attack arc: large span = blade moved far; harder to catch late.
                var arc_span: float = pa.get("arc_span_deg", 0.0)
                if arc_span > CombatConstants.ARC_SPAN_LATE_PARRY_THRESHOLD_DEG:
                    var span_factor: float = clampf(
                        (arc_span - CombatConstants.ARC_SPAN_LATE_PARRY_THRESHOLD_DEG) / 90.0, 0.0, 1.0
                    )
                    parry_c_d *= 1.0 - CombatConstants.ARC_SPAN_LATE_PARRY_PENALTY_MAX * span_factor
                var pr_base_late: float = PassiveParryContext.get_passive_parry_readiness(tgt)
                pr_base_late *= CombatConstants.passive_parry_readiness_incoming_contact_mult(contact_type_late)
                var yomi_rd_late: float = CombatAttention.yomi_defense_readiness_mult(
                    tgt, CombatantEntityAccess.id_int(atk)
                )
                parry_readiness = clampf(
                    (
                        pr_base_late
                        * _defender_passive_readiness_stamina_mult(tgt)
                        * _defender_passive_readiness_exhaustion_mult(tgt)
                        * CombatAttention.focus_effective(tgt)
                        * yomi_rd_late
                    ),
                    0.0,
                    1.0
                )
                var pr_guard_feint_late: float = (
                    parry_readiness
                    * _feint_readiness_reveal_mult(pa, atk)
                    * CombatAttention.focus_line_mult_for_feint(tgt, pa)
                )
                parry_off_balance = PassiveParryContext.is_off_balance(tgt)
                if parry_off_balance:
                    parry_c_d *= CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
                parry_c_d *= _parry_bonus_if_active(tgt)
                # Guard zone: parry bonus when target_part == guard_zone, penalty when unguarded (feint D).
                parry_c_d *= _guard_zone_modifier(
                    pa, tgt, targetable, attack_type, pr_guard_feint_late, CombatantEntityAccess.id_int(atk)
                )
                # BP2: angle-based alignment for late parry. Arc at progress 1.0 = impact (blade at arc_end).
                var align_ctx_late: Dictionary = {}
                var arc_start_late: float = pa.get(DataKeys.ATTACK_ARC_START_DEG, 0.0)
                var arc_end_late: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
                if arc_end_late >= -900.0:
                    var attack_angle_at_impact: float = CombatConstants.get_arc_angle_at_progress(
                        arc_start_late, arc_end_late, 1.0
                    )
                    attack_angle_at_impact = CombatFootwork.apply_offset_to_angle_deg(attack_angle_at_impact, atk)
                    var wobble_late: Dictionary = CombatantEntityAccess.parry_wobble_context(
                        def_weapon, pr_guard_feint_late
                    )
                    align_ctx_late = {
                        "attack_angle_deg": attack_angle_at_impact,
                        "guard_angle_deg":
                        CombatFootwork.guard_angle_deg_with_step_deg(tgt, wobble_late, parry_eval_step_deg_late),
                    }
                var al_raw: float = _get_line_alignment(
                    attack_type, tgt, pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""), align_ctx_late
                )
                var al: float = _alignment_with_arm_interpose(
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    al_raw,
                    targetable,
                    result
                )
                result[DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT] = al
                parry_c_d *= _get_contact_geometry(al, def_weapon)
                # Stamina: non-linear fatigue curve -- parry capacity scales with stamina_factor
                var st_ratio_late: float = CombatantEntityAccess.stamina_ratio(tgt)
                parry_c_d *= lerpf(
                    CombatConstants.STAMINA_AT_ZERO_PARRY_MULT, 1.0, CombatConstants.stamina_factor(st_ratio_late)
                )
                parry_c_d *= CombatExhaustion.timing_mult_for_combatant(tgt)
                parry_c_d *= TacticalCombat.surround_defense_multiplier_from_pa(tgt, pa)
                parry_c_d *= pa.get(DataKeys.PA_TACTICAL_AMBUSH_MULT, 1.0)
                if CombatConstants.combat_debug_active():
                    var dbg_tgt_late: String = CombatantEntityAccess.get_display_name(tgt)
                    CombatDebug.log(
                        (
                            "parry_align %s guard=%s atk=%s raw=%.3f align=%.3f"
                            % [
                                dbg_tgt_late,
                                tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT),
                                move_def_late.get(DataKeys.PA_ATTACK_LINE, "high"),
                                al_raw,
                                al
                            ]
                        )
                    )
                var cal_suffix_late: String = ""
                if not align_ctx_late.is_empty():
                    cal_suffix_late = (
                        " atk_deg=%.0f guard_deg=%.0f"
                        % [align_ctx_late.get(DataKeys.ALIGNMENT_ATTACK_ANGLE_DEG, 0.0), align_ctx_late.get(DataKeys.ALIGNMENT_GUARD_ANGLE_DEG, 0.0)]
                    )
                var interpose_note_late: String = ""
                if result.has(DataKeys.RESULT_ARM_INTERPOSE_BOOST) and result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] > 0.0:
                    interpose_note_late = (
                        " interpose_arm=%s boost=%.3f"
                        % [result.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""), result[DataKeys.RESULT_ARM_INTERPOSE_BOOST]]
                    )
                CombatDebug.calibration_log(
                    (
                        "parry_pre_late atk_line=%s guard=%s raw=%.3f align=%.3f parry_c_d=%.2f%s%s"
                        % [
                            move_def_late.get(DataKeys.PA_ATTACK_LINE, "high"),
                            tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT),
                            al_raw,
                            al,
                            parry_c_d,
                            cal_suffix_late,
                            interpose_note_late
                        ]
                    )
                )

    parry_p_a *= depth_spear_open_lane_stab_parry_p_a_mult(pa, attack_type)
    parry_c_d *= depth_spear_tight_lane_parry_c_d_mult(pa)
    parry_c_d *= pa.get(DataKeys.PA_ZONE_ENGAGEMENT_PARRY_MULT, 1.0)
    parry_c_d *= _spacing_band_parry_capacity_mult(tgt, atk)
    parry_c_d *= CombatWeaponPosition.parry_capacity_mult_for_defender(tgt)
    parry_c_d *= CombatMuscleFatigue.parry_capacity_mult(tgt)
    parry_c_d *= CombatWeaponPosition.incoming_attack_parry_c_d_mult(atk)

    result.can_parry_in_time = can_parry_in_time
    result.parry_p_a = parry_p_a
    result.parry_c_d = parry_c_d
    result.parry_time_to_react = parry_time_to_react
    if can_parry_in_time and not pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges().is_empty():
        result.parry_readiness = clampf(parry_readiness * _feint_readiness_reveal_mult(pa, atk), 0.0, 1.0)
    else:
        result.parry_readiness = parry_readiness
    result.parry_off_balance = parry_off_balance
    result.late_parry = late_parry

    var parry_cfg: Dictionary = PassiveParryContext.get_parry_config()
    # Classify parry timing as proactive/reactive/mid based on how far into the wind-up the defender responds.
    var effective_wind_up_for_timing: float = maxf(0.001, wind_up_duration * comm_frac) if can_parry_in_time else 1.0
    var parry_windup_frac: float = clampf(parry_time_to_react / effective_wind_up_for_timing, 0.0, 1.0) if not late_parry else 0.9
    var timing_class: String = CombatConstants.classify_parry_timing(parry_windup_frac)
    # Apply proactive/reactive capacity multiplier and control bonus to parry_c_d (initiative matters).
    # Proactive parries also get a momentum boost — meeting the attack early transfers more of its force.
    if can_parry_in_time:
        parry_c_d *= CombatConstants.parry_timing_capacity_mult(timing_class)
        var timing_ctrl_bonus: float = CombatConstants.parry_timing_control_bonus(timing_class)
        if timing_ctrl_bonus > 0.0 and parry_p_a > 0.0:
            parry_p_a *= (1.0 + timing_ctrl_bonus)
    # Bidirectional strong/weak: attacker weak exposure + defender forte (blade only). Shaft/haft use leverage in
    # contact_geometry.
    # Contact quality: delayed/slow parries couldn't get weapon into optimal position — contact happens further out
    # (weak). Scale strong/weak by intercept ability.
    if can_parry_in_time:
        var atk_w_arch = CombatantEntityAccess.get_weapon(atk)
        var def_w_arch = CombatantEntityAccess.get_weapon(tgt)
        var def_w: Variant = def_w_arch if def_w_arch != null else CombatantEntityAccess.get_weapon(tgt)
        var contact_quality: float = (
            CombatConstants.PARRY_LATE_CAPACITY_FLOOR
            if late_parry
            else (_get_parry_capacity_mult(def_w, tgt, parry_time_to_react) if def_w != null else 0.5)
        )
        if atk_w_arch != null:
            var arch_id: String = CombatantEntityAccess.weapon_archetype_id(atk_w_arch, attack_type)
            var pct: String = CombatantEntityAccess.weapon_parry_contact_type(def_w_arch)
            # Blade-on-blade: archetype weak exposure + defender forte matter. Shaft/haft: leverage only — no blade
            # weak to catch.
            var sc_raw: Variant = parry_cfg.get("strong_contact_by_arch", null)
            var sc_map: Dictionary = sc_raw if sc_raw is Dictionary else {}
            var full_strong_mod: float = sc_map.get(arch_id, 1.0) if pct == "blade" else 1.0
            if pct == "blade":
                var weak_exp: float = CombatConstants.WEAK_EXPOSURE_BY_ARCH.get(arch_id, 0.5)
                # Spatial strong fraction: models Stercke/Schweche — early parries contact with forte (strong),
                # late parries contact farther toward blade tip (weak). Uses parry_progress to estimate where
                # along the defender's blade the contact occurs.
                var spatial_strong_frac: float = 0.5  # fallback default
                if def_w_arch is Weapon:
                    var eff_wind_val: float = maxf(0.001, wind_up_duration * comm_frac)
                    var pp: float = 1.0 - clampf(parry_time_to_react / eff_wind_val, 0.0, 1.0) if not late_parry else 0.85
                    spatial_strong_frac = def_w_arch.get_spatial_strong_fraction_at_parry(pp)
                full_strong_mod *= 1.0 + CombatConstants.DEFENDER_STRONG_BONUS * spatial_strong_frac * weak_exp
            var strong_mod: float = lerpf(1.0, full_strong_mod, contact_quality)
            parry_c_d *= strong_mod
        parry_c_d *= CombatWeaponForm.mod(
            CombatantEntityAccess.form_str(tgt), "parry", CombatantEntityAccess.get_weapon(tgt)
        )
        result.parry_c_d = parry_c_d

    # Mass/strength for block check (total mass for both); m_a_velocity for partial parry v_reduced (striking mass when
    # parts).
    var m_a_parry: float = 0.0
    var m_d_parry: float = 0.0
    var m_a_velocity: float = 0.0
    var s_atk_parry: float = 100.0
    var s_d_parry: float = 100.0
    if can_parry_in_time:
        var atk_w: Variant = CombatantEntityAccess.get_weapon(atk)
        var def_w: Variant = CombatantEntityAccess.get_weapon(tgt)
        if atk_w != null and def_w != null:
            m_a_parry = CombatantEntityAccess.weapon_mass_kg(atk_w)
            m_d_parry = CombatantEntityAccess.weapon_mass_kg(def_w)
            var move_def_mass: Dictionary = WeaponConstants.get_move(attack_type)
            var ct_mass: String = str(move_def_mass.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
            m_a_velocity = CombatantEntityAccess.weapon_striking_mass_kg(atk_w, ct_mass)
        s_atk_parry = float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
        s_d_parry = float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    result.m_a_parry = m_a_parry
    result.m_d_parry = m_d_parry
    result.m_a_velocity = m_a_velocity
    result.s_atk_parry = s_atk_parry
    result.s_d_parry = s_d_parry

    var block_mass_t: float = parry_cfg.get("block_mass_threshold", CombatConstants.PARRY_BLOCK_MASS_THRESHOLD)
    var block_str_t: float = parry_cfg.get("block_str_threshold", CombatConstants.PARRY_BLOCK_STR_THRESHOLD)
    var effective_redirect: float = _get_effective_redirect(tgt)
    result.effective_redirect = effective_redirect
    result.is_block_parry = m_d_parry >= m_a_parry * block_mass_t and s_d_parry >= s_atk_parry * block_str_t
    var block_viable: bool = (
        can_parry_in_time and result.parry_p_a <= result.parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO
    )
    var desperate_parry: bool = can_parry_in_time and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD
    var redirect_viable: bool = (
        can_parry_in_time and (result.parry_p_a <= result.parry_c_d * effective_redirect or desperate_parry)
    )
    var preview_align: float = float(result.get(DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT, 1.0))
    var interpose_active: bool = float(result.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)) > 0.0
    var def_has_weapon: bool = CombatantEntityAccess.has_weapon(tgt)

    var choose_parry: bool = false
    if not def_has_weapon:
        choose_parry = false
    elif desperate_parry:
        choose_parry = true
    elif not can_parry_in_time:
        choose_parry = false
    elif can_parry_in_time and def_has_weapon:
        var part_mod: float = CombatantEntityAccess._get_part_dodge_modifier(tgt, result.dodge_eval_part)
        var effective_dodge_chance: float = dodge_chance * part_mod
        # Below glancing floor (cos60): parry is physically ineffective — boost dodge and skip parry decision entirely.
        if preview_align < CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
            effective_dodge_chance *= 1.25
        elif preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD and not interpose_active:
            effective_dodge_chance *= 1.15
        var full_dodge_prob: float = effective_dodge_chance * CombatConstants.DODGE_FULL_THRESHOLD
        var partial_dodge_avg_ratio: float = (CombatConstants.DODGE_PARTIAL_RATIO_MIN + 1.0) * 0.5
        var energy_dodge: float = (
            (1.0 - effective_dodge_chance) * 1.0
            + effective_dodge_chance * (1.0 - CombatConstants.DODGE_FULL_THRESHOLD) * partial_dodge_avg_ratio
        )
        var contact_type_for_parry: String = WeaponConstants.contact_type_for_move_id(attack_type)
        var parry_full: bool = CombatConstants.parry_full_stop_reached(
            result.parry_c_d, result.parry_p_a, result.is_block_parry, contact_type_for_parry
        )
        var parry_edge: bool = CombatConstants.parry_edge_deflect_reached(
            result.parry_c_d, result.parry_p_a, preview_align, result.is_block_parry, contact_type_for_parry
        )
        var agi_d: float = float(
            tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
        )
        var perc_d: float = float(
            tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE)
        )
        var redirect_mult: float = CombatConstants.compute_parry_redirect_mult(
            parry_cfg,
            agi_d,
            perc_d,
            WeaponConstants.contact_type_for_move_id(attack_type),
            result.is_block_parry,
            m_a_parry,
            m_d_parry
        )
        var parry_remaining_est: float = 1.0
        if not parry_full and result.parry_p_a > 0.001:
            parry_remaining_est = clampf(
                maxf(0.0, result.parry_p_a - result.parry_c_d * redirect_mult) / result.parry_p_a, 0.0, 1.0
            )
        var glancing_exp: float = parry_cfg.get("glancing_exponent", 0.5)
        var energy_parry: float = (
            0.0 if (parry_full or parry_edge) else CombatConstants.glancing_factor(parry_remaining_est, glancing_exp)
        )
        var dodge_better: bool = energy_dodge < energy_parry
        var clean_dodge_likely: bool = full_dodge_prob >= CombatConstants.PARRY_PREFER_DODGE_FULL_THRESHOLD
        # Alignment tiers: strong (>=cos45) -> parry preferred; glancing (cos45-cos60) -> needs stronger capacity surplus;
        ## below glancing floor (cos60) -> parry physically ineffective, dodge always wins.
        var well_aligned: bool = preview_align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
        var is_glancing: bool = (preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
            and preview_align >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR)
        # Glancing parries need a meaningful capacity surplus to overcome dodge energy advantage.
        choose_parry = (
            late_parry
            and (block_viable or redirect_viable)
            or (
                well_aligned
                and (block_viable or redirect_viable)
            )
            or (
                interpose_active
                and (block_viable or redirect_viable)
            )
            or (
                not is_glancing
                and not clean_dodge_likely
                and (block_viable or redirect_viable)
                and not dodge_better
            )
        )
    if choose_parry:
        CombatFootwork.apply_defender_step_on_parry(
            tgt, str(tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)), CombatantEntityAccess.id_int(atk), manager
        )
    elif def_has_weapon:
        CombatFootwork.clear_on_exchange_end(tgt)
        CombatFootwork.apply_defender_step_on_dodge(
            tgt, result.dodge_eval_part, CombatantEntityAccess.id_int(atk), manager
        )
    else:
        CombatFootwork.clear_on_exchange_end(tgt)
    result.defense = "parry" if choose_parry else "dodge"
    return result


static func _get_effective_redirect(tgt: Dictionary) -> float:
    var pcfg: Dictionary = PassiveParryContext.get_parry_config()
    var redirect_attempt: float = pcfg.get(DataKeys.PCFG_REDIRECT_ATTEMPT_RATIO, 2.5)
    var agi_scale: float = pcfg.get(DataKeys.PCFG_REDIRECT_ATTEMPT_AGILITY_SCALE, 0.5)
    var agi_d_attempt: float = float(
        CombatantEntityAccess.stats_dict(tgt).get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE)
    )
    return redirect_attempt * (0.75 + agi_scale * clampf(agi_d_attempt / 100.0, 0.0, 1.5))


static func _compute_parry_c_d(def_weapon, tgt: Dictionary, contact_type: String = "") -> float:
    var m_parry_part: float = CombatantEntityAccess.weapon_parry_part_mass_kg(def_weapon)
    var m_total: float = CombatantEntityAccess.weapon_mass_kg(def_weapon)
    # Full weapon mass matters: inertia and geometry. Blend parry-part (contact) with total (leverage).
    var m_d: float = (
        lerpf(m_parry_part, m_total, CombatConstants.PARRY_INERTIA_BLEND)
        if CombatantEntityAccess.weapon_has_parts(def_weapon)
        else m_total
    )
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var s_d: float = float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var c_d_full: float = (
        m_d * PassiveParryContext.get_parry_speed_m_s(def_weapon) * (s_d / CombatConstants.PARRY_STRENGTH_NORM)
    )
    var agi_d: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    c_d_full *= clampf(agi_d / 100.0, 0.7, 1.3)
    var def_perf: float = CombatantEntityAccess.get_performance_modifier(tgt)
    c_d_full *= maxf(CombatConstants.PERF_MOD_MIN, def_perf)
    c_d_full *= maxf(0.1, CombatantEntityAccess.get_attack_damage_modifier(tgt))
    if CombatantEntityAccess.weapon_has_parts(def_weapon):
        var pct: String = CombatantEntityAccess.weapon_parry_contact_type(def_weapon)
        c_d_full *= CombatConstants.PARRY_CONTACT_MODIFIERS.get(pct, 1.0)
    var contact_key: String = contact_type.to_lower().strip_edges()
    if not contact_key.is_empty():
        var def_type: String = str(def_weapon.get("weapon_type")).to_upper()
        var mod_dict: Variant = CombatConstants.PARRY_DEF_VS_ATK_MOD.get(def_type, {})
        if mod_dict is Dictionary:
            var mult: float = mod_dict.get(contact_key, 1.0)
            c_d_full *= mult
    return c_d_full


## Unified contact geometry: alignment × leverage. Blade gets alignment only (leverage=1); shaft/haft get alignment ×
## leverage factor.
## Merges angular (attack vs guard) and linear (where along shaft contact happens) into one multiplier.
## Micro-floor at 0.001 prevents degenerate zero-capacity from exactly-zero alignment while keeping the
## continuous cosine model intact — a blade in motion can accidentally intercept even at poor angles.
static func _get_contact_geometry(alignment: float, def_weapon) -> float:
    var leverage: float = _get_leverage_factor(def_weapon, alignment)
    return maxf(0.001, alignment) * leverage


## Leverage factor: where along shaft/haft the blow lands. Good alignment = defender controlled contact = strong (near
## hands).
## Poor alignment = contact could be weak (far from hands). Blade/handle: 1.0 (uniform).
static func _get_leverage_factor(def_weapon, alignment: float) -> float:
    if not CombatantEntityAccess.weapon_has_parts(def_weapon):
        return 1.0
    var pct: String = CombatantEntityAccess.weapon_parry_contact_type(def_weapon)
    if pct != "shaft" and pct != "haft":
        return 1.0
    var len_cm: float = CombatantEntityAccess.weapon_parry_part_length_cm(def_weapon)
    if len_cm < CombatConstants.PARRY_LEVERAGE_LONG_PART_CM:
        return 1.0
    return lerpf(CombatConstants.PARRY_LEVERAGE_FLOOR, 1.0, alignment)


static func _get_parry_capacity_mult(def_weapon, tgt: Dictionary, parry_time_to_react: float) -> float:
    # Weapon objects use direct properties; Object.get() takes 1 arg (no default like Dictionary).
    var m_d: float = CombatantEntityAccess.weapon_mass_kg(def_weapon)
    var s_d: float = float(CombatantEntityAccess.stats_dict(tgt).get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var speed_f: float = clampf(
        float(def_weapon.parry_speed_factor), CombatConstants.STAT_EFFECT_MULT_MIN, CombatConstants.STAT_EFFECT_MULT_MAX
    )
    var blade_movement_s: float = (
        (
            CombatConstants.PARRY_BLADE_MOVEMENT_S
            * clampf(
                m_d * CombatConstants.PARRY_STRENGTH_NORM / maxf(s_d, 1.0),
                CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MIN,
                CombatConstants.PARRY_MOVEMENT_MASS_STRENGTH_MAX
            )
        )
        / speed_f
    )
    var effective_parry_time: float = maxf(0.0, parry_time_to_react - blade_movement_s)
    return clampf(effective_parry_time / CombatConstants.PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)


static func _parry_bonus_if_active(tgt: Dictionary) -> float:
    var now_s: float = CombatTiming.now_seconds()
    if tgt.get(DataKeys.PA_PARRY_BONUS_UNTIL, -1.0) > now_s:
        return 1.1
    return 1.0


static func _get_line_alignment(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line_override: String = "",
    alignment_context: Dictionary = {}
) -> float:
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var attack_line: String = (
        effective_attack_line_override
        if not effective_attack_line_override.is_empty()
        else move_def.get(DataKeys.PA_ATTACK_LINE, "high")
    )
    return CombatConstants.get_line_alignment_with_deflect(attack_line, tgt, alignment_context)


## IV-5 BP6: boost parry alignment when attack-side arm is on the intercept path despite misaligned guard.
static func _alignment_with_arm_interpose(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line: String,
    alignment: float,
    targetable: Array,
    result: Dictionary
) -> float:
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var atk_line: String = (
        effective_attack_line if not effective_attack_line.is_empty() else str(move_def.get(DataKeys.PA_ATTACK_LINE, "high"))
    )
    var guard_line: String = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT))
    var interpose: Dictionary = CombatGuardLines.arm_interpose_eval(atk_line, guard_line, alignment, targetable)
    if not interpose.get("active", false):
        return alignment
    var boost: float = interpose.get("align_boost", 0.0)
    result[DataKeys.RESULT_ARM_INTERPOSE_ARM] = interpose.get(CombatConstants.INTERPOSE_KEY_ARM, "")
    result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] = boost
    return minf(1.0, alignment + boost)


static func _defender_spacing_band_to_attacker(tgt: Dictionary, atk: Dictionary) -> String:
    return CombatConstants.defender_distance_band_to_attacker_id(tgt, CombatantEntityAccess.id_int(atk))


static func _spacing_band_parry_capacity_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG
        _:
            return 1.0


static func _spacing_band_dodge_chance_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG
        _:
            return 1.0


static func _feint_telegraph_dodge_spacing_mult(tgt: Dictionary, atk: Dictionary) -> float:
    match _defender_spacing_band_to_attacker(tgt, atk):
        CombatConstants.DISTANCE_CLOSE:
            return CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE
        CombatConstants.DISTANCE_LONG:
            return CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG
        _:
            return 1.0


## Tier 4.2 telegraph delay (Feint --AC-- ): until attacker wind-up progress ''deg'
## **`feint_target_reveal_at_progress`**, damp readiness used for feint read-through / dodge telegraph / guard-zone bait
## resolution (**`1.0`** = disabled). If **`pa`** has **`feint_target_reveal_at_progress`** and it is **''deg' 0**,
## delay is off; if the key is absent, read the fraction from **`WeaponConstants.get_move(attack_type)`**.
static func _feint_readiness_reveal_mult(pa: Dictionary, atk: Dictionary) -> float:
    var fp: String = pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges()
    if fp.is_empty():
        return 1.0
    var reveal_at: float = 0.0
    if pa.has(DataKeys.PA_FEINT_TARGET_REVEAL_AT_PROGRESS):
        reveal_at = clampf(float(pa[DataKeys.PA_FEINT_TARGET_REVEAL_AT_PROGRESS]), 0.0, 1.0)
        if reveal_at <= 0.0:
            return 1.0
    else:
        var mid: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
        if not mid.is_empty():
            reveal_at = clampf(WeaponConstants.get_move(mid).get(DataKeys.WEAPON_FEINT_TARGET_REVEAL_AT_PROGRESS, 0.0), 0.0, 1.0)
        if reveal_at <= 0.0:
            return 1.0
    if CombatantEntityAccess.state_str(atk) != CombatConstants.STATE_WIND_UP:
        return 1.0
    var dur: float = atk.get(DataKeys.PA_STATE_DURATION, 0.0)
    var t: float = atk.get(DataKeys.PA_STATE_TIMER, 0.0)
    var denom: float = maxf(0.001, dur)
    var p: float = clampf(t / denom, 0.0, 1.0)
    if p >= reveal_at:
        return 1.0
    return lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, p / maxf(0.001, reveal_at))


## Tier 4.2: defender passive readiness for feint listing weight (shared by **`CombatAIActionPicker`** and harness).
static func defender_feint_listing_pr_def(
    defender: Dictionary,
    attacker_id: int,
    move_id: String,
    attacker: Dictionary = {},
    pa_live: Dictionary = {},
    apply_stamina_and_exhaustion: bool = true,
    apply_spacing_mult: bool = true
) -> float:
    var pr_def: float = clampf(PassiveParryContext.get_passive_parry_readiness(defender), 0.0, 1.0)
    var ct_mv: String = str(WeaponConstants.get_move(move_id).get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
    pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_mv), 0.0, 1.0)
    if apply_stamina_and_exhaustion:
        pr_def = clampf(
            (
                pr_def
                * CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
                    CombatantEntityAccess.stamina_ratio(defender)
                )
                * CombatConstants.defender_passive_readiness_exhaustion_mult(defender)
            ),
            0.0,
            1.0
        )
    if apply_spacing_mult:
        pr_def = clampf(
            pr_def * CombatConstants.ai_feint_listing_defender_readiness_spacing_mult(defender, attacker_id), 0.0, 1.0
        )
    if not attacker.is_empty() and not pa_live.is_empty():
        if pa_live.get(DataKeys.ACTION_TARGET_ID, -1) == CombatantEntityAccess.id_int(defender):
            var pa_mid: String = pa_live.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
            if pa_mid.is_empty() or pa_mid == move_id:
                pr_def = clampf(pr_def * _feint_readiness_reveal_mult(pa_live, attacker), 0.0, 1.0)
    return pr_def


## Tier 4.2 footwork / tempo: same curve as post-alignment **`parry_c_d`** stamina (**`STAMINA_AT_ZERO_PARRY_MULT`** +
## **`stamina_factor`**) applied to **readiness** (feint read-through, guard-zone, dodge telegraph). Not multiplied into
## **`pr_base`** in **`parry_c_d *= parry_capacity_mult * pr_base`** — avoids double-applying stamina to passive parry
## capacity.
static func _defender_passive_readiness_stamina_mult(tgt: Dictionary) -> float:
    return CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(CombatantEntityAccess.stamina_ratio(tgt))


## MXm-2: fight-duration exhaustion on readiness reporting (not folded into **`pr_base`** in **`parry_c_d`**).
static func _defender_passive_readiness_exhaustion_mult(tgt: Dictionary) -> float:
    return CombatConstants.defender_passive_readiness_exhaustion_mult(tgt)


static func _feint_guard_reads_real_line(tgt: Dictionary, parry_readiness: float, attacker_id: int = -1) -> bool:
    var sm: float = CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "feint_readthrough", CombatantEntityAccess.get_weapon(tgt)
    )
    # A2: meisterhau_readthrough — extra bonus for defending against Liechtenauer decisive counter-strikes.
    var mh_rt: float = CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(tgt), "meisterhau_readthrough", CombatantEntityAccess.get_weapon(tgt)
    )
    if mh_rt > 1.0:
        sm *= lerpf(1.0, mh_rt, 0.4)
    if attacker_id >= 0:
        var cache_raw: Variant = tgt.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
        if cache_raw is Dictionary:
            var inferred: String = (cache_raw as Dictionary).get(str(attacker_id), "").strip_edges()
            sm += CombatWeaponForm.counter_readiness_nudge(
                CombatantEntityAccess.form_str(tgt), inferred, CombatantEntityAccess.get_weapon(tgt)
            )
    return parry_readiness * sm >= CombatConstants.FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD


## When **`pa.feint_part`** is set and defender does not read through the feint, **`dodge_eval_part`** may follow the
## telegraph (dodge --Abites--  on bait). **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** (**0..1**)
## overrides **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS`** for regression only; then **`distance_to[attacker]`** scales bias
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**). Read-through uses the same
## **`feint_guard_zone_readiness_spacing_mult`** as **`_guard_zone_modifier`** vs
## **`CombatantEntityAccess.id_int(atk)`** ( **`attacker_id` < 0** '' ' MID / **1.0** ). **`attack_type_for_contact`**:
## incoming move id for stab/cut/blunt readiness scaling; if empty, uses **`pa["attack_type"]`**.
static func _apply_feint_telegraph_bias_to_dodge_eval_part(
    pa: Dictionary,
    tgt: Dictionary,
    atk: Dictionary,
    targetable: Array,
    result: Dictionary,
    attack_type_for_contact: String = ""
) -> void:
    if targetable.is_empty():
        return
    var fp: String = pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges()
    if fp.is_empty() or not targetable.has(fp):
        return
    var pr: float = PassiveParryContext.get_passive_parry_readiness(tgt)
    var atk_type_for_ct: String = attack_type_for_contact.strip_edges()
    if atk_type_for_ct.is_empty():
        atk_type_for_ct = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
    var ct_for_pr: String = ""
    if not atk_type_for_ct.is_empty():
        ct_for_pr = str(WeaponConstants.get_move(atk_type_for_ct).get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
    pr *= CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_for_pr)
    pr *= _defender_passive_readiness_stamina_mult(tgt)
    pr *= _defender_passive_readiness_exhaustion_mult(tgt)
    pr *= CombatAttention.focus_effective(tgt)
    pr *= CombatAttention.yomi_defense_readiness_mult(tgt, CombatantEntityAccess.id_int(atk))
    pr *= _feint_readiness_reveal_mult(pa, atk)
    pr *= CombatAttention.focus_line_mult_for_feint(tgt, pa)
    pr = clampf(pr, 0.0, 1.0)
    var pr_rt: float = clampf(
        pr * CombatConstants.feint_guard_zone_readiness_spacing_mult(tgt, CombatantEntityAccess.id_int(atk)), 0.0, 1.0
    )
    if _feint_guard_reads_real_line(tgt, pr_rt, CombatantEntityAccess.id_int(atk)):
        return
    var bias: float = CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS
    var ho: Variant = pa.get(CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS, -1.0)
    if ho is float or ho is int:
        var ob: float = float(ho)
        if ob >= 0.0:
            bias = clampf(ob, 0.0, 1.0)
    bias = clampf(bias * _feint_telegraph_dodge_spacing_mult(tgt, atk), 0.0, 1.0)
    if bias > 0.0 and randf() < bias:
        result.dodge_eval_part = fp


## Guard zone modifier: bonus when defender guards the hit part, penalty when unguarded (feint D).
## **`parry_readiness_for_feint`**: pass passive parry readiness from **`choose_defense`**; **`< 0`** skips feint
## read-through (harness compatibility / static calls). **`atk_id_for_feint_spacing`**: defender
## **`distance_to[atk_id]`** scales readiness only for read-through (**`-1`** = omit footwork, default).
static func _guard_zone_modifier(
    pa: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    parry_readiness_for_feint: float = -1.0,
    atk_id_for_feint_spacing: int = -1
) -> float:
    var gz: String = str(tgt.get(DataKeys.DEFENDER_GUARD_ZONE, "head"))
    if gz.is_empty():
        return 1.0
    var move_def: Dictionary = WeaponConstants.get_move(attack_type)
    var attack_line: String = move_def.get(DataKeys.PA_ATTACK_LINE, "high")
    var guard_line: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
    var intended: String = pa.get(DataKeys.ACTION_TARGET_PART, "")
    var expected_part: String = AttackPathResolver.resolve_hit_part(
        attack_line, guard_line, targetable, {}, intended, tgt
    )
    if expected_part.is_empty():
        return 1.0
    var feint_part: String = pa.get(DataKeys.ACTION_FEINT_PART, "")
    var gz_eval: String = gz
    var pr_fe_rt: float = parry_readiness_for_feint
    if atk_id_for_feint_spacing >= 0 and pr_fe_rt >= 0.0:
        pr_fe_rt = clampf(
            (
                parry_readiness_for_feint
                * CombatConstants.feint_guard_zone_readiness_spacing_mult(tgt, atk_id_for_feint_spacing)
            ),
            0.0,
            1.0
        )
    if (
        not feint_part.is_empty()
        and parry_readiness_for_feint >= 0.0
        and _feint_guard_reads_real_line(tgt, pr_fe_rt, atk_id_for_feint_spacing)
    ):
        gz_eval = expected_part
    if not feint_part.is_empty():
        var tele: String = str(tgt.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, feint_part))
        if tele.is_empty():
            tele = feint_part
        # Still aligned with wind-up telegraph while real line lands elsewhere '' ' baited / wrong focus.
        if gz_eval == tele and expected_part != tele:
            return CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    if expected_part == gz_eval:
        return CombatConstants.GUARD_ZONE_BONUS
    return CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY


## Velocity-based parry difficulty: faster attacks reduce effective parry capacity.
## Models the reality that high-speed strikes are harder to time/read, not just harder to stop.
## Low-intensity attacks (below threshold) are excluded to avoid penalizing deliberate/slow techniques.
static func _parry_velocity_difficulty_mult(attack_velocity_m_s: float, pa: Dictionary = {}) -> float:
    var intensity: float = float(pa.get(CombatConstants.PA_KEY_INTENSITY, 1.0))
    if intensity < CombatConstants.PARRY_VELOCITY_INTENSITY_MIN_THRESHOLD:
        return 1.0
    var ref: float = CombatConstants.PARRY_VELOCITY_DIFFICULTY_REF_M_S
    if attack_velocity_m_s <= ref:
        return 1.0
    var ratio: float = (attack_velocity_m_s - ref) / maxf(ref, 1.0)
    var penalty: float = clampf(ratio * CombatConstants.PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY / 2.0, 0.0, CombatConstants.PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY)
    return 1.0 - penalty
