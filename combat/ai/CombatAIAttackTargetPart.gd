class_name CombatAIAttackTargetPart
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


static func _add_attack_target_part(choice: Dictionary, manager: Node, attacker_id: int) -> void:
    if CombatConstants.is_medical_move(choice.get("move_id", "")):
        return
    if choice.get("move_id", "") == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
        return  # Close attempt targets a combatant, not a body part
    if (
        choice.get("move_id", "")
        in [
            CombatConstants.MOVE_ID_SWAP_RANK,
            CombatConstants.MOVE_ID_DRAG_BACK,
            CombatConstants.MOVE_ID_FALL_BACK,
            CombatConstants.MOVE_ID_ROTATE_FILE,
        ]
    ):
        return
    if choice.get("move_id", "") == CombatConstants.MOVE_ID_WAIT:
        return
    if choice.get("move_id", "") == CombatConstants.MOVE_ID_FLEE:
        return
    var tgt_id: int = choice.get("target_id", -1)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tgt_id)
    if tgt.is_empty():
        return
    var targetable: Array = CombatantEntityAccess.get_targetable_parts(tgt)
    if targetable.is_empty():
        return
    var atk_pick: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if not atk_pick.is_empty():
        targetable = CombatDepthPolearm.depth_polearm_targetable_parts_filter(manager, atk_pick, targetable)
    var move_id_pick: String = choice.get("move_id", "")
    var depth_allows_low: bool = (
        CombatDepthPolearm.depth_polearm_lane_allows_low_targets(manager, atk_pick) if not atk_pick.is_empty() else true
    )
    if targetable.is_empty():
        return
    var move_def: Dictionary = WeaponConstants.get_move(move_id_pick)
    var atk_line: String = move_def.get("attack_line", "high")
    var guard_line: String = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT)
    var atk_angle_list: float = CombatConstants.line_to_angle(atk_line)
    if atk_pick != null and not atk_pick.is_empty():
        atk_angle_list = CombatFootwork.attack_angle_deg_for_listing_preview(
            atk_pick, atk_line, atk_angle_list, tgt_id, manager
        )
    var guard_angle_list: float = (
        CombatFootwork.guard_angle_deg(tgt, {})
        if CombatFootwork.enabled()
        else CombatConstants.get_guard_angle_deg(tgt)
    )
    var align_ctx: Dictionary = {
        "attack_angle_deg": atk_angle_list,
        "guard_angle_deg": guard_angle_list,
    }
    var alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
    choice["target_part"] = AttackPathResolver.pick_ai_target_part(
        atk_line,
        guard_line,
        targetable,
        alignment,
        move_def,
        atk_pick,
        tgt,
        attacker_id,
        align_ctx,
        move_id_pick,
        depth_allows_low
    )
    if choice.get("target_part", "").is_empty():
        return
    if move_def.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false):
        var feint_part: String = AttackPathResolver.pick_feint_part_for_attack(
            choice["target_part"], targetable, tgt, attacker_id
        )
        if not feint_part.is_empty():
            choice["feint_part"] = feint_part
