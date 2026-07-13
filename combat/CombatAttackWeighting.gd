class_name CombatAttackWeighting
extends RefCounted

## Per-factor attack weight computation extracted from **`CombatAIActionPicker._compute_attack_weight_components`**.
## Each factor is independently auditable and tunable. The main entry point composes them into a final weight.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _CombatAttention := preload("res://combat/CombatAttention.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _Bp := preload("res://core/BodyPartConstants.gd")


## Main entry: compute attack weight by composing all per-factor multipliers.
static func compute_weight(
    a: Dictionary,
    combatant_id: int,
    manager: Node,
    move_id: String,
    c: Dictionary,
    skip_targeting_prune: bool,
    actor_zone_geometry_line_context: Dictionary,
    zone_geometry_by_combatant_id: Dictionary,
    all_actions: Array
) -> float:
    var stamina_ratio: float = _EntityAccess.stamina_ratio(c)

    # Core factors (always computed)
    var base_stamina: float = _factor_base_stamina(stamina_ratio)
    var polearm_lane: float = _factor_polearm_lane(manager, c, move_id, actor_zone_geometry_line_context)
    var form_move_m: float = _factor_form_move(_EntityAccess.form_str(c), move_id, c)
    var form_counter_m: float = _factor_form_counter(manager, c, a)
    var targeting_m: float = _factor_targeting(
        manager, combatant_id, a, skip_targeting_prune, actor_zone_geometry_line_context, zone_geometry_by_combatant_id
    )
    var counter_tempo_m: float = _factor_counter_tempo(manager, combatant_id, a, move_id)
    var attrition_m: float = _factor_attrition(manager, c)
    var exh_offense_m: float = _factor_exhaustion(c)

    # Feint listing (only for feint moves)
    var feint_list_m: float = 1.0
    if move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE and _WeaponConstants.is_feint_move(move_id):
        feint_list_m = _factor_feint_listing(manager, combatant_id, a, c, stamina_ratio)

    # Compose core factors
    var w: float = (
        base_stamina
        * targeting_m
        * polearm_lane
        * form_move_m
        * form_counter_m
        * feint_list_m
        * counter_tempo_m
        * attrition_m
        * exh_offense_m
    )

    # Post-compose: attempt_close specific modifiers
    w = _apply_attempt_close_modifiers(w, move_id, a, combatant_id, c, manager, all_actions)

    # IV-12 slot distraction
    w *= _TacticalCombat.iv12_offense_weight_mult(manager, combatant_id)

    return w


# '"''''"''' Per-factor functions '"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"''''"'''


static func _factor_base_stamina(stamina_ratio: float) -> float:
    return CombatConstants.ai_offense_stamina_weight_mult(stamina_ratio)


static func _factor_polearm_lane(
    manager: Node, c: Dictionary, move_id: String, actor_zone_geometry_line_context: Dictionary
) -> float:
    return _DepthPolearm.depth_polearm_action_weight_mult(manager, c, move_id, actor_zone_geometry_line_context)


static func _factor_form_move(form: String, move_id: String, c: Dictionary) -> float:
    return _WeaponForm.action_weight_mult(form, move_id, _EntityAccess.get_weapon(c))


static func _factor_form_counter(manager: Node, c: Dictionary, a: Dictionary) -> float:
    var tid_counter: int = a.get("target_id", -1)
    if tid_counter < 0:
        return 1.0
    var inferred: String = ""
    var cache_raw: Variant = c.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
    if cache_raw is Dictionary:
        inferred = (cache_raw as Dictionary).get(str(tid_counter), "").strip_edges()
    if inferred.is_empty():
        inferred = _WeaponForm.infer_opponent_form(manager, c, tid_counter)
    return _WeaponForm.form_counter_mult(
        _EntityAccess.form_str(c), inferred, a.get("move_id", ""), _EntityAccess.get_weapon(c)
    )


static func _factor_targeting(
    manager: Node,
    combatant_id: int,
    a: Dictionary,
    skip_targeting_prune: bool,
    actor_zone_geometry_line_context: Dictionary,
    zone_geometry_by_combatant_id: Dictionary
) -> float:
    return _TargetScoring.ai_targeting_weight_mult(
        manager, combatant_id, a, skip_targeting_prune, actor_zone_geometry_line_context, zone_geometry_by_combatant_id
    )


static func _factor_counter_tempo(manager: Node, combatant_id: int, a: Dictionary, move_id: String) -> float:
    return _CounterTempo.counter_tempo_listing_weight_mult(manager, combatant_id, a, move_id)


static func _factor_attrition(manager: Node, c: Dictionary) -> float:
    if manager == null:
        return 1.0
    var fid: String = _EntityAccess.formation_id_str(c)
    if _CombatDoctrine.envelop_mop_up_active(manager, fid):
        return 1.0
    if _CombatDoctrine.mop_up_underdog_active(manager, c):
        return 1.0
    if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        return 1.0
    var side: String = _EntityAccess.side_str(c)
    var standing: int = _EngagementMode.count_active_for_side(manager, side)
    if standing <= int(CombatConstants.AI_ATTRITION_LOW_STANDING_MAX):
        return CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT
    return 1.0


static func _factor_exhaustion(c: Dictionary) -> float:
    return _Exhaustion.exhaustion_offense_weight_mult(c)


## Feint listing weight factor: readiness, footwork state, doctrine, yomi, stamina gate.
static func _factor_feint_listing(
    manager: Node, combatant_id: int, a: Dictionary, c: Dictionary, stamina_ratio: float
) -> float:
    var tid_feint: int = a.get("target_id", -1)

    # Defender readiness (pr_def)
    var pr_def: float = 0.0
    if tid_feint >= 0:
        var tgt_feint: Dictionary = _EntityAccess.manager_get_combatant(manager, tid_feint)
        if not tgt_feint.is_empty():
            var pa_live: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
            pr_def = _DefenseChoice.defender_feint_listing_pr_def(
                tgt_feint, _EntityAccess.id_int(c), a.get("move_id", ""), c, pa_live
            )

    var read_m: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)
    var stance_feint_m: float = _WeaponForm.mod(
        _EntityAccess.form_str(c), "ai_feint_listing", _EntityAccess.get_weapon(c)
    )
    var feint_list_m: float = CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * stance_feint_m

    if tid_feint >= 0:
        var tgt_ob: Dictionary = _EntityAccess.manager_get_combatant(manager, tid_feint)
        if not tgt_ob.is_empty():
            if _PassiveParry.is_off_balance(tgt_ob):
                feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
            elif _EntityAccess.state_str(tgt_ob) == CombatConstants.STATE_RECOVERING:
                feint_list_m *= CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
                    str(tgt_ob.get("recovery_cause", "skip"))
                )
            elif _EntityAccess.state_str(tgt_ob) == CombatConstants.STATE_WAITING:
                feint_list_m *= CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT

    # Stamina gate for feints
    if stamina_ratio < CombatConstants.AI_FEINT_LISTING_STAMINA_GATE:
        var st_feint_stamina: float = lerpf(
            CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
            1.0,
            stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
        )
        feint_list_m *= st_feint_stamina

    # Doctrine context
    var fid_atk: String = _EntityAccess.formation_id_str(c)
    var doc_feint: String = _CombatDoctrine.doctrine_for_fid(manager, fid_atk)
    match doc_feint:
        CombatConstants.DOCTRINE_PROBING:
            feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
        CombatConstants.DOCTRINE_PINCH_CENTER:
            feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
        CombatConstants.DOCTRINE_HOLD_LANE:
            feint_list_m *= CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT

    # Parry-deflect recency pressure
    feint_list_m *= _feint_listing_opp_parry_deflect_pressure_mult(manager, c, tid_feint)

    # Yomi
    if tid_feint >= 0:
        var tgt_yomi: Dictionary = _EntityAccess.manager_get_combatant(manager, tid_feint)
        if not tgt_yomi.is_empty():
            var dom_line: String = _CombatAttention.dominant_attack_line_toward_defender(tgt_yomi, combatant_id)
            var fp_est: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom_line, _Bp.PART_HEAD)
            feint_list_m *= _CombatAttention.yomi_feint_listing_mult(tgt_yomi, combatant_id, fp_est)
            feint_list_m *= _CombatAttention.yomi_parry_deflect_feint_listing_mult(tgt_yomi, combatant_id)

    return feint_list_m


## Post-compose modifiers for attempt_close specific logic.
static func _apply_attempt_close_modifiers(
    w: float, move_id: String, a: Dictionary, combatant_id: int, c: Dictionary, manager: Node, all_actions: Array
) -> float:
    if move_id != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return w

    var tgt_id_close_w: int = a.get("target_id", -1)
    var fid: String = _EntityAccess.formation_id_str(c)

    # Envelop mop-up close boost
    if _CombatDoctrine.envelop_mop_up_active(manager, fid):
        w *= CombatConstants.ENVELOP_MOP_UP_CLOSE_AI_WEIGHT_MULT

    # Sparse line modifiers
    if _FormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        if _ListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
            w *= CombatConstants.AI_SPARSE_LINE_OFFENSE_MULT
        else:
            w *= CombatConstants.AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT

    # Defender close listing weight
    if tgt_id_close_w >= 0:
        var tgt_close: Dictionary = _EntityAccess.manager_get_combatant(manager, tgt_id_close_w)
        if not tgt_close.is_empty():
            w *= _WeaponForm.opponent_close_listing_weight_mult_for_defender(tgt_close)

    # Long close-only offense dampening
    if (
        not all_actions.is_empty()
        and _long_close_only_offense_menu(manager, c, combatant_id, all_actions)
        and _EntityAccess.distance_to_opponent_band(c, tgt_id_close_w) == CombatConstants.DISTANCE_LONG
    ):
        w *= CombatConstants.AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT
    elif _EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
        w *= CombatConstants.AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT

    return w


## LONG band, close listed but no melee strikes --" mapped rank-0 band-lag shuffle.
static func _long_close_only_offense_menu(manager: Node, c: Dictionary, combatant_id: int, all_actions: Array) -> bool:
    return _ListedActions.long_close_only_offense_menu(manager, c, combatant_id, all_actions)


## Short-horizon parry-deflect recency pressure for feint listing.
static func _feint_listing_opp_parry_deflect_pressure_mult(
    manager: Node, attacker: Dictionary, defender_id: int
) -> float:
    if manager == null or attacker.is_empty() or defender_id < 0:
        return 1.0
    var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
    if raw_m == null or not (raw_m is Dictionary):
        return 1.0
    var st: Variant = (raw_m as Dictionary).get(str(defender_id), null)
    if st == null:
        return 1.0
    var stored_tick: int = int(st)
    var tick_now: int = manager.get_combat_tick_index()
    var age: int = tick_now - stored_tick
    if age < 0:
        return 1.0
    var win: int = maxi(1, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS)
    var t: float = 1.0 - clampf(float(age) / win, 0.0, 1.0)
    return lerpf(1.0, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT, t)
