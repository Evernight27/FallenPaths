class_name CombatAIActionPicker
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
## (**`ACTION_KEY_COUNTER_TEMPO`**) ->'' -  **`CounterTempo.counter_tempo_listing_weight_mult`**
## (**`AI_COUNTER_TEMPO_*`**). **`is_feint`** moves get **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** ->''
## -  defender-readiness lerp (**`PassiveParryContext.get_passive_parry_readiness`** ->'' -
## **`CombatConstants.passive_parry_readiness_incoming_contact_mult`** for this move'"--"''s **`contact_type`** ->'' -
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** on the defender ->'' -
## **`CombatConstants.ai_feint_listing_defender_readiness_spacing_mult`** from defender **`distance_to[attacker]`** '""
## same curve as **`DefenseChoiceResolver`** reported readiness, not attacker stamina) ->'' -  attacker
## **`CombatWeaponForm.mod(form_str, "ai_feint_listing")`** ->'' -  defender footwork state mult
## (**`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** when off-balance; elif **`STATE_RECOVERING`**,
## **`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**; elif settled **`STATE_WAITING`**,
## **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**) ->'' -  optional low-stamina feint dampening ->'' -  formation
## doctrine **`probing`** / **`pinch_center`** / **`hold_lane`** (**`AI_FEINT_LISTING_DOCTRINE_*_MULT`**) ->'' -
## short-horizon boost after that defender **`parry_deflect`**
## (**`COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`**, **`AI_FEINT_LISTING_OPP_PARRY_DEFLECT_*`**) (Tier 4.2).
## Feint **listing** applies **`DefenseChoiceResolver._feint_readiness_reveal_mult`** when the attacker has live
## **`pending_attack`** on the listed target (same move / wind-up progress as **`choose_defense`**).
## Manager must have: _get_by_id, get_health_entity (via CombatantEntityAccess), _is_medical_move.


static func pick(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
    if actions.is_empty():
        return {}
    var c_pick: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    actions = CombatMobilityRetreat.filter_actions_for_retreat_only(actions, c_pick)
    if actions.is_empty():
        return {}
    var stacked: Dictionary = MentalStackDecider.try_pick(actions, combatant_id, manager)
    if not stacked.is_empty():
        var choice_stacked: Dictionary = stacked.duplicate()
        CombatAIAttackTargetPart._add_attack_target_part(choice_stacked, manager, combatant_id)
        return choice_stacked
    CombatWeaponForm.evaluate_automatic_form(manager, c_pick)
    return pick_weighted(actions, combatant_id, manager)


## Weighted random choice without **`MentalStackDecider`** (used by stack layers to avoid recursion).
## **`weight_menu_context`**: full turn menu for `_get_action_weight` when picking from a narrowed pool (MS-L5 plug).


## Weighted random choice without **`MentalStackDecider`** (used by stack layers to avoid recursion).
## **`weight_menu_context`**: full turn menu for `_get_action_weight` when picking from a narrowed pool (MS-L5 plug).
static func pick_weighted(
    actions: Array, combatant_id: int, manager: Node, weight_menu_context: Array = []
) -> Dictionary:
    if actions.is_empty():
        return {}
    var c_pick: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    actions = CombatMobilityRetreat.filter_actions_for_retreat_only(actions, c_pick)
    if actions.is_empty():
        return {}
    CombatTargetScoring.prune_expired_commitments(manager)
    var ctx_actor: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, c_pick)
    var zone_by_id: Dictionary = ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
    var weight_ctx: Array = weight_menu_context if not weight_menu_context.is_empty() else actions
    var total: float = 0.0
    for a in actions:
        total += CombatAIActionWeights._get_action_weight(
            a, combatant_id, manager, true, ctx_actor, zone_by_id, weight_ctx
        )
    var r: float = randf() * total
    for a in actions:
        var w: float = CombatAIActionWeights._get_action_weight(
            a, combatant_id, manager, true, ctx_actor, zone_by_id, weight_ctx
        )
        if r < w:
            var choice: Dictionary = a.duplicate()
            CombatAIAttackTargetPart._add_attack_target_part(choice, manager, combatant_id)
            return choice
        r -= w
    var fallback: Dictionary = actions[0].duplicate()
    CombatAIAttackTargetPart._add_attack_target_part(fallback, manager, combatant_id)
    return fallback


## Deterministic medical pick for campaign batch exit (highest triage weight, no RNG).


## Deterministic medical pick for campaign batch exit (highest triage weight, no RNG).
static func pick_highest_medical(actions: Array, combatant_id: int, manager: Node) -> Dictionary:
    if actions.is_empty():
        return {}
    var best: Dictionary = {}
    var best_w: float = -1.0
    for a in actions:
        if a is not Dictionary:
            continue
        var w: float = CombatAIActionWeights._get_medical_weight(a as Dictionary, combatant_id, manager)
        if w > best_w:
            best_w = w
            best = a.duplicate()
    return best


## Build opts dict from AI choice (target_part, feint_part) for resolve_action. Shared by all pick-and-resolve callers.


## Build opts dict from AI choice (target_part, feint_part) for resolve_action. Shared by all pick-and-resolve callers.
static func opts_from_choice(choice: Dictionary) -> Dictionary:
    var opts: Dictionary = {}
    if choice.get("target_part", "") != "":
        opts["target_part"] = choice.target_part
    if choice.get("feint_part", "") != "":
        opts["feint_part"] = choice.feint_part
    if choice.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false):
        opts[CombatConstants.ACTION_KEY_COUNTER_TEMPO] = true
    return opts


## Apply a picked move via **`CombatManager.resolve_action`** (shared by player/enemy turn paths).


## Apply a picked move via **`CombatManager.resolve_action`** (shared by player/enemy turn paths).
static func resolve_choice(manager: Node, combatant_id: int, choice: Dictionary, self_target: bool = false) -> bool:
    var opts: Dictionary = opts_from_choice(choice)
    var target_id: int = combatant_id if self_target else int(choice.get("target_id", combatant_id))
    var move_id: String = choice.get("move_id", "")
    var committed: bool = manager.resolve_action(combatant_id, target_id, move_id, opts)
    if not committed:
        CombatAIActionWeights._verify_turn_committed_after_resolve(manager, combatant_id, move_id)
    return committed


## Pick from **`actions`** then resolve; optional **`CombatDebug.flow_log_turn`** when **`log_side`** set.
static func resolve_picked_turn(
    manager: Node, combatant_id: int, actions: Array, log_side: String = "", self_target: bool = false
) -> void:
    if actions.is_empty():
        return
    var choice: Dictionary = pick(actions, combatant_id, manager)
    CombatEngagementDiagnostics.maybe_log_turn_pick(manager, combatant_id, actions, choice)
    var committed: bool = resolve_choice(manager, combatant_id, choice, self_target)
    if not committed and manager != null and manager.medical_phase:
        CombatantEntityAccess.manager_skip_turn(
            manager, combatant_id, "pass", "medical coordination blocked stale pick"
        )
    elif not committed:
        CombatAIActionWeights._verify_turn_committed_after_resolve(manager, combatant_id, choice.get("move_id", ""))
    if not log_side.is_empty() and committed:
        CombatDebug.flow_log_turn(log_side, combatant_id, actions, choice, manager)


## **`skip_turn`** when no actions; else **`resolve_picked_turn`** (player/enemy **`ACTION_READY`** paths).


## **`skip_turn`** when no actions; else **`resolve_picked_turn`** (player/enemy **`ACTION_READY`** paths).
static func resolve_picked_turn_or_skip(
    manager: Node, combatant_id: int, actions: Array, log_side: String = "", self_target: bool = false
) -> void:
    if manager != null and manager.medical_phase:
        actions = manager.get_available_actions(combatant_id)
        actions = CombatMedicalCoordination.filter_actions_for_pick(manager, combatant_id, actions)
    if actions.is_empty():
        CombatantEntityAccess.manager_skip_turn(
            manager, combatant_id, CombatConstants.SKIP_TURN_LOG_PASS, "no available actions"
        )
        return
    resolve_picked_turn(manager, combatant_id, actions, log_side, self_target)


## Shared swap-rank fitness gate: `disengage` = front yields to fitter rear; relief = rear replaces exhausted front.


## True when front->''--''''' 'back disengage swap is tactically justified (matches high-weight rules in
## _get_action_weight).
## Plug-forward (incapacitated partner) is handled separately in `CombatFormationMoveListing`.
## `manager`: required for body-damage / peril gate (fatigue alone must not justify retreat).
static func is_disengage_swap_tactically_allowed(c: Dictionary, partner: Dictionary, manager: Node) -> bool:
    return CombatAIActionWeights._swap_rank_fitness_swap_allowed(c, partner, manager, true)


## True when deeper rank (higher rank #) should swap forward with the rank ahead (relief / rotation).


## True when deeper rank (higher rank #) should swap forward with the rank ahead (relief / rotation).
static func is_relief_swap_tactically_allowed(c: Dictionary, partner: Dictionary) -> bool:
    return CombatAIActionWeights._swap_rank_fitness_swap_allowed(c, partner, null, false)


## Returns weight for action. Medical: urgency + direct pressure bleed + pending retry.
## Combat: attack/attempt_close = use stamina (exhausted less likely to engage); `attempt_close` weight 0 unless listed
## pair (`attempt_close_listed_for_pair`); swap_rank = fitness only (no stamina).
## `skip_targeting_prune`: pass **true** when `pick()` already called `prune_expired_commitments` (avoids O(actions)
## redundant prunes).


## Tier 4.2: after **`AttackResultApplier`** **`parry_deflect`**, record defender tick on **`attacker`** for
## short-horizon feint listing pressure.
static func record_opp_parry_deflect_for_feint_listing(manager: Node, attacker: Dictionary, defender_id: int) -> void:
    if manager == null or attacker.is_empty() or defender_id < 0:
        return
    var tick_now: int = manager.get_combat_tick_index()
    var mem: Dictionary = {}
    var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
    if raw_m is Dictionary:
        mem = raw_m.duplicate()
    mem[str(defender_id)] = tick_now
    attacker[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = mem


## Tier 4.2: clear short-horizon parry-deflect memory for this defender (e.g. after a **`hit`** landed).


## Tier 4.2: clear short-horizon parry-deflect memory for this defender (e.g. after a **`hit`** landed).
static func clear_feint_listing_opp_parry_deflect_for_target(attacker: Dictionary, defender_id: int) -> void:
    if attacker.is_empty() or defender_id < 0:
        return
    var raw_m: Variant = attacker.get(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK, null)
    if raw_m == null or not (raw_m is Dictionary):
        return
    var mem: Dictionary = (raw_m as Dictionary).duplicate()
    mem.erase(str(defender_id))
    if mem.is_empty():
        attacker.erase(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK)
    else:
        attacker[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = mem
