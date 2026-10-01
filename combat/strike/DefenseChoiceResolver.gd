class_name DefenseChoiceResolver
extends RefCounted

## Given attack params and defender state, chooses parry vs dodge and computes parry capacity/timing.
## Footing: Tier 4.2 spacing/state mults here — Tier 4.4 PA stamp + geometry preview: **`apply_defender_step_*`**,
## **`parry_eval_step_deg_for_defender`**, **`dodge_eval_step_deg_for_defender`**, **`guard_angle_deg_with_step_deg`**,
## dodge-path **`clear_on_exchange_end`**. LIVE_PATHS **`#wf-tier-44-pa`** . **`#wf-layer-labels`**.
## Pure function: returns a dict of computed values; caller handles resolution and mutation.
## Tier 4.2: **`_guard_zone_modifier`** may treat the real hit line as the defender's guard focus when passive
## **`parry_readiness`**  -  stance **`feint_readthrough`** clears
## **`CombatConstants.FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** (omit extra arg — harness compatibility / static
## calls).
## Tier 4.2 footwork: pair **`distance_to[attacker]`** scales **`parry_c_d`** (CLOSE / LONG vs MID) and
## **`dodge_chance`** at CLOSE / LONG (**`CombatConstants.DEFENSE_SPACING_*`**); **`STATE_RECOVERING`** / settled
## **`STATE_WAITING`** scale reported **`dodge_chance`** via **`defense_footwork_recovering_dodge_mult_for_cause`** /
## **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** (waiting skipped when off-balance); feint-only spacing on dodge telegraph
## (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**), AI feint-listing readiness
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**), and **`_guard_zone_modifier`** read-through
## (**`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**).
## Tier 4.2 tempo: non-empty **`feint_part`** on **`pa`** uses
## **`CombatConstants.commitment_fraction_for_pending_attack`** (larger committed fraction → shorter
## **`effective_wind_up`** for passive parry timing vs plain attacks).
## Tier 4.2 telegraph delay: optional **`feint_target_reveal_at_progress`** on feint moves (stamped on **`pa`** in
## **`AttackWindUpStarter`**) scales feint read-through / dodge-telegraph readiness via
## **`CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT`** until wind-up progress reaches that fraction
## (**`_feint_readiness_reveal_mult`**).
## Incoming **`contact_type`** (stab/cut/blunt) scales passive parry readiness after
## **`PassiveParryContext.get_passive_parry_readiness`**
## (**`CombatConstants.passive_parry_readiness_incoming_contact_mult`**).
## Defender **`stamina`** scales the **readiness** used for feint read-through / guard-zone / dodge telegraph
## (**`_defender_passive_readiness_stamina_mult`** →
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
## rank≥1 depth spear lane is live.
static func _depth_polearm_lane_is_open(pa: Dictionary) -> bool:
    ## `stamp_attack_pair_geometry_on_dict` always sets the key (often `""`). Empty / unknown → `allows_low`
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

    ## Read attacker windup before dodge computation so the defender's dodge model uses realistic weapon-dependent
    ## timing.
    var atk_windup: float = pa.get(DataKeys.PA_WIND_UP_DURATION, 0.5)
    var dodge_chance: float = CombatantEntityAccess.get_dodge_chance(tgt, atk_windup)
    # Apply graduated limb impairment to dodge — damaged legs reduce movement speed and reaction.
    if not tgt.is_empty():
        var node: Node = CombatantEntityAccess.combat_body(tgt)
        if node != null:
            if node.has_method("_get_vital_parts"):
                var limb_impairment: Dictionary = EntityPainConsciousness.get_limb_impairment_multiplier(node)
                dodge_chance *= limb_impairment.get("dodge_mult", 1.0)
            # Concussion: impaired balance/proprioception degrades the evasive step — a concussed fighter
            # can't shift weight cleanly to step away. balance_mult < 1.0 while concussed, 1.0 otherwise
            # (D001-neutral). This is the one axis of get_dodge_speed_modifier NOT already in the base
            # dodge formula (leg pain / performance / armor encumbrance are all in it), so only the
            # balance term is applied here to avoid double-counting.
            var conc_balance: float = float(
                EntityPainConsciousness.get_concussion_phase_info(node).get("balance_mult", 1.0)
            )
            if conc_balance < 0.999:
                dodge_chance *= conc_balance
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
    # HEMA: an off-balance defender can't step away as effectively — compromised center of gravity
    # impairs the evasive step. Symmetric with the parry-capacity penalty applied elsewhere. Fades as
    # the defender re-establishes balance (proportional to off-balance depth).
    if PassiveParryContext.is_off_balance(tgt):
        dodge_chance *= PassiveParryContext.off_balance_penalty_mult(tgt, CombatConstants.OFF_BALANCE_DODGE_CHANCE_MULT)
    result.dodge_chance = dodge_chance

    var already_used_defense: bool = pa.get(CombatConstants.PA_KEY_PASSIVE_PARRY_ATTEMPTED, false)
    if pa.get(DataKeys.PA_PARRY_CHOICE_BLOCKED, false):
        result.effective_redirect = _get_effective_redirect(tgt)
        return result
    if already_used_defense:
        result.effective_redirect = _get_effective_redirect(tgt)
        return result
    var wind_up_duration: float = pa.get(DataKeys.PA_WIND_UP_DURATION, 0.5)
    var comm_frac: float = CombatConstants.commitment_fraction_for_pending_attack(pa)
    var effective_wind_up: float = wind_up_duration * (1.0 - comm_frac)
    # A defender already committed to their own wind-up (STATE_WIND_UP / STATE_MEDICAL_WIND_UP) has no free blade for a
    # proactive on-time parry — their weapon is in their own arc. They are NOT defenseless though: HEMA reflex shows a
    # mid-swing fighter still raises the blade into a late/reflexive parry. Force `force_reflexive_parry` so the branch
    # below routes to the late path regardless of reaction timing (a fast reaction would otherwise take the proactive
    # on-time branch, which over-credits a defender whose weapon is already committed). Hard-returning here was zeroing
    # parry_c_d for the common mid-swing case — that is why mirror matchups produced clean hits and no blade clashes.
    # The late branch applies PARRY_LATE_CAPACITY_FLOOR + arc-span + stamina/exhaustion timing penalties, so reflexive
    # mid-swing parries stay strictly weaker than on-time ones (no over-reward).
    var force_reflexive_parry: bool = (
        CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_WIND_UP
        or CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_MEDICAL_WIND_UP
    )
    var can_parry_in_time: bool = false
    var parry_p_a: float = 0.0
    var parry_c_d: float = 0.0
    var c_d_raw: float = 0.0
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
            # `force_reflexive_parry` (mid-swing defender) takes the late branch even with a fast reaction, so a
            # committed weapon is never credited with a proactive on-time parry.
            if not force_reflexive_parry and reaction_time < effective_wind_up and atk_weapon != null:
                can_parry_in_time = true
                var parry_eval_step_deg: float = CombatFootwork.parry_eval_step_deg_for_defender(
                    tgt, CombatantEntityAccess.id_int(atk), manager
                )
                var move_def: Dictionary = WeaponConstants.get_move(attack_type)
                var contact_type: String = str(
                    move_def.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
                )
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
                c_d_raw = c_d_full
                var pr_base: float = PassiveParryContext.get_passive_parry_readiness(tgt)
                pr_base *= CombatConstants.passive_parry_readiness_incoming_contact_mult(contact_type)
                var st_rd: float = _defender_passive_readiness_stamina_mult(tgt)
                var ex_rd: float = _defender_passive_readiness_exhaustion_mult(tgt)
                var yomi_rd: float = CombatAttention.yomi_defense_readiness_mult(tgt, CombatantEntityAccess.id_int(atk))
                ## P4: Long weapon parry advantage — spear/polearm reach extends the blade into the attack trajectory
                ## earlier,
                ## effectively increasing readiness. Models HEMA "Langen-ort" (long game) where polearms control
                ## distance.
                var reach_readiness_bonus: float = _reach_parry_readiness_bonus(def_weapon, atk_weapon)
                parry_readiness = clampf(
                    (
                        pr_base
                        * st_rd
                        * ex_rd
                        * CombatAttention.focus_effective(tgt)
                        * yomi_rd
                        * (1.0 + reach_readiness_bonus)
                        * CombatMoraleCohesion.morale_parry_readiness_mult(
                            tgt.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0)
                        )
                    ),
                    0.0,
                    1.0
                )
                var pr_guard_feint: float = (
                    parry_readiness
                    * _feint_readiness_reveal_mult(pa, atk)
                    * CombatAttention.focus_line_mult_for_feint(tgt, pa)
                )
                parry_off_balance = PassiveParryContext.is_off_balance(tgt)
                var v_par_diff_mult: float = _parry_velocity_difficulty_mult(
                    v_intent if v_intent > 0 else WeaponConstants.VELOCITY_MAX_M_S * 0.7, pa
                )
                parry_c_d *= parry_capacity_mult * pr_base * v_par_diff_mult
                # XCamp-6 (gladiator): a school fighter's scouted parry_bias raises its parry
                # capacity (a defensive fighter reads and catches more). 1.0 when no tendency.
                parry_c_d *= CombatConstantsAIWeights.school_tendency_parry_mult(tgt)
                # Positional feint open-line: a defender who just failed to parry a feint on a specific
                # line is still displaced on that line — the next attack on the same line finds reduced
                # parry capacity (they are re-committing their guard, not fully re-established).
                var incoming_line: String = str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
                parry_c_d *= _feint_open_line_parry_mult(tgt, incoming_line)
                # Limb crippling (structural arm damage) degrades weapon handling / parry absorption.
                # Distinct from arm PAIN (already in get_parry_capacity_modifier) and consciousness
                # (already in get_performance_modifier applied via _compute_parry_c_d).
                var node_p: Node = CombatantEntityAccess.combat_body(tgt)
                if node_p != null and node_p.has_method("_get_vital_parts"):
                    parry_c_d *= EntityPainConsciousness.get_limb_impairment_multiplier(node_p).get("parry_mult", 1.0)
                # Leg-wound bracing: a compromised base weakens the platform a parry braces into.
                # Distinct from the arm limb-impairment above (weapon handling) and from the momentary
                # off-balance penalty below (dynamic, fades with depth).
                parry_c_d *= CombatConstants.leg_stance_parry_mult(CombatantEntityAccess.get_leg_functionality(tgt))
                # Torso-wound bracing: a compromised core weakens the central brace a parry absorbs
                # into. Reads the chest part's structural (bone + tissue) integrity directly. D001-neutral.
                parry_c_d *= CombatConstants.torso_stance_parry_mult(BodyPartQuery.get_torso_core_functionality(node_p))
                # Tier 3.1 persistent facing: a fighter still turned from a prior flank/rear hit has a
                # blade off-line on the new exposure line — a bounded parry-capacity dip, distinct axis
                # from the momentary off-balance penalty below. No-op when the window is empty (front-on /
                # D001 never stamps it).
                if CombatConstants.is_feature_persistent_facing_enabled():
                    parry_c_d *= PassiveParryContext.facing_turn_parry_capacity_mult(tgt)
                if parry_off_balance:
                    parry_c_d *= PassiveParryContext.off_balance_penalty_mult(
                        tgt, CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
                    )
                parry_c_d *= _parry_bonus_if_active(tgt)
                # HEMA bind pressure: opponent pressing the bind reduces defender's parry capacity.
                if manager != null:
                    parry_c_d *= CombatBindPressure.defender_parry_cap_mult(
                        atk, CombatantEntityAccess.combat_clock_float(manager)
                    )
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
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    align_ctx,
                    pa.get(DataKeys.PA_GUARD_ALIGNMENT, -1.0)
                )
                var al: float = _alignment_with_arm_interpose(
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    al_raw,
                    targetable,
                    result
                )
                var atk_line_on: String = pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
                var proactive_align_boost: float = 0.0
                if can_parry_in_time and not late_parry and al >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
                    proactive_align_boost = minf(0.08, (al - CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR) * 0.12)
                al = _apply_guard_line_matching(
                    al, atk_line_on, tgt, can_parry_in_time and not late_parry, proactive_align_boost
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
                        % [
                            align_ctx.get(DataKeys.ALIGNMENT_ATTACK_ANGLE_DEG, 0.0),
                            align_ctx.get(DataKeys.ALIGNMENT_GUARD_ANGLE_DEG, 0.0)
                        ]
                    )
                var interpose_note: String = ""
                if (
                    result.has(DataKeys.RESULT_ARM_INTERPOSE_BOOST)
                    and result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] > 0.0
                ):
                    interpose_note = (
                        " interpose_arm=%s boost=%.3f"
                        % [
                            result.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""),
                            result[DataKeys.RESULT_ARM_INTERPOSE_BOOST]
                        ]
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
                var contact_type_late: String = str(
                    move_def_late.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT)
                )
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
                c_d_raw = parry_c_d
                parry_c_d *= CombatConstants.PARRY_LATE_CAPACITY_FLOOR
                # XCamp-6 (gladiator): parry_bias on the late/reflexive path too (same lever).
                parry_c_d *= CombatConstantsAIWeights.school_tendency_parry_mult(tgt)
                # Limb crippling (structural arm damage) degrades parry absorption — mirrors the on-time
                # path. Distinct from arm PAIN (already in get_parry_capacity_modifier) and consciousness
                # (already in get_performance_modifier applied via _compute_parry_c_d).
                var node_l: Node = CombatantEntityAccess.combat_body(tgt)
                if node_l != null and node_l.has_method("_get_vital_parts"):
                    parry_c_d *= EntityPainConsciousness.get_limb_impairment_multiplier(node_l).get("parry_mult", 1.0)
                # Leg-wound bracing (late path): mirrors the on-time path above.
                parry_c_d *= CombatConstants.leg_stance_parry_mult(CombatantEntityAccess.get_leg_functionality(tgt))
                # Torso-wound bracing (late path): mirrors the on-time path above.
                parry_c_d *= CombatConstants.torso_stance_parry_mult(BodyPartQuery.get_torso_core_functionality(node_l))
                # Tier 3.1 persistent facing (late path): a fighter still turned from a prior flank/rear hit
                # has a blade off-line on the new exposure line — a bounded parry-capacity dip. No-op when
                # the window is empty (front-on / D001 never stamps it).
                if CombatConstants.is_feature_persistent_facing_enabled():
                    parry_c_d *= PassiveParryContext.facing_turn_parry_capacity_mult(tgt)
                # HEMA: a mid-swing defender's blade is locked in their own attack arc — they cannot reposition it
                # to meet the incoming strike, so their reflexive parry has reduced blade control. Applied on top of
                # the timing-based late floor so a committed weapon is strictly weaker than a waiting defender's
                # slow reaction.
                if force_reflexive_parry:
                    parry_c_d *= CombatConstants.PARRY_MID_SWING_CAPACITY_MULT
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
                ## P4: Long weapon parry advantage for late (reactive) parries too — reach still helps intercept closer
                ## to impact.
                var reach_readiness_bonus_late: float = _reach_parry_readiness_bonus(def_weapon, atk_weapon)
                parry_readiness = clampf(
                    (
                        pr_base_late
                        * _defender_passive_readiness_stamina_mult(tgt)
                        * _defender_passive_readiness_exhaustion_mult(tgt)
                        * CombatAttention.focus_effective(tgt)
                        * yomi_rd_late
                        * (1.0 + reach_readiness_bonus_late)
                        * CombatMoraleCohesion.morale_parry_readiness_mult(
                            tgt.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0)
                        )
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
                    parry_c_d *= PassiveParryContext.off_balance_penalty_mult(
                        tgt, CombatConstants.OFF_BALANCE_PARRY_CAPACITY_MULT
                    )
                parry_c_d *= _parry_bonus_if_active(tgt)
                # Positional feint open-line (late parry path): same grounded effect as the on-time path —
                # a defender still displaced on the feint line has reduced reflexive parry capacity too.
                parry_c_d *= _feint_open_line_parry_mult(
                    tgt, str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
                )
                # HEMA bind pressure: opponent pressing the bind reduces defender's parry capacity.
                if manager != null:
                    parry_c_d *= CombatBindPressure.defender_parry_cap_mult(
                        atk, CombatantEntityAccess.combat_clock_float(manager)
                    )
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
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    align_ctx_late,
                    pa.get(DataKeys.PA_GUARD_ALIGNMENT, -1.0)
                )
                var al: float = _alignment_with_arm_interpose(
                    attack_type,
                    tgt,
                    pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""),
                    al_raw,
                    targetable,
                    result
                )
                var atk_line_late: String = pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
                al = _apply_guard_line_matching(al, atk_line_late, tgt, false, 0.0)
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
                        % [
                            align_ctx_late.get(DataKeys.ALIGNMENT_ATTACK_ANGLE_DEG, 0.0),
                            align_ctx_late.get(DataKeys.ALIGNMENT_GUARD_ANGLE_DEG, 0.0)
                        ]
                    )
                var interpose_note_late: String = ""
                if (
                    result.has(DataKeys.RESULT_ARM_INTERPOSE_BOOST)
                    and result[DataKeys.RESULT_ARM_INTERPOSE_BOOST] > 0.0
                ):
                    interpose_note_late = (
                        " interpose_arm=%s boost=%.3f"
                        % [
                            result.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""),
                            result[DataKeys.RESULT_ARM_INTERPOSE_BOOST]
                        ]
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
    # Capacity cascade floor: applied BEFORE small gameplay modifiers (spacing, reach, weapon form,
    # muscle fatigue) so those modifiers remain visible. Prevents the 15+ factor multiplicative
    # cascade from collapsing capacity to ~25% of raw, which made deflects mathematically impossible.
    # HEMA: trained fencers produce clean deflections ~20-30% of the time.
    # Only applies when raw capacity is above a minimum threshold AND defender is not in a degraded
    # state (recovering, off-balance) AND guard is non-trivial — degraded parries and unguarded
    # defenders should genuinely have near-zero capacity.
    var is_degraded_state: bool = (
        parry_off_balance
        or CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_RECOVERING
        or CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_FORM_SWITCH
    )
    var def_guard: float = float(tgt.get("guard", 0.0))
    if (
        c_d_raw > CombatConstants.PARRY_CASCADE_FLOOR_RAW_MIN
        and not is_degraded_state
        and def_guard > CombatConstants.PARRY_CASCADE_FLOOR_GUARD_MIN
    ):
        parry_c_d = maxf(parry_c_d, c_d_raw * CombatConstants.PARRY_CASCADE_CAPACITY_FLOOR)
    parry_c_d *= _spacing_band_parry_capacity_mult(tgt, atk)
    parry_c_d *= _reach_disparity_parry_penalty(atk, tgt)
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
    var parry_windup_frac: float = (
        clampf(parry_time_to_react / effective_wind_up_for_timing, 0.0, 1.0) if not late_parry else 0.9
    )
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
                # HEMA: forte/schwach difference scales with blade flexibility — a flexible blade (long/thin)
                # flexes more under load, so its forte/schwach difference is larger than a stiff blade's.
                var flex_factor: float = 1.0
                if def_w_arch is Weapon:
                    var eff_wind_val: float = maxf(0.001, wind_up_duration * comm_frac)
                    var pp: float = (
                        1.0 - clampf(parry_time_to_react / eff_wind_val, 0.0, 1.0) if not late_parry else 0.85
                    )
                    spatial_strong_frac = def_w_arch.get_spatial_strong_fraction_at_parry(pp)
                    flex_factor = CombatConstants.flex_factor_for_slenderness(def_w_arch.get_blade_slenderness())
                full_strong_mod *= (
                    1.0 + CombatConstants.DEFENDER_STRONG_BONUS * flex_factor * spatial_strong_frac * weak_exp
                )
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
    # KE-weighted block scaling skipped here — requires AttackInstance which isn't available in choose_defense.
    # Has negligible effect vs the existing PARRY_BLOCK_MASS_THRESHOLD defaults.
    var effective_redirect: float = _get_effective_redirect(tgt)
    result.effective_redirect = effective_redirect
    result.is_block_parry = m_d_parry >= m_a_parry * block_mass_t and s_d_parry >= s_atk_parry * block_str_t
    # Reflexive mid-swing parry floor — must run BEFORE the viability booleans below so it actually makes
    # `redirect_viable`/`block_viable` true. A defender committed to their own wind-up has no free blade for a proactive
    # parry, but a reflexive block is still physically available; without this floor the late-branch cascade
    # (PARRY_LATE_CAPACITY_FLOOR × arc-span × alignment geometry × reactive timing) collapses c_d below the
    # redirect-viability threshold and the defender always falls to dodge — exactly why mirror matchups produced clean
    # hits and no blade clashes. Anchor at 1/effective_redirect (the exact point where `redirect_viable` flips true) so
    # the reflexive parry is actually choosable, then scale by alignment (0.85–1.0) so a well-matched guard reflexes
    # slightly harder than a misaligned one. This sits below an on-time defender's typical c_d/p_a surplus (~0.7–1.0)
    # for equal weapons, so a mid-swing block stays strictly weaker than a settled parry (no over-reward). Skipped when
    # the guard is explicitly zeroed (harness test fixtures) or when no parry was even evaluated.
    if force_reflexive_parry and can_parry_in_time and result.parry_p_a > 0.0:
        var reflex_guard_suppressed: bool = PassiveParryContext.guard_readiness_float(tgt) <= 0.0
        if not reflex_guard_suppressed:
            var reflex_align_frac: float = clampf(
                float(result.get(DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT, 1.0)), 0.0, 1.0
            )
            var reflex_floor_ratio: float = (1.0 / maxf(effective_redirect, 0.5)) * lerpf(0.85, 1.0, reflex_align_frac)
            result.parry_c_d = maxf(result.parry_c_d, result.parry_p_a * reflex_floor_ratio)
    var block_viable: bool = (
        can_parry_in_time and result.parry_p_a <= result.parry_c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO
    )
    var desperate_parry: bool = can_parry_in_time and dodge_chance < CombatConstants.PARRY_DESPERATE_DODGE_THRESHOLD
    var redirect_viable: bool = (
        can_parry_in_time and (result.parry_p_a <= result.parry_c_d * effective_redirect or desperate_parry)
    )
    var preview_align: float = float(result.get(DataKeys.RESULT_PARRY_PREVIEW_ALIGNMENT, 1.0))
    if CombatDebug.dc_trace_active():
        CombatDebug.combat_session(
            (
                "dc_pre_align def=%s state=%s cause=%s preview_align=%.4f"
                % [
                    CombatantEntityAccess.get_display_name(tgt, -1),
                    CombatantEntityAccess.state_str(tgt),
                    str(tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "")),
                    preview_align
                ]
            )
        )
    # Functional alignment bonus: near-threshold alignments (cos45) get a small boost for confident parry decisions.
    if (
        preview_align >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR
        and preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD + 0.15
    ):
        var margin_frac = (
            (preview_align - CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR)
            / (CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD - CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR)
        )
        preview_align = minf(
            1.0, preview_align + CombatConstants.PARRY_FUNCTIONAL_ALIGNMENT_BONUS * (1.0 - margin_frac)
        )
    # Enforce minimum capacity floor: even with heavy stamina/pain/exhaustion penalties, a well-aligned defender retains
    # meaningful parry options.
    # Skip the floor for defenders in active recovery from attacks — reduced parry capacity there is by design
    # (readiness curve + weapon position).
    var def_state = CombatantEntityAccess.state_str(tgt)
    var def_recovering_from_attack: bool = (
        def_state == CombatConstants.STATE_RECOVERING
        and (
            tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "") in ["attack_hit", "attack_miss"]
            or tgt.get(DataKeys.ATTACK_RECOVERY_CAUSE, "") in ["parry_deflect", "parry_partial"]
        )
    )
    if preview_align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD and not def_recovering_from_attack:
        # Skip floor when guard is explicitly zeroed (e.g. harness tests forcing hit outcomes).
        var guard_suppressed: bool = PassiveParryContext.guard_readiness_float(tgt) <= 0.0
        if not guard_suppressed:
            var alignment_floor: float = maxf(preview_align, CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD)
            var min_viable_capacity: float = (
                result.parry_p_a
                * CombatConstants.PARRY_CAPACITY_FLOOR_RATIO
                * (alignment_floor / CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD)
            )
            result.parry_c_d = maxf(result.parry_c_d, min_viable_capacity)
    var interpose_active: bool = float(result.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)) > 0.0
    var def_has_weapon: bool = CombatantEntityAccess.has_weapon(tgt)

    var choose_parry: bool = false
    if CombatDebug.dc_trace_active():
        CombatDebug.combat_session(
            (
                (
                    "defense_choose def=%s atk_id=%d type=%s can_pt=%s has_wpn=%s block_v=%s redir_v=%s align=%.3f "
                    + "dodge_c=%.2f late=%s"
                )
                % [
                    CombatantEntityAccess.get_display_name(tgt, -1),
                    CombatantEntityAccess.id_int(atk),
                    attack_type,
                    can_parry_in_time,
                    def_has_weapon,
                    block_viable,
                    redirect_viable,
                    preview_align,
                    dodge_chance,
                    late_parry
                ]
            )
        )
    if not def_has_weapon:
        choose_parry = false
    elif not can_parry_in_time:
        choose_parry = false
    else:
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    (
                        "dc_enter_def=%s atk_id=%d type=%s late_parry=%s well_aligned=%s is_glancing=%s block_v=%s "
                        + "redir_v=%s"
                    )
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        CombatantEntityAccess.id_int(atk),
                        attack_type,
                        late_parry,
                        preview_align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD,
                        (
                            preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
                            and preview_align >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR
                        ),
                        block_viable,
                        redirect_viable
                    ]
                )
            )
        var part_mod: float = CombatantEntityAccess._get_part_dodge_modifier(tgt, result.dodge_eval_part)
        var effective_dodge_chance: float = dodge_chance * part_mod
        # Below glancing floor (cos60): parry is physically ineffective — boost dodge and skip parry decision entirely.
        if preview_align < CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR:
            effective_dodge_chance *= CombatConstants.PARRY_BELOW_GLANCING_DODGE_BOOST
        elif preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD and not interpose_active:
            effective_dodge_chance *= CombatConstants.PARRY_GLANCING_DODGE_BOOST
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
        var atk_weapon_dc: Variant = CombatantEntityAccess.get_weapon(atk)
        var is_wide_arc_dc: bool = CombatConstantsParry.is_wide_arc_weapon(atk_weapon_dc)
        var eff_atk_line_dc: String = pa.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
        var guard_line_dc: String = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
        var parry_edge: bool = CombatConstants.parry_edge_deflect_reached(
            result.parry_c_d,
            result.parry_p_a,
            preview_align,
            result.is_block_parry,
            contact_type_for_parry,
            eff_atk_line_dc,
            guard_line_dc,
            is_wide_arc_dc
        )
        var agi_d: float = float(tgt_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
        var perc_d: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
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
        var glancing_exp: float = parry_cfg.get("glancing_exponent", CombatConstants.PARRY_GLANCING_EXPONENT)
        var energy_parry: float = (
            0.0 if (parry_full or parry_edge) else CombatConstants.glancing_factor(parry_remaining_est, glancing_exp)
        )
        # Historical combat favors passive defense — bias parry decision toward block/deflect over dodge.
        var passive_defense_bias: float = CombatConstants.PASSIVE_DEFENSE_BIAS
        var energy_parry_biased: float = (
            energy_parry * passive_defense_bias if not (parry_full or parry_edge) else energy_parry
        )
        var dodge_better: bool = energy_dodge < energy_parry_biased
        var clean_dodge_likely: bool = full_dodge_prob >= CombatConstants.PARRY_PREFER_DODGE_FULL_THRESHOLD
        # Alignment tiers: strong (>=cos45) -> parry preferred; glancing (cos45-cos60) -> needs stronger capacity
        # surplus;
        ## below glancing floor (cos60) -> parry physically ineffective, dodge always wins.
        var well_aligned: bool = preview_align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
        var is_glancing: bool = (
            preview_align < CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
            and preview_align >= CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR
        )
        # Glancing parries need a meaningful capacity surplus to overcome dodge energy advantage.
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    (
                        "dc_sub def=%s atk_id=%d late_parry=%s well_aligned=%s is_glancing=%s clean_dodge_likely=%s "
                        + "dodge_better=%s energy_dodge=%.3f energy_parry=%.3f"
                    )
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        CombatantEntityAccess.id_int(atk),
                        late_parry,
                        well_aligned,
                        is_glancing,
                        clean_dodge_likely,
                        dodge_better,
                        energy_dodge,
                        energy_parry
                    ]
                )
            )
        var capacity_shortfall_ratio: float = 1.0
        if result.parry_p_a > 0.001:
            capacity_shortfall_ratio = result.parry_c_d / result.parry_p_a
        var partial_parry_viable: bool = (
            well_aligned
            and not is_glancing
            and capacity_shortfall_ratio >= CombatConstants.PARRY_CAPACITY_FLOOR_RATIO * 0.5
        )
        # Below glancing floor (cos60): parry is physically ineffective — skip the parry decision
        # entirely (dodge always wins; see the dodge boost above). Exception: a block parry with
        # actual capacity (`block_viable` — a mass intercept that works regardless of blade
        # alignment) or an arm interpose (body in the path) stays available below the floor.
        var below_glancing_floor: bool = preview_align < CombatConstants.PARRY_GLANCING_ALIGNMENT_FLOOR
        var body_intercept: bool = block_viable or interpose_active
        choose_parry = (
            not (below_glancing_floor and not body_intercept)
            and (
                late_parry and (block_viable or redirect_viable)
                or (well_aligned and (block_viable or redirect_viable))
                or (partial_parry_viable and not dodge_better and not clean_dodge_likely)
                or (interpose_active and (block_viable or redirect_viable))
                or (
                    not is_glancing
                    and not clean_dodge_likely
                    and (block_viable or redirect_viable)
                    and not dodge_better
                )
            )
        )
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    (
                        "dc_out def=%s atk_id=%d type=%s choose_parry=%s late=%s well_aligned=%s is_glancing=%s "
                        + "block_v=%s redir_v=%s dodge_better=%s clean_dodge=%s align=%.3f c_d=%.2f p_a=%.2f"
                    )
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        CombatantEntityAccess.id_int(atk),
                        attack_type,
                        choose_parry,
                        late_parry,
                        well_aligned,
                        is_glancing,
                        block_viable,
                        redirect_viable,
                        dodge_better,
                        clean_dodge_likely,
                        preview_align,
                        result.parry_c_d,
                        result.parry_p_a
                    ]
                )
            )
        else:
            # Condensed always-on defense line: the decision (parry vs dodge), alignment tier, and capacity —
            # enough to judge whether a defense call is realistic without the 4 intermediate trace lines.
            var dc_tier: String = "aligned" if well_aligned else ("glancing" if is_glancing else "off")
            CombatDebug.combat_session(
                (
                    "dc def=%s vs atk=%d %s -> %s | align=%.3f (%s) late=%s c_d=%.2f p_a=%.2f"
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        CombatantEntityAccess.id_int(atk),
                        attack_type,
                        "parry" if choose_parry else "dodge",
                        preview_align,
                        dc_tier,
                        late_parry,
                        result.parry_c_d,
                        result.parry_p_a
                    ]
                )
            )
    if choose_parry:
        CombatFootwork.apply_defender_step_on_parry(
            tgt,
            str(tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)),
            CombatantEntityAccess.id_int(atk),
            manager
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
    return DefenseParryMath._get_effective_redirect(tgt)


static func arm_wound_parry_capacity_mult(arm_mod: float) -> float:
    return DefenseParryMath.arm_wound_parry_capacity_mult(arm_mod)


static func _compute_parry_c_d(def_weapon, tgt: Dictionary, contact_type: String = "") -> float:
    return DefenseParryMath._compute_parry_c_d(def_weapon, tgt, contact_type)


static func _apply_guard_line_matching(
    alignment: float, attack_line: String, tgt, can_parry_in_time: bool, proactive_boost: float
) -> float:
    return DefenseParryMath._apply_guard_line_matching(alignment, attack_line, tgt, can_parry_in_time, proactive_boost)


static func _get_contact_geometry(alignment: float, def_weapon) -> float:
    return DefenseParryMath._get_contact_geometry(alignment, def_weapon)


static func _get_leverage_factor(def_weapon, alignment: float) -> float:
    return DefenseParryMath._get_leverage_factor(def_weapon, alignment)


static func _get_parry_capacity_mult(def_weapon, tgt: Dictionary, parry_time_to_react: float) -> float:
    return DefenseParryMath._get_parry_capacity_mult(def_weapon, tgt, parry_time_to_react)


static func _parry_bonus_if_active(tgt: Dictionary) -> float:
    return DefenseParryMath._parry_bonus_if_active(tgt)


static func _get_line_alignment(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line_override: String = "",
    alignment_context: Dictionary = {},
    base_alignment: float = -1.0
) -> float:
    return DefenseParryMath._get_line_alignment(
        attack_type, tgt, effective_attack_line_override, alignment_context, base_alignment
    )


static func _alignment_with_arm_interpose(
    attack_type: String,
    tgt: Dictionary,
    effective_attack_line: String,
    alignment: float,
    targetable: Array,
    result: Dictionary
) -> float:
    return DefenseParryMath._alignment_with_arm_interpose(
        attack_type, tgt, effective_attack_line, alignment, targetable, result
    )


static func _defender_spacing_band_to_attacker(tgt: Dictionary, atk: Dictionary) -> String:
    return DefenseParryMath._defender_spacing_band_to_attacker(tgt, atk)


static func _spacing_band_parry_capacity_mult(tgt: Dictionary, atk: Dictionary) -> float:
    return DefenseParryMath._spacing_band_parry_capacity_mult(tgt, atk)


static func _reach_disparity_parry_penalty(atk: Dictionary, tgt: Dictionary) -> float:
    return DefenseParryMath._reach_disparity_parry_penalty(atk, tgt)


static func _spacing_band_dodge_chance_mult(tgt: Dictionary, atk: Dictionary) -> float:
    return DefenseParryMath._spacing_band_dodge_chance_mult(tgt, atk)


static func _feint_telegraph_dodge_spacing_mult(tgt: Dictionary, atk: Dictionary) -> float:
    return DefenseParryMath._feint_telegraph_dodge_spacing_mult(tgt, atk)


static func _feint_readiness_reveal_mult(pa: Dictionary, atk: Dictionary) -> float:
    return DefenseParryMath._feint_readiness_reveal_mult(pa, atk)


static func defender_feint_listing_pr_def(
    defender: Dictionary,
    attacker_id: int,
    move_id: String,
    attacker: Dictionary = {},
    pa_live: Dictionary = {},
    apply_stamina_and_exhaustion: bool = true,
    apply_spacing_mult: bool = true
) -> float:
    return DefenseParryMath.defender_feint_listing_pr_def(
        defender, attacker_id, move_id, attacker, pa_live, apply_stamina_and_exhaustion, apply_spacing_mult
    )


static func _defender_passive_readiness_stamina_mult(tgt: Dictionary) -> float:
    return DefenseParryMath._defender_passive_readiness_stamina_mult(tgt)


static func _defender_passive_readiness_exhaustion_mult(tgt: Dictionary) -> float:
    return DefenseParryMath._defender_passive_readiness_exhaustion_mult(tgt)


static func _feint_guard_reads_real_line(tgt: Dictionary, parry_readiness: float, attacker_id: int = -1) -> bool:
    return DefenseParryMath._feint_guard_reads_real_line(tgt, parry_readiness, attacker_id)


static func _apply_feint_telegraph_bias_to_dodge_eval_part(
    pa: Dictionary,
    tgt: Dictionary,
    atk: Dictionary,
    targetable: Array,
    result: Dictionary,
    attack_type_for_contact: String = ""
) -> void:
    DefenseParryMath._apply_feint_telegraph_bias_to_dodge_eval_part(
        pa, tgt, atk, targetable, result, attack_type_for_contact
    )


static func _guard_zone_modifier(
    pa: Dictionary,
    tgt: Dictionary,
    targetable: Array,
    attack_type: String,
    parry_readiness_for_feint: float = -1.0,
    atk_id_for_feint_spacing: int = -1
) -> float:
    return DefenseParryMath._guard_zone_modifier(
        pa, tgt, targetable, attack_type, parry_readiness_for_feint, atk_id_for_feint_spacing
    )


static func _parry_velocity_difficulty_mult(attack_velocity_m_s: float, pa: Dictionary = {}) -> float:
    return DefenseParryMath._parry_velocity_difficulty_mult(attack_velocity_m_s, pa)


static func _reach_parry_readiness_bonus(def_weapon: Variant, atk_weapon: Variant) -> float:
    return DefenseParryMath._reach_parry_readiness_bonus(def_weapon, atk_weapon)


static func _feint_open_line_parry_mult(tgt: Dictionary, incoming_line: String) -> float:
    return DefenseParryMath._feint_open_line_parry_mult(tgt, incoming_line)
