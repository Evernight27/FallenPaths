class_name CombatAIActionWeights
extends RefCounted

## Picks one action from available actions using weighted randomness. **Combat move choice is fully AI-driven:**
## WF turn pick (L2): **`CombatWeaponForm.action_weight_mult`**, **`wait_action_weight_mult`**, focus
## **`preferred_guards`**; listing path preview uses **`CombatFootwork.attack_angle_deg_for_listing_preview`** +
## **`guard_angle_deg`** when PA on '"" **`#wf-tier-44-pa`** (geometry) '. **`#wf-pick-vs-strike`**;
## **`evaluate_automatic_form`** after mental-stack miss '"" **`assign_form`** only.
## weights combine stamina + `CombatTargetScoring` (doctrine, file bias, commitment, distributed pressure, **engagement
## mode**, our formation posture+cohesion, **opponent** formation, stance). No human pick path.
## Medical: deterministic urgency + per-part threat; bandage/pack/tourniquet favor high `get_medical_effectiveness`,
## pressure favors lower skill.
## Pending retry: strongly prefer retrying the failed part when target is still in peril.
## For attacks: adds target_part from path when pathway allows (unguarded bonus). Counter-tempo listing
## (**`ACTION_KEY_COUNTER_TEMPO`**) →  **`CounterTempo.counter_tempo_listing_weight_mult`**
## (**`AI_COUNTER_TEMPO_*`**). **`is_feint`** moves get **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** →
## -  defender-readiness lerp (**`PassiveParryContext.get_passive_parry_readiness`** → -
## **`CombatConstants.passive_parry_readiness_incoming_contact_mult`** for this move'"—→s **`contact_type`** → -
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** on the defender → -
## **`CombatConstants.ai_feint_listing_defender_readiness_spacing_mult`** from defender **`distance_to[attacker]`** '""
## same curve as **`DefenseChoiceResolver`** reported readiness, not attacker stamina) →  attacker
## **`CombatWeaponForm.mod(form_str, "ai_feint_listing")`** →  defender footwork state mult
## (**`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** when off-balance; elif **`STATE_RECOVERING`**,
## **`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**; elif settled **`STATE_WAITING`**,
## **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**) →  optional low-stamina feint dampening →  formation
## doctrine **`probing`** / **`pinch_center`** / **`hold_lane`** (**`AI_FEINT_LISTING_DOCTRINE_*_MULT`**) → -
## short-horizon boost after that defender **`parry_deflect`**
## (**`COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`**, **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_*`**) (Tier 4.2).
## Feint **listing** applies **`DefenseChoiceResolver._feint_readiness_reveal_mult`** when the attacker has live
## **`pending_attack`** on the listed target (same move / wind-up progress as **`choose_defense`**).
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), _is_medical_move.


static func _verify_turn_committed_after_resolve(manager: Node, combatant_id: int, move_id: String) -> void:
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        return
    if CombatantEntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
        return
    CombatDebug.resolve_action_rejected(
        manager, combatant_id, move_id, "no state change after resolve (gauge still full)", true
    )


## Pick from **`actions`** then resolve; optional **`CombatDebug.flow_log_turn`** when **`log_side`** set.


## Shared swap-rank fitness gate: `disengage` = front yields to fitter rear; relief = rear replaces exhausted front.
static func _swap_rank_fitness_swap_allowed(c: Dictionary, partner: Dictionary, manager: Node, disengage: bool) -> bool:
    if partner == null or partner.is_empty():
        return false
    if CombatantEntityAccess.is_incapacitated(partner):
        return false
    if disengage and not CombatantEntityAccess.retreat_formation_body_damage_warranted(c, manager):
        return false
    var our_fitness: float = CombatAIActionWeights._get_positioning_fitness(c)
    var partner_fitness: float = CombatAIActionWeights._get_positioning_fitness(partner)
    var gap: float = (partner_fitness - our_fitness) if disengage else (our_fitness - partner_fitness)
    if gap <= 0.0:
        return false
    if disengage:
        if CombatantEntityAccess.get_attacking_arm(c).is_empty():
            return not CombatantEntityAccess.get_attacking_arm(partner).is_empty()
    else:
        if CombatantEntityAccess.get_attacking_arm(partner).is_empty():
            return not CombatantEntityAccess.get_attacking_arm(c).is_empty()
    var stressed_fitness: float = our_fitness if disengage else partner_fitness
    if (
        stressed_fitness <= CombatConstants.SWAP_RANK_AI_CRITICAL_FITNESS
        and gap >= CombatConstants.SWAP_RANK_AI_URGENT_MIN_GAP
    ):
        return true
    return gap >= CombatConstants.SWAP_RANK_AI_MIN_FITNESS_GAP


## True when front→ 'back disengage swap is tactically justified (matches high-weight rules in
## _get_action_weight).
## Plug-forward (incapacitated partner) is handled separately in `CombatFormationMoveListing`.
## `manager`: required for body-damage / peril gate (fatigue alone must not justify retreat).


## Returns weight for action. Medical: urgency + direct pressure bleed + pending retry.
## Combat: attack/attempt_close = use stamina (exhausted less likely to engage); `attempt_close` weight 0 unless listed
## pair (`attempt_close_listed_for_pair`); swap_rank = fitness only (no stamina).
## `skip_targeting_prune`: pass **true** when `pick()` already called `prune_expired_commitments` (avoids O(actions)
## redundant prunes).
static func _get_action_weight(
    a: Dictionary,
    combatant_id: int,
    manager: Node,
    skip_targeting_prune: bool = false,
    actor_zone_geometry_line_context: Dictionary = {},
    zone_geometry_by_combatant_id: Dictionary = {},
    all_actions: Array = []
) -> float:
    var mid: String = a.get(DataKeys.ACTION_MOVE_ID, "")
    if CombatConstants.is_medical_move(mid):
        return CombatMedicalWeighting.compute_weight(a, combatant_id, manager)
    # Combat actions: attack, attempt_close, swap_rank
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty():
        return 1.0
    if (
        CombatMobilityRetreat.cannot_commit_melee(c)
        and not CombatMobilityRetreat.resolve_move_allowed_when_cannot_melee(
            mid, a.get(DataKeys.ACTION_TARGET_ID, -1), combatant_id
        )
    ):
        return 0.0
    if mid == CombatConstants.MOVE_ID_EXECUTE:
        return CombatExecute.execute_weight(
            manager, c, CombatantEntityAccess.manager_get_combatant(manager, a.get(DataKeys.ACTION_TARGET_ID, -1))
        )
    if mid == CombatConstants.MOVE_ID_WAIT:
        var preset_w: float = a.get(DataKeys.ACTION_WEIGHT, -1.0)
        if preset_w >= 0.0:
            return preset_w
        if (
            CombatMobilityRetreat.formation_retreat_only_for(c)
            and CombatFormationRout.duel_disarmed_retreat_menu(manager, c)
        ):
            return CombatConstants.DUEL_DISARMED_WAIT_AI_WEIGHT
        var wait_w: float = CombatWeaponForm.wait_action_weight_mult(
            CombatantEntityAccess.form_str(c), CombatantEntityAccess.get_weapon(c)
        )
        var fid_wait: String = CombatantEntityAccess.formation_id_str(c)
        if not all_actions.is_empty():
            if CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
                if CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid_wait):
                    wait_w *= CombatConstants.AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT
                elif (
                    CombatDoctrine.envelop_mop_up_active(manager, fid_wait)
                    or CombatDoctrine.mop_up_underdog_active(manager, c)
                ):
                    wait_w *= CombatConstants.AI_WAIT_MOP_UP_FINISH_MULT
            else:
                wait_w *= CombatConstants.AI_WAIT_NO_STRIKE_MULT
        var mood_wait_mult: float = CombatCampaignMoodBias.wait_action_weight_mult(
            CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
        )
        wait_w *= mood_wait_mult
        wait_w *= CombatMuscleFatigue.wait_recovery_weight_mult(c)
        return wait_w
    if mid == CombatConstants.MOVE_ID_REGAIN_FOOTING and a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
        # Only meaningful while off-balance; fade with depth so a nearly-settled fighter no longer
        # prefers it over striking.
        if PassiveParryContext.is_off_balance(c):
            return CombatConstants.REGAIN_FOOTING_AI_WEIGHT * PassiveParryContext.off_balance_depth(c)
        return 0.0
    if CombatConstants.is_focus_line_move(mid):
        return CombatAIActionWeights._focus_line_action_weight(mid, combatant_id, manager, c, all_actions)
    if CombatConstants.is_leader_formation_command_move(mid):
        if a.get(DataKeys.ACTION_TARGET_ID, -1) != combatant_id:
            return 0.0
        if not CombatantEntityAccess.is_formation_command_issuer(c):
            return 0.0
        return CombatAIActionWeights._leader_formation_command_pick_weight(manager, c, mid)
    if mid == CombatConstants.MOVE_ID_FLEE and a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
        if CombatMobilityRetreat.formation_retreat_only_for(c):
            if CombatFormationRout.duel_disarmed_retreat_menu(manager, c):
                return CombatConstants.DUEL_DISARMED_FLEE_AI_WEIGHT
            return CombatConstants.COWERING_FLEE_AI_WEIGHT
        var flee_w: float = CombatConstants.AI_FLEE_ROUTINE_WEIGHT * CombatFormationRout.flee_ai_pick_mult(manager, c)
        if CombatFormationRout.duel_blocks_armed_flee(manager, c):
            return 0.0
        if (
            CombatExhaustion.exhaustion_tunnel_active(c)
            or CombatantEntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
        ):
            flee_w = maxf(flee_w, CombatConstants.AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT)
        var mood_flee_mult: float = CombatCampaignMoodBias.flee_action_weight_mult(
            CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
        )
        flee_w *= mood_flee_mult
        return flee_w
    if mid == CombatConstants.MOVE_ID_YIELD and a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
        if CombatFormationRout.duel_disarmed_retreat_menu(manager, c):
            return CombatConstants.DUEL_DISARMED_YIELD_AI_WEIGHT
        return 0.0
    if mid == CombatConstants.MOVE_ID_FALL_BACK and a.get(DataKeys.ACTION_TARGET_ID, -1) == combatant_id:
        if CombatMobilityRetreat.formation_retreat_only_for(c):
            return CombatConstants.COWERING_SOLO_FALL_BACK_AI_WEIGHT
        # Offered only when desperate / peril (AvailableActionsBuilder); keep below routine wait.
        var mood_disengage_mult: float = CombatCampaignMoodBias.disengage_action_weight_mult(
            CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
        )
        return (
            0.45
            * mood_disengage_mult
            / CombatAIActionWeights._opponent_controlling_disengage_listing_divisor(manager, c)
        )
    if mid == CombatConstants.MOVE_ID_ROTATE_FILE:
        var partner_id_rot: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if CombatFormationFlow.rotate_file_reverse_pair_blocked(manager, c, partner_id_rot):
            return 0.0
        if not all_actions.is_empty() and CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, all_actions):
            return 0.0
        var rot_w: float = 0.55
        var lane_preview: Dictionary = CombatFormationMoveDuration.preview_lane_pressure_for_combatant(manager, c)
        if lane_preview.get(DataKeys.DURATION_LANE_FOOT, 0.0) >= CombatConstants.LANE_MOD_BLOCKED - 0.05:
            rot_w *= CombatConstants.AI_FORMATION_MOVE_BLOCKED_LANE_MULT
        if CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c)):
            rot_w *= CombatConstants.ENVELOP_MOP_UP_ROTATE_AI_WEIGHT_MULT
        var engagement_listed: bool = (
            not all_actions.is_empty() and CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
        )
        var close_only_long: bool = CombatAIActionWeights._long_close_only_offense_menu(
            manager, c, combatant_id, all_actions
        )
        if engagement_listed:
            if close_only_long:
                rot_w *= CombatConstants.AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT
            else:
                rot_w *= CombatConstants.AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT
        var fid_rot: String = CombatantEntityAccess.formation_id_str(c)
        if (
            not engagement_listed
            and CombatFormationFlow.formation_line_has_rank0_gap(manager, fid_rot)
            and not CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid_rot)
            and not (
                not all_actions.is_empty()
                and CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, all_actions, combatant_id)
            )
        ):
            rot_w = maxf(rot_w, CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT)
        return rot_w
    ## III-4 **3e**: plug_forward AI weight during envelop mop-up.
    if mid == CombatConstants.MOVE_ID_PLUG_FORWARD:
        var partner_id_pf: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if partner_id_pf < 0:
            return 0.0
        var partner_pf: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, partner_id_pf)
        if partner_pf.is_empty():
            return 0.0
        if not CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.side_str(c)):
            return 0.0
        var engagement_listed: bool = (
            not all_actions.is_empty() and CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
        )
        ## When this unit already has strikes listed, suppress plug_forward so the weighted pick
        ## does not compete with and beat viable strikes. High weight only when the unit cannot
        ## strike at all (LONG band, no reach) and needs to close into engagement range.
        if engagement_listed:
            return CombatConstants.PLUG_FORWARD_AI_LOW_WEIGHT
        ## When the rank-0 partner already has strikes, plugging forward would displace a fighter
        ## that can already engage '"" suppress so the line does not shuffle unnecessarily during mop-up.
        ## Uses cheap distance check instead of rebuilding partner's full action list (avoids
        ## vacancy reconciliation cost when _get_action_weight is called twice per action).
        var partner_has_strikes: bool = false
        if manager != null and not partner_pf.is_empty():
            var dist_data: Variant = partner_pf.get(DataKeys.COMBATANT_DISTANCE_TO, {})
            if dist_data is Dictionary:
                var hostile_side: String = CombatantEntityAccess.opponent_side_label(CombatantEntityAccess.side_str(c))
                for _k in dist_data:
                    if dist_data[_k] == "CLOSE" or dist_data[_k] == "MEDIUM":
                        var hostile: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, int(_k))
                        if not hostile.is_empty() and CombatantEntityAccess.is_alive_in_combat(hostile):
                            if CombatantEntityAccess.side_str(hostile) == hostile_side:
                                partner_has_strikes = true
                                break
        if partner_has_strikes:
            return CombatConstants.PLUG_FORWARD_AI_LOW_WEIGHT
        return CombatConstants.PLUG_FORWARD_AI_HIGH_WEIGHT
    if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        var tgt_id_close: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tgt_id_close < 0:
            return 0.0
        var dist_close: String = CombatantEntityAccess.distance_to_opponent_band(c, tgt_id_close)
        if CombatMeleeListing.close_attempt_pair_blocked(manager, c, tgt_id_close):
            if (
                not all_actions.is_empty()
                and CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
            ):
                return CombatConstants.AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT
            return 0.0
        if not CombatMeleeListing.attempt_close_listed_for_pair(manager, c, tgt_id_close, dist_close):
            if (
                not all_actions.is_empty()
                and CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
            ):
                return CombatConstants.AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT
            return 0.0
        if dist_close == CombatConstants.DISTANCE_CLOSE or dist_close == CombatConstants.DISTANCE_MID:
            if CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c)):
                return 0.0
            if (
                not all_actions.is_empty()
                and CombatListedActions.action_list_has_hostile_melee_strike(all_actions, combatant_id)
                and (
                    CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
                    or CombatFormationFlow.skirmish_line_sparse_after_casualties(
                        manager, CombatantEntityAccess.formation_id_str(c)
                    )
                )
            ):
                return 0.0
    if mid in [CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK, CombatConstants.MOVE_ID_FALL_BACK]:
        if (
            mid == CombatConstants.MOVE_ID_SWAP_RANK
            and not all_actions.is_empty()
            and CombatantEntityAccess.rank_int(c) == 0
            and CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
            and CombatDoctrine.fight_finish_tail_active(manager, c, all_actions, combatant_id)
        ):
            return 0.0
        var partner_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        var partner: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, partner_id)
        var partner_incapacitated: bool = not partner.is_empty() and CombatantEntityAccess.is_incapacitated(partner)
        if partner_incapacitated:
            # Back rank plugging forward '"" partner (front) is incapacitated; strongly prefer.
            return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
        if not partner.is_empty() and CombatantEntityAccess.rank_int(c) > CombatantEntityAccess.rank_int(partner):
            # Deeper rank swapping up (relief) '"" only swap_rank is offered for this path in builder.
            if mid != CombatConstants.MOVE_ID_SWAP_RANK:
                return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
            if CombatAIActionPicker.is_relief_swap_tactically_allowed(c, partner):
                return CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
            var fid_plug: String = CombatantEntityAccess.formation_id_str(c)
            if (
                CombatFormationFlow.formation_line_has_rank0_gap(manager, fid_plug)
                and not CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid_plug)
                and (
                    all_actions.is_empty()
                    or not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, all_actions, combatant_id)
                )
            ):
                return CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT
            return CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
        if not partner.is_empty() and CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, partner, manager):
            var mood_dm: float = CombatCampaignMoodBias.disengage_action_weight_mult(
                CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
            )
            return (
                CombatConstants.SWAP_RANK_AI_HIGH_WEIGHT
                * mood_dm
                / CombatAIActionWeights._opponent_controlling_disengage_listing_divisor(manager, c)
            )
        var mood_dm2: float = CombatCampaignMoodBias.disengage_action_weight_mult(
            CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
        )
        return (
            CombatConstants.SWAP_RANK_AI_LOW_WEIGHT
            * mood_dm2
            / CombatAIActionWeights._opponent_controlling_disengage_listing_divisor(manager, c)
        )
    # Attack or attempt_close: engaging the enemy '"" use stamina + hybrid targeting (doctrine, file, pressure).
    var comps: Dictionary = CombatAIActionWeights._compute_attack_weight_components(
        a,
        combatant_id,
        manager,
        mid,
        c,
        skip_targeting_prune,
        actor_zone_geometry_line_context,
        zone_geometry_by_combatant_id,
        all_actions
    )
    var post_strike_mult: float = CombatAIActionWeights._post_strike_weight_mult(c, a, manager)
    # XCamp-6 (gladiator): a school fighter's scouted aggression tendency scales its attack
    # commitment (all-in fighters weigh offense higher; cautious ones lower). 1.0 when the
    # combatant carries no tendency, so campaign/arena/D001 picks are unchanged.
    var school_tend_aggr_m: float = CombatConstantsAIWeights.school_tendency_aggression_mult(c)
    return (
        comps.weight
        * CombatAIActionWeights._salience_offense_weight_mult(c, manager)
        * post_strike_mult
        * school_tend_aggr_m
    )


## Extracted from **`_get_action_weight`** for auditability. Returns `{weight, ...}` dictionary.
## Computes all per-attack multipliers: stamina base, polearm lane, form weights, counter-read,
## feint listing (readiness, footwork state, doctrine, yomi), counter-tempo, attrition, exhaustion.
static func _compute_attack_weight_components(
    a: Dictionary,
    combatant_id: int,
    manager: Node,
    move_id: String,
    c: Dictionary,
    skip_targeting_prune: bool,
    actor_zone_geometry_line_context: Dictionary,
    zone_geometry_by_combatant_id: Dictionary,
    all_actions: Array
) -> Dictionary:
    var stamina_ratio: float = CombatantEntityAccess.stamina_ratio(c)
    var base_stamina: float = CombatConstants.ai_offense_stamina_weight_mult(stamina_ratio)
    var polearm_lane: float = CombatAIActionWeights._depth_polearm_action_weight_mult(
        manager, c, move_id, actor_zone_geometry_line_context
    )
    var form_move_m: float = CombatWeaponForm.action_weight_mult(
        CombatantEntityAccess.form_str(c), move_id, CombatantEntityAccess.get_weapon(c)
    )
    var prof_occ_m: float = 1.0
    var ent_node: CoreEntity = CombatantEntityAccess.scene_entity(c)
    if ent_node != null:
        prof_occ_m = EntityProficiency.proficiency_occurrence_mult(
            ent_node, CombatantEntityAccess.weapon_type_id(c), CombatantEntityAccess.form_str(c), move_id
        )
    form_move_m *= prof_occ_m
    var form_counter_m: float = 1.0
    var tid_counter: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
    if tid_counter >= 0:
        var inferred: String = ""
        var cache_raw: Variant = c.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
        if cache_raw is Dictionary:
            inferred = cache_raw.get(str(tid_counter), "").strip_edges()
        if inferred.is_empty():
            inferred = CombatWeaponForm.infer_opponent_form(manager, c, tid_counter)
        form_counter_m = CombatWeaponForm.form_counter_mult(
            CombatantEntityAccess.form_str(c), inferred, move_id, CombatantEntityAccess.get_weapon(c)
        )
        # A2: meisterhau-family cuts are risky without yomi commitment — scale counter bonus down
        # when the fighter is not holding a committed counter-read against this target.
        if form_counter_m > 1.0 and move_id in ["zornhau", "scheitelhau", "krumphau", "schielhau"]:
            if not CombatWeaponForm.is_counter_read_committed(c, CombatantEntityAccess.combat_clock_float(manager)):
                form_counter_m = lerpf(1.0, form_counter_m, CombatConstants.A2_MEISTERHAU_CONFIDENCE_SCALE_FACTOR)
    var feint_list_m: float = 1.0
    if move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE and WeaponConstants.is_feint_move(move_id):
        var tid_feint: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        var resistance_active: bool = (
            CombatConstants.is_feature_ms_feint_resistance_enabled()
            and tid_feint >= 0
            and not CombatantEntityAccess.manager_get_combatant(manager, tid_feint).is_empty()
            and CombatAIActionWeights._is_feint_resistance_active(tid_feint, manager)
        )
        if resistance_active:
            CombatDebug.flow_log(
                (
                    "feint_resistance active move=%s vs defender=%d readiness=%.2f state=%s"
                    % [
                        move_id,
                        tid_feint,
                        PassiveParryContext.get_passive_parry_readiness(
                            CombatantEntityAccess.manager_get_combatant(manager, tid_feint)
                        ),
                        CombatantEntityAccess.state_str(CombatantEntityAccess.manager_get_combatant(manager, tid_feint))
                    ]
                )
            )
        var pr_def: float = 0.0
        if tid_feint >= 0:
            var tgt_feint: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid_feint)
            if not tgt_feint.is_empty():
                var pa_live: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
                pr_def = DefenseChoiceResolver.defender_feint_listing_pr_def(
                    tgt_feint, CombatantEntityAccess.id_int(c), move_id, c, pa_live
                )
        var read_m: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)
        var stance_feint_m: float = CombatWeaponForm.mod(
            CombatantEntityAccess.form_str(c), "ai_feint_listing", CombatantEntityAccess.get_weapon(c)
        )
        feint_list_m = (CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * stance_feint_m)
        if tid_feint >= 0:
            var tgt_ob: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid_feint)
            if not tgt_ob.is_empty():
                if not resistance_active:
                    if PassiveParryContext.is_off_balance(tgt_ob):
                        feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
                    elif CombatantEntityAccess.state_str(tgt_ob) == CombatConstants.STATE_RECOVERING:
                        feint_list_m *= CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
                            str(tgt_ob.get(DataKeys.ATTACK_RECOVERY_CAUSE, "skip"))
                        )
                    elif CombatantEntityAccess.state_str(tgt_ob) == CombatConstants.STATE_WAITING:
                        feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
                if stamina_ratio < CombatConstants.AI_FEINT_LISTING_STAMINA_GATE:
                    var st_feint_stamina: float = lerpf(
                        CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
                        1.0,
                        stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
                    )
                    feint_list_m *= st_feint_stamina
                var fid_atk: String = CombatantEntityAccess.formation_id_str(c)
                var doc_feint: String = CombatDoctrine.doctrine_for_fid(manager, fid_atk)
                match doc_feint:
                    CombatConstants.DOCTRINE_PROBING:
                        feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
                    CombatConstants.DOCTRINE_PINCH_CENTER:
                        feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
                    CombatConstants.DOCTRINE_HOLD_LANE:
                        feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
                feint_list_m *= CombatAttackWeighting._feint_listing_opp_parry_deflect_pressure_mult(
                    manager, c, tid_feint
                )
                if tid_feint >= 0:
                    var tgt_yomi: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid_feint)
                    if not tgt_yomi.is_empty():
                        var dom_line: String = CombatAttention.dominant_attack_line_toward_defender(
                            tgt_yomi, combatant_id
                        )
                        var fp_est: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, "head")
                        feint_list_m *= CombatAttention.yomi_feint_listing_mult(tgt_yomi, combatant_id, fp_est)
                        feint_list_m *= CombatAttention.yomi_parry_deflect_feint_listing_mult(tgt_yomi, combatant_id)
    var counter_tempo_m: float = CounterTempo.counter_tempo_listing_weight_mult(manager, combatant_id, a, move_id)
    var attrition_m: float = CombatAIActionWeights._attrition_offense_weight_mult(manager, c)
    var exh_offense_m: float = CombatExhaustion.exhaustion_offense_weight_mult(c)
    var muscle_f_m: float = CombatMuscleFatigue.offense_weight_mult(c, move_id, manager)
    var decision_q_m: float = CombatExhaustion.decision_quality_mult(c)
    var mood_offense_m: float = CombatCampaignMoodBias.offense_action_weight_mult(
        CombatCampaignMoodBias.mood_bias_for_combatant(manager, c)
    )
    var target_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
    var opp_degrad_m: float = 1.0
    # Wounded-opponent exploit applies to ALL offensive moves (not just feints) — a real fighter finishes the
    # weakest target. The old feint-only gate left the AI blind to wound state when choosing which enemy to strike.
    if target_id >= 0 and move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        opp_degrad_m = _opponent_degradation_weight_mult(manager, target_id)
    # Yomi/attention: a target that is highly focused on you is more likely to read and parry the strike.
    # Scales offensive weight down from 1.0 (target unfocused, weight 0.25) to ATTENTION_FOCUSED_OFFENSE_WEIGHT_MIN.
    var focus_read_m: float = 1.0
    if target_id >= 0 and move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        var focus_tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
        if not focus_tgt.is_empty():
            var atk_weight: float = CombatAttention.get_attention_weight(focus_tgt, combatant_id)
            var focus_t: float = clampf((atk_weight - 0.25) / 0.75, 0.0, 1.0)
            focus_read_m = lerpf(1.0, CombatConstants.ATTENTION_FOCUSED_OFFENSE_WEIGHT_MIN, focus_t)
    # Open/guarded line bias: prefer striking the line the defender is NOT covering.
    # A fencer does not hammer a guarded line; open lines are where hits actually land.
    # Moderate by design (see AI_OPEN_LINE_MULT) — timing/stamina/wounds still compete.
    var open_guard_m: float = 1.0
    var line_fail_m: float = 1.0
    var yomi_vary_m: float = 1.0
    var feint_open_line_m: float = 1.0
    var feint_read_fail_m: float = 1.0
    if target_id >= 0 and move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        var og_tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
        if not og_tgt.is_empty():
            var og_move_def: Dictionary = WeaponConstants.get_move(move_id)
            var og_atk_line: String = str(og_move_def.get(DataKeys.PA_ATTACK_LINE, ""))
            var og_guard_line: String = str(og_tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT))
            var og_counter: bool = bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false))
            open_guard_m = open_guard_line_weight_mult(og_atk_line, og_guard_line, move_id, og_tgt, og_counter)
            line_fail_m = line_fail_weight_mult(c, og_atk_line, manager)
            yomi_vary_m = yomi_vary_weight_mult(og_tgt, combatant_id, og_atk_line)
            feint_open_line_m = _feint_open_line_mult(og_tgt, og_atk_line)
            # A feint on an already-open line is inert — there is no guard there to draw a
            # reaction, so the deception has nothing to commit the defender onto. The opening
            # is exploited by a REAL strike, not by re-feinting it. Gate the open-line boost to
            # honest strikes; feints keep only the generic open/guarded bias. (No open-line state
            # in the ratio fixtures, so this does not perturb the pinned feint/plain ratios.)
            if WeaponConstants.is_feint_move(move_id):
                feint_open_line_m = 1.0
            feint_read_fail_m = _feint_read_fail_mult(c, og_atk_line, move_id, manager)
    var w: float = (
        base_stamina
        * CombatTargetScoring.ai_targeting_weight_mult(
            manager,
            combatant_id,
            a,
            skip_targeting_prune,
            actor_zone_geometry_line_context,
            zone_geometry_by_combatant_id
        )
        * polearm_lane
        * form_move_m
        * form_counter_m
        * feint_list_m
        * counter_tempo_m
        * attrition_m
        * exh_offense_m
        * muscle_f_m
        * decision_q_m
        * mood_offense_m
        * opp_degrad_m
        * focus_read_m
        * open_guard_m
        * line_fail_m
        * yomi_vary_m
        * feint_open_line_m
        * feint_read_fail_m
    )
    if (
        move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
        and CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c))
    ):
        w *= CombatConstants.ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT
    if (
        move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
        and CombatFormationFlow.skirmish_line_sparse_after_casualties(
            manager, CombatantEntityAccess.formation_id_str(c)
        )
    ):
        w *= CombatConstants.AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT
    elif (
        not all_actions.is_empty()
        and CombatFormationFlow.skirmish_line_sparse_after_casualties(
            manager, CombatantEntityAccess.formation_id_str(c)
        )
        and CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id)
    ):
        w *= CombatConstants.AI_SPARSE_LINE_OFFENSE_MULT
    if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        var tgt_id_close_w: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tgt_id_close_w >= 0:
            var tgt_close: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_id_close_w)
            if not tgt_close.is_empty():
                w *= CombatWeaponForm.opponent_close_listing_weight_mult_for_defender(tgt_close)
        if (
            not all_actions.is_empty()
            and CombatAIActionWeights._long_close_only_offense_menu(manager, c, combatant_id, all_actions)
            and CombatantEntityAccess.distance_to_opponent_band(c, tgt_id_close_w) == CombatConstants.DISTANCE_LONG
        ):
            w *= CombatConstants.AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT
        elif EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
            w *= CombatConstants.AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT
    w *= TacticalCombat.iv12_offense_weight_mult(manager, combatant_id)
    return {"weight": w, "occ_mult": prof_occ_m}


## AI action-weight modifiers extracted to CombatAIWeightModifiers (pure code-motion split).
## The thin delegates below keep existing call sites unchanged.


static func open_guard_line_weight_mult(
    atk_line: String, guard_line: String, move_id: String, defender: Dictionary, is_counter_tempo: bool
) -> float:
    return CombatAIWeightModifiers.open_guard_line_weight_mult(
        atk_line, guard_line, move_id, defender, is_counter_tempo
    )


static func line_fail_weight_mult(attacker: Dictionary, candidate_line: String, manager: Node) -> float:
    return CombatAIWeightModifiers.line_fail_weight_mult(attacker, candidate_line, manager)


static func yomi_vary_weight_mult(defender: Dictionary, attacker_id: int, candidate_line: String) -> float:
    return CombatAIWeightModifiers.yomi_vary_weight_mult(defender, attacker_id, candidate_line)


static func _defender_live_feint_open_line(defender: Dictionary) -> String:
    return CombatAIWeightModifiers._defender_live_feint_open_line(defender)


static func _feint_open_line_mult(defender: Dictionary, candidate_line: String) -> float:
    return CombatAIWeightModifiers._feint_open_line_mult(defender, candidate_line)


static func _feint_read_fail_mult(
    attacker: Dictionary, candidate_line: String, move_id: String, manager: Node
) -> float:
    return CombatAIWeightModifiers._feint_read_fail_mult(attacker, candidate_line, move_id, manager)


static func _leader_formation_command_pick_weight(manager: Node, c: Dictionary, move_id: String) -> float:
    return CombatAIWeightModifiers._leader_formation_command_pick_weight(manager, c, move_id)


static func _long_close_only_offense_menu(manager: Node, c: Dictionary, combatant_id: int, all_actions: Array) -> bool:
    return CombatAIWeightModifiers._long_close_only_offense_menu(manager, c, combatant_id, all_actions)


static func _post_strike_weight_mult(c: Dictionary, a: Dictionary, manager: Node) -> float:
    return CombatAIWeightModifiers._post_strike_weight_mult(c, a, manager)


static func _is_feint_resistance_active(defender_id: int, manager: Node) -> bool:
    return CombatAIWeightModifiers._is_feint_resistance_active(defender_id, manager)


static func _salience_offense_weight_mult(c: Dictionary, manager: Node = null) -> float:
    return CombatAIWeightModifiers._salience_offense_weight_mult(c, manager)


static func _attrition_offense_weight_mult(manager: Node, c: Dictionary) -> float:
    return CombatAIWeightModifiers._attrition_offense_weight_mult(manager, c)


static func _fight_finish_focus_damp_mult(manager: Node, c: Dictionary, combatant_id: int, all_actions: Array) -> float:
    return CombatAIWeightModifiers._fight_finish_focus_damp_mult(manager, c, combatant_id, all_actions)


static func _focus_line_action_weight(
    move_id: String, combatant_id: int, manager: Node, c: Dictionary, all_actions: Array = []
) -> float:
    return CombatAIWeightModifiers._focus_line_action_weight(move_id, combatant_id, manager, c, all_actions)


static func _guard_priority_focus_mult(c: Dictionary, line: String) -> float:
    return CombatAIWeightModifiers._guard_priority_focus_mult(c, line)


static func _form_focus_preferred_mult(c: Dictionary, line: String) -> float:
    return CombatAIWeightModifiers._form_focus_preferred_mult(c, line)


static func _opponent_controlling_disengage_listing_divisor(manager: Node, c: Dictionary) -> float:
    return CombatAIWeightModifiers._opponent_controlling_disengage_listing_divisor(manager, c)


static func _depth_polearm_action_weight_mult(
    manager: Node, c: Dictionary, move_id: String, actor_zone_geometry_line_context: Dictionary = {}
) -> float:
    return CombatAIWeightModifiers._depth_polearm_action_weight_mult(
        manager, c, move_id, actor_zone_geometry_line_context
    )


static func _get_positioning_fitness(c: Dictionary) -> float:
    return CombatAIWeightModifiers._get_positioning_fitness(c)


static func _opponent_degradation_weight_mult(manager: Node, target_id: int) -> float:
    return CombatAIWeightModifiers._opponent_degradation_weight_mult(manager, target_id)
