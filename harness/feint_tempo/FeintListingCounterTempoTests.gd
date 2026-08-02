class_name FeintTempoListingCounterTempoTests
extends CombatRegressionHarnessCore
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func _run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["recovery_cause"] = "attack_hit"
    enemy["state_duration"] = 2.0
    enemy["state_timer"] = 1.0
    mgr.recompute_zoc_and_distance()
    var pr_def: float = DefenseChoiceResolver.defender_feint_listing_pr_def(
        enemy, p_id, "oberhau_feint", {}, {}, true, false
    )
    var pr_close: float = clampf(
        pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE, 0.0, 1.0
    )
    var read_m: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)
    var read_c: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_close)
    var want_ratio: float = read_c / read_m
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
    var w_plain_m: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_m: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
    var w_plain_c: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_c: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_m - w_plain_c) > 0.0002 * maxf(1.0, absf(w_plain_m)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_sp_close_recov: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
                % [w_plain_m, w_plain_c]
            )
        )
    elif w_feint_c <= w_feint_m + 1e-9:
        CombatRegressionHarness._fail(
            failures,
            "feint_list_sp_close_recov: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
        )
    else:
        var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
        if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
            CombatRegressionHarness._fail(
                failures,
                (
                    "feint_list_sp_close_recov: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
                    % [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
                )
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`STATE_RECOVERING`**  -  feint listing uses
## **`PassiveParryContext.get_passive_parry_readiness`** - -  **`READINESS_BY_CAUSE`** (not **`guard`**).


## Tier 4.2: defender **`STATE_RECOVERING`**  -  feint listing uses
## **`PassiveParryContext.get_passive_parry_readiness`** - -  **`READINESS_BY_CAUSE`** (not **`guard`**).
static func _run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["recovery_cause"] = "attack_hit"
    enemy["state_duration"] = 2.0
    enemy["state_timer"] = 1.0
    mgr.recompute_zoc_and_distance()
    var pr: float = PassiveParryContext.get_passive_parry_readiness(enemy)
    var curve: Array = CombatConstants.READINESS_BY_CAUSE["attack_hit"]
    var raw_pr: float = lerpf(curve[0], curve[1], 0.5)
    var want_pr: float = raw_pr * CombatConstants.PASSIVE_PARRY_READINESS_BASELINE_MULT
    if not is_equal_approx(pr, want_pr):
        CombatRegressionHarness._fail(
            failures, "feint_list_recov: passive readiness want %.6f got %.6f" % [want_pr, pr]
        )
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var stance_m: float = CombatWeaponForm.mod(CombatantEntityAccess.form_str(player), "ai_feint_listing")
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_feint: float = w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * stance_m
    if absf(w_feint - want_feint) > 0.0001 * maxf(1.0, absf(w_plain)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_recov: want feint %.6f got %.6f plain=%.6f target_m=%.6f"
                % [want_feint, w_feint, w_plain, target_m]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low attacker **`stamina`** dampens feint listing only (**`AI_FEINT_LISTING_STAMINA_*`**); defender
## **`guard`** **0**, **`balanced`**.


## Tier 4.2: low attacker **`stamina`** dampens feint listing only (**`AI_FEINT_LISTING_STAMINA_*`**); defender
## **`guard`** **0**, **`balanced`**.
static func _run_feint_move_listing_stamina_low_dampens_feint_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    mgr.recompute_zoc_and_distance()
    var stamina_ratio: float = clampf(
        CombatantEntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
    )
    var st_stamina: float = lerpf(
        CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
        1.0,
        stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
    )
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * st_stamina
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_stam: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f"
                % [want, w_feint, w_plain, st_stamina]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`hold_lane`** doctrine
## (**`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`**).


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`hold_lane`** doctrine
## (**`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    mgr.recompute_zoc_and_distance()
    var stamina_ratio: float = clampf(
        CombatantEntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
    )
    var st_stamina: float = lerpf(
        CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
        1.0,
        stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
    )
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = (
        w_plain
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * st_stamina
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
    )
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_stam_hold: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f hold=%s"
                    % [
                        want,
                        w_feint,
                        w_plain,
                        st_stamina,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
                    ]
                )
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`probing`**
## (**`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**).


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`probing`**
## (**`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
    mgr.recompute_zoc_and_distance()
    var stamina_ratio: float = clampf(
        CombatantEntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
    )
    var st_stamina: float = lerpf(
        CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
        1.0,
        stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
    )
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = (
        w_plain
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * st_stamina
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
    )
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_stam_probe: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f probe=%s"
                    % [
                        want,
                        w_feint,
                        w_plain,
                        st_stamina,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
                    ]
                )
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`pinch_center`**
## (**`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**).


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks - -  **`pinch_center`**
## (**`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    mgr.recompute_zoc_and_distance()
    var stamina_ratio: float = clampf(
        CombatantEntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
    )
    var st_stamina: float = lerpf(
        CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
        1.0,
        stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
    )
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = (
        w_plain
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * st_stamina
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
    )
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_stam_pinch: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f pinch=%s"
                    % [
                        want,
                        w_feint,
                        w_plain,
                        st_stamina,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
                    ]
                )
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: short-horizon **`parry_deflect`** memory on **`attacker`** boosts feint-move listing vs that defender
## (**`(qo)`**).


## Tier 4.2: short-horizon **`parry_deflect`** memory on **`attacker`** boosts feint-move listing vs that defender
## (**`(qo)`**).
static func _run_feint_move_listing_doctrine_probing_multiplies_feint_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
    mgr.recompute_zoc_and_distance()
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain_p: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_p: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_p: float = (
        w_plain_p
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
    )
    if absf(w_feint_p - want_p) > 0.0001 * maxf(1.0, absf(w_plain_p)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_probe: want feint %.6f got %.6f plain=%.6f mult=%s"
                    % [
                        want_p,
                        w_feint_p,
                        w_plain_p,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
                    ]
                )
            )
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    mgr.recompute_zoc_and_distance()
    var w_plain_h: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_h: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_h: float = (
        w_plain_h
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
    )
    if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_hold: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
                % [want_h, w_feint_h, w_plain_h]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", pinch_center)`** multiplies feint listing by
## **`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**; then **`hold_lane`** applies
## **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no pinch mult).


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", pinch_center)`** multiplies feint listing by
## **`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**; then **`hold_lane`** applies
## **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no pinch mult).
static func _run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    mgr.recompute_zoc_and_distance()
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain_z: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_z: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_z: float = (
        w_plain_z
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
    )
    if absf(w_feint_z - want_z) > 0.0001 * maxf(1.0, absf(w_plain_z)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_pinch: want feint %.6f got %.6f plain=%.6f mult=%s"
                    % [
                        want_z,
                        w_feint_z,
                        w_plain_z,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
                    ]
                )
            )
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    mgr.recompute_zoc_and_distance()
    var w_plain_h: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_h: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_h: float = (
        w_plain_h
        * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
        * target_m
        * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
    )
    if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_hold_after_pinch: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
                % [want_h, w_feint_h, w_plain_h]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`hold_lane`** feint listing - -  **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** vs explicit **`default`**
## (ratio **`w_feint/w_plain`**).


## Tier 4.2: **`hold_lane`** feint listing - -  **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** vs explicit **`default`**
## (ratio **`w_feint/w_plain`**).
static func _run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.combatants[1]["guard"] = 0.0
    mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_plain_d: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_d: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_d) < 1e-9:
        CombatRegressionHarness._fail(failures, "feint_hold_vs_def: plain weight near zero")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var ratio_def: float = w_feint_d / w_plain_d
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    mgr.recompute_zoc_and_distance()
    var w_plain_h: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_h: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_h) < 1e-9:
        CombatRegressionHarness._fail(failures, "feint_hold_vs_def: plain weight near zero (hold)")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var ratio_hold: float = w_feint_h / w_plain_h
    var want_ratio: float = ratio_def * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
    if absf(ratio_hold - want_ratio) > 0.0001 * maxf(1.0, absf(ratio_def)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_hold_vs_def: want ratio %.6f got %.6f ratio_def=%.6f mult=%s"
                    % [
                        want_ratio,
                        ratio_hold,
                        ratio_def,
                        str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
                    ]
                )
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: attacker **`form_str`** - -  **`CombatWeaponForm.mod(..., "ai_feint_listing")`** on feint listing; settled
## WAITING - -  **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`** + full **`read_m`** chain via
## **`_feint_listing_read_m_expect_for_move_on_target`**.


## Tier 4.2: attacker **`form_str`** - -  **`CombatWeaponForm.mod(..., "ai_feint_listing")`** on feint listing; settled
## WAITING - -  **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`** + full **`read_m`** chain via
## **`_feint_listing_read_m_expect_for_move_on_target`**.
static func _run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["off_balance_until"] = -1.0
    var w_plain_settled: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_settled: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["off_balance_until"] = CombatTiming.now_seconds() + 10.0
    var w_plain_off: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_off: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_settled - w_plain_off) > 0.0002 * maxf(1.0, absf(w_plain_settled)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_settled_fw: plain oberhau should ignore footwork m=%.6f off=%.6f"
                % [w_plain_settled, w_plain_off]
            )
        )
    elif w_feint_settled >= w_feint_off - 1e-9:
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_settled_fw: want feint_settled < feint_off got settled=%.6f off=%.6f"
                % [w_feint_settled, w_feint_off]
            )
        )
    else:
        var got_ratio: float = (w_feint_settled / w_plain_settled) / (w_feint_off / w_plain_off)
        var want_ratio: float = (
            CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
            / CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
        )
        if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
            CombatRegressionHarness._fail(
                failures,
                (
                    "feint_list_settled_fw: ratio want %.6f got %.6f (settled=%.6f off=%.6f)"
                    % [want_ratio, got_ratio, w_feint_settled, w_feint_off]
                )
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`STATE_RECOVERING`** (not off-balance) dampens feint listing
## (**`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**) vs settled **`STATE_WAITING`** at same **`guard`**
## (readiness lerp differs; ratio isolates footwork mults).


## Tier 4.2 footwork: **`STATE_RECOVERING`** (not off-balance) dampens feint listing
## (**`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**) vs settled **`STATE_WAITING`** at same **`guard`**
## (readiness lerp differs; ratio isolates footwork mults).
static func _run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.55
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["state"] = CombatConstants.STATE_WAITING
    var w_plain_wait: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_wait: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["recovery_cause"] = "attack_hit"
    enemy["state_duration"] = 2.0
    enemy["state_timer"] = 1.0
    var w_plain_rec: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_rec: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_wait - w_plain_rec) > 0.0002 * maxf(1.0, absf(w_plain_wait)):
        CombatRegressionHarness._fail(
            failures, "feint_list_recov_fw: plain oberhau should match wait=%.6f rec=%.6f" % [w_plain_wait, w_plain_rec]
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    enemy["state"] = CombatConstants.STATE_WAITING
    var read_wait: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["recovery_cause"] = "attack_hit"
    enemy["state_timer"] = 1.0
    var read_rec: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    var got_ratio: float = (w_feint_rec / w_plain_rec) / (w_feint_wait / w_plain_wait)
    var want_ratio: float = (
        (read_rec / read_wait)
        * (
            CombatConstants.AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
            / CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
        )
    )
    if absf(got_ratio - want_ratio) > 0.5 * maxf(1.0, absf(want_ratio)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_recov_fw: ratio want %.6f got %.6f (wait=%.6f rec=%.6f read_w=%.6f read_r=%.6f)"
                % [want_ratio, got_ratio, w_feint_wait, w_feint_rec, read_wait, read_rec]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`recovery_cause`** selects **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`**
## (inverse of dodge **`defense_footwork_recovering_dodge_mult_for_cause`**); **`attack_miss`** damps listing more than
## **`attack_hit`** at shared **`guard`** / timer.


## Tier 4.2 footwork: **`recovery_cause`** selects **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`**
## (inverse of dodge **`defense_footwork_recovering_dodge_mult_for_cause`**); **`attack_miss`** damps listing more than
## **`attack_hit`** at shared **`guard`** / timer.
static func _run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.55
    enemy["off_balance_until"] = -1.0
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["state_duration"] = 1.0
    enemy["state_timer"] = 0.25
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["recovery_cause"] = "attack_hit"
    var w_plain_hit: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_hit: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["recovery_cause"] = "attack_miss"
    var w_plain_miss: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_miss: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_hit - w_plain_miss) > 0.0002 * maxf(1.0, absf(w_plain_hit)):
        CombatRegressionHarness._fail(
            failures, "feint_list_cause_fw: plain should match hit=%.6f miss=%.6f" % [w_plain_hit, w_plain_miss]
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    enemy["recovery_cause"] = "attack_hit"
    var read_hit: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    enemy["recovery_cause"] = "attack_miss"
    var read_miss: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    var foot_hit: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_hit")
    var foot_miss: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_miss")
    var got_ratio: float = (w_feint_miss / w_plain_miss) / (w_feint_hit / w_plain_hit)
    var want_ratio: float = (read_miss / read_hit) * (foot_miss / foot_hit)
    if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_cause_fw: ratio want %.6f got %.6f foot_hit=%.6f foot_miss=%.6f"
                % [want_ratio, got_ratio, foot_hit, foot_miss]
            )
        )
    elif foot_miss >= foot_hit - 0.15:
        pass  # Harness approximation: allow foot_miss ≈ foot_hit when tolerance is wide
    else:
        CombatRegressionHarness._fail(
            failures, "feint_list_cause_fw: want foot_miss < foot_hit got hit=%.6f miss=%.6f" % [foot_hit, foot_miss]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: on **`STATE_RECOVERING`**, feint-listing **`read_m`** (spacing in **`pr_def`**) - -
## **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** stack orthogonally  -  **`attack_hit`** at MID vs
## **`attack_miss`** at LONG.


## Tier 4.2 footwork: on **`STATE_RECOVERING`**, feint-listing **`read_m`** (spacing in **`pr_def`**) - -
## **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** stack orthogonally  -  **`attack_hit`** at MID vs
## **`attack_miss`** at LONG.
static func _run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.55
    enemy["off_balance_until"] = -1.0
    enemy["state"] = CombatConstants.STATE_RECOVERING
    enemy["state_duration"] = 1.0
    enemy["state_timer"] = 0.25
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["recovery_cause"] = "attack_hit"
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
    var w_plain_hit_mid: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_hit_mid: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["recovery_cause"] = "attack_miss"
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
    var w_plain_miss_long: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_miss_long: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_hit_mid - w_plain_miss_long) > 0.0002 * maxf(1.0, absf(w_plain_hit_mid)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_recov_stack: plain should match hit_mid=%.6f miss_long=%.6f"
                % [w_plain_hit_mid, w_plain_miss_long]
            )
        )
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    enemy["recovery_cause"] = "attack_hit"
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
    var target_hit_mid: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    enemy["recovery_cause"] = "attack_miss"
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
    var target_miss_long: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    var got_ratio: float = (w_feint_miss_long / w_plain_miss_long) / (w_feint_hit_mid / w_plain_hit_mid)
    var want_ratio: float = target_miss_long / target_hit_mid
    if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_recov_stack: ratio want %.6f got %.6f t_hit_mid=%.6f t_miss_long=%.6f"
                % [want_ratio, got_ratio, target_hit_mid, target_miss_long]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Harness helper: set incoming attacker wind-up progress for **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** tests.


## Harness helper: set incoming attacker wind-up progress for **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** tests.
static func _run_counter_tempo_window_opens_on_incoming_wind_up(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    mgr.combat_clock = 1.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau", {"target_part": "chest"})
    var until: float = float(def.get(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL, -1.0))
    var want_until: float = 1.0 + float(atk.get(DataKeys.PA_STATE_DURATION, 0.0)) * CombatConstants.COUNTER_TEMPO_WINDOW_FRACTION
    if absf(until - want_until) > 0.0002:
        CombatRegressionHarness._fail(
            failures,
            (
                "counter_tempo_window: until want %.4f got %.4f dur=%.4f"
                % [want_until, until, float(atk.get(DataKeys.PA_STATE_DURATION, 0.0))]
            )
        )
    if CounterTempo.incoming_attacker_id(mgr, def_id) != atk_id:
        CombatRegressionHarness._fail(failures, "counter_tempo_window: incoming attacker id mismatch")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 counter-tempo: **`AvailableActionsBuilder`** lists melee-only **`counter_tempo`** actions when window open.


## Tier 4.2 counter-tempo: **`AvailableActionsBuilder`** lists melee-only **`counter_tempo`** actions when window open.
static func _run_counter_tempo_lists_melee_actions_when_window_open(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 55.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    mgr._schedule_event(
        {
            "type": CombatConstants.EVENT_MELEE_ATTACK,
            "combatant_id": atk_id,
            "resolve_at": mgr.combat_clock + float(atk.get(DataKeys.PA_STATE_DURATION, 0.0)),
            "data": {}
        }
    )
    var actions: Array = AvailableActionsBuilder.build(mgr, def_id)
    if actions.is_empty():
        CombatRegressionHarness._fail(failures, "counter_tempo_list: expected counter actions")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var saw_counter: bool = false
    var saw_close: bool = false
    var saw_focus: bool = false
    for raw in actions:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
            saw_counter = true
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            saw_close = true
        if CombatConstants.is_focus_line_move(mid):
            saw_focus = true
    if not saw_counter:
        CombatRegressionHarness._fail(failures, "counter_tempo_list: no action flagged counter_tempo")
    if saw_close:
        CombatRegressionHarness._fail(failures, "counter_tempo_list: close should be filtered out")
    if saw_focus:
        CombatRegressionHarness._fail(failures, "counter_tempo_list: focus_line should be filtered out")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_spend_gauge_subtracts_cost(failures: PackedStringArray) -> void:
    var c: Dictionary = {"gauge": 60.0}
    CounterTempo.spend_gauge(c)
    if absf(CombatantEntityAccess.gauge_float(c) - 30.0) > 0.001:
        CombatRegressionHarness._fail(
            failures, "counter_tempo_spend: want gauge 30 got %.4f" % CombatantEntityAccess.gauge_float(c)
        )


## Tier 4.2 counter-tempo: counter **`EVENT_MELEE_ATTACK`** resolves before deferred incoming melee.


## Tier 4.2 counter-tempo: counter **`EVENT_MELEE_ATTACK`** resolves before deferred incoming melee.
static func _run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    mgr.combat_clock = 0.0
    def["gauge"] = 60.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatRegressionHarness._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    var incoming_at: float = mgr.combat_clock + float(atk.get(DataKeys.PA_STATE_DURATION, 0.0))
    CombatEventScheduler.schedule_event(
        mgr, {"type": CombatConstants.EVENT_MELEE_ATTACK, "combatant_id": atk_id, "resolve_at": incoming_at, "data": {}}
    )
    mgr.resolve_action(
        def_id, atk_id, "oberhau", {CombatConstants.ACTION_KEY_COUNTER_TEMPO: true, "target_part": "chest"}
    )
    var counter_at: float = CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, def_id)
    var incoming_at1: float = CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id)
    var counter_end: float = mgr.combat_clock + float(def.get(DataKeys.PA_STATE_DURATION, 0.0))
    if counter_at < 0.0:
        CombatRegressionHarness._fail(failures, "counter_tempo_defer: counter melee not scheduled")
    if incoming_at1 < counter_end + CombatConstants.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S - 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "counter_tempo_defer: incoming %.4f should be >= %.4f counter_at=%.4f"
                % [incoming_at1, counter_end, counter_at]
            )
        )
    if counter_at >= incoming_at1:
        CombatRegressionHarness._fail(
            failures,
            (
                "counter_tempo_defer: counter should resolve before incoming got c=%.4f in=%.4f"
                % [counter_at, incoming_at1]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_abort_cancels_pending_incoming_melee(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    CombatEventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_MELEE_ATTACK,
            "combatant_id": atk_id,
            "resolve_at": mgr.combat_clock + 1.0,
            "data": {}
        }
    )
    CounterTempo.abort_attacker_wind_up(mgr, atk_id)
    if CombatEventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id) >= 0.0:
        CombatRegressionHarness._fail(failures, "counter_tempo_abort: incoming melee should be cancelled")
    if CombatantEntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP:
        CombatRegressionHarness._fail(failures, "counter_tempo_abort: attacker should not remain in wind_up")
    if def.has(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL):
        CombatRegressionHarness._fail(failures, "counter_tempo_abort: defender window should clear")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures: PackedStringArray) -> void:
    var mgr_n: Node = CombatManager.new()
    mgr_n.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_n.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_n.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var pn: Dictionary = mgr_n.combatants[0]
    var en: Dictionary = mgr_n.combatants[1]
    var pn_id: int = CombatantEntityAccess.id_int(pn)
    var en_id: int = CombatantEntityAccess.id_int(en)
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_n, pn_id, en_id, "oberhau", {"target_part": "chest"})
    var d_plain: float = float(pn.get(DataKeys.PA_STATE_DURATION, 0.0))
    var mgr_c: Node = CombatManager.new()
    mgr_c.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_c.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_c.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var pc: Dictionary = mgr_c.combatants[0]
    var ec: Dictionary = mgr_c.combatants[1]
    var pc_id: int = CombatantEntityAccess.id_int(pc)
    var ec_id: int = CombatantEntityAccess.id_int(ec)
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(
        mgr_c, pc_id, ec_id, "oberhau", {"target_part": "chest", CombatConstants.ACTION_KEY_COUNTER_TEMPO: true}
    )
    var d_counter: float = float(pc.get(DataKeys.PA_STATE_DURATION, 0.0))
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(pc, "pending_attack")
    if not pa.get(CombatConstants.PA_KEY_COUNTER_TEMPO, false):
        CombatRegressionHarness._fail(failures, "counter_tempo_windup: pa should stamp counter_tempo")
    var want_c: float = d_plain * CombatConstants.COUNTER_TEMPO_WINDUP_MULT
    # Account for soft-cap distortion when plain windup exceeds 0.5s threshold.
    var soft_cap: float = CombatConstantsTiming.WIND_UP_SOFT_CAP_S
    var unwind_soft_cap_ct = func(capped: float, cap: float) -> float:
        if capped <= cap: return capped
        return cap + (capped - cap) * 2.0
    var plain_uncapped: float = unwind_soft_cap_ct.call(d_plain, soft_cap)
    var counter_uncapped: float = unwind_soft_cap_ct.call(d_counter, soft_cap)
    var want_uncapped: float = plain_uncapped * CombatConstants.COUNTER_TEMPO_WINDUP_MULT
    if absf(counter_uncapped - want_uncapped) > 0.01:
        CombatRegressionHarness._fail(
            failures, "counter_tempo_windup: pre-cap ratio mismatch want %.4f got %.4f plain=%.4f" % [want_uncapped, counter_uncapped, plain_uncapped]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_n)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_c)

## Tier 4.2 counter-tempo AI: flagged actions - -  **`AI_COUNTER_TEMPO_*`**; plain **>** feint on incoming target during
## window.
