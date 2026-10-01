class_name FeintTempoCounterTempoGuardZoneTests
extends CombatRegressionHarnessCore

const CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func _run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    def["gauge"] = 60.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    var a_plain: Dictionary = {
        "move_id": "oberhau",
        "target_id": atk_id,
        CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
    }
    var a_feint: Dictionary = {
        "move_id": "oberhau_feint",
        "target_id": atk_id,
        CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
    }
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, def_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, def_id, mgr, true)
    var base_mult: float = (
        CombatConstants.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT * CombatConstants.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
    )
    if w_plain < w_feint:
        _fail(failures, "counter_tempo_ai: plain should beat feint got plain=%.6f feint=%.6f" % [w_plain, w_feint])
    var a_no_flag: Dictionary = {"move_id": "oberhau", "target_id": atk_id}
    var w_no_flag: float = CombatAIActionPicker._get_action_weight(a_no_flag, def_id, mgr, true)
    if w_plain <= w_no_flag * base_mult * 0.99:
        _fail(
            failures,
            (
                "counter_tempo_ai: counter flag should boost vs plain listing got counter=%.6f no_flag=%.6f want>%f"
                % [w_plain, w_no_flag, w_no_flag * base_mult * 0.99]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 Approach B: **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** blocks **`can_act`** until incoming wind-up is
## far enough along.


## Tier 4.2 Approach B: **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** blocks **`can_act`** until incoming wind-up is
## far enough along.
static func _run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 60.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    if CounterTempo.can_act(mgr, def):
        _fail(failures, "counter_tempo_gate: can_act should be false at 20% wind-up")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.49)
    if CounterTempo.can_act(mgr, def):
        _fail(failures, "counter_tempo_gate: can_act should be false at 49% wind-up")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.51)
    if not CounterTempo.can_act(mgr, def):
        _fail(failures, "counter_tempo_gate: can_act should be true at 51% wind-up")
    if AvailableActionsBuilder.build(mgr, def_id).is_empty():
        _fail(failures, "counter_tempo_gate: build should list counter actions at 51%")
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CounterTempo.process_waiting`** schedules ready once progress gate opens (not at wind-up start).


## Tier 4.2: **`CounterTempo.process_waiting`** schedules ready once progress gate opens (not at wind-up start).
static func _run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(
    failures: PackedStringArray
) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 60.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.1)
    if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
        _fail(failures, "counter_tempo_wait: should not signal ready at 10% wind-up")
    CounterTempo.process_waiting(mgr, def)
    if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
        _fail(failures, "counter_tempo_wait: process_waiting should not signal at 10%")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
    CounterTempo.process_waiting(mgr, def)
    if not bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
        _fail(failures, "counter_tempo_wait: should signal ready after 55% wind-up")
    HarnessFixtures._free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_ui_hint_winding_then_ready(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var atk: Dictionary = mgr.combatants[0]
    var def: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var def_id: int = CombatantEntityAccess.id_int(def)
    def["gauge"] = 60.0
    AttackWindUpStarter.start(mgr, atk_id, def_id, "oberhau")
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
    CounterTempo.process_waiting(mgr, def)
    if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_winding":
        _fail(
            failures,
            (
                "counter_tempo_ui: want counter_winding got %s"
                % str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
            )
        )
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.6)
    CounterTempo.process_waiting(mgr, def)
    if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_ready":
        _fail(
            failures,
            (
                "counter_tempo_ui: want counter_ready got %s"
                % str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 riposte chain: **`grant_riposte_chain`** after deflect -> next wind-up vs that attacker ×
## **`RIPOSTE_CHAIN_WINDUP_MULT`**.


## Tier 4.2 riposte chain: **`grant_riposte_chain`** after deflect -> next wind-up vs that attacker ×
## **`RIPOSTE_CHAIN_WINDUP_MULT`**.
static func _run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(failures: PackedStringArray) -> void:
    var mgr_p: Node = CombatManager.new()
    mgr_p.register(_new_entity("SWORD"), "player")
    mgr_p.register(_new_entity("SWORD"), "enemy")
    mgr_p.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def_p: Dictionary = mgr_p.combatants[0]
    var atk_p: Dictionary = mgr_p.combatants[1]
    var def_p_id: int = CombatantEntityAccess.id_int(def_p)
    var atk_p_id: int = CombatantEntityAccess.id_int(atk_p)
    seed(_FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_p, def_p_id, atk_p_id, "oberhau", {"target_part": "chest"})
    var d_plain: float = float(def_p.get(DataKeys.PA_STATE_DURATION, 0.0))
    var mgr_r: Node = CombatManager.new()
    mgr_r.register(_new_entity("SWORD"), "player")
    mgr_r.register(_new_entity("SWORD"), "enemy")
    mgr_r.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def_r: Dictionary = mgr_r.combatants[0]
    var atk_r: Dictionary = mgr_r.combatants[1]
    var def_r_id: int = CombatantEntityAccess.id_int(def_r)
    var atk_r_id: int = CombatantEntityAccess.id_int(atk_r)
    CounterTempo.grant_riposte_chain(mgr_r, def_r, atk_r_id)
    seed(_FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_r, def_r_id, atk_r_id, "oberhau", {"target_part": "chest"})
    var d_rip: float = float(def_r.get(DataKeys.PA_STATE_DURATION, 0.0))
    var pa_r: Dictionary = CombatantEntityAccess.nested_dictionary_read(def_r, "pending_attack")
    if not pa_r.get(CombatConstants.PA_KEY_RIPOSTE_CHAIN, false):
        _fail(failures, "riposte_chain: pending_attack should stamp riposte_chain")
    var soft_cap_rc: float = CombatConstantsTiming.WIND_UP_SOFT_CAP_S
    var unwind_soft_cap_rc = func(capped: float, cap: float) -> float:
        if capped <= cap:
            return capped
        return cap + (capped - cap) * 2.0
    var plain_un: float = unwind_soft_cap_rc.call(d_plain, soft_cap_rc)
    var rip_un: float = unwind_soft_cap_rc.call(d_rip, soft_cap_rc)
    var want_r_uncapped: float = plain_un * CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT
    if absf(rip_un - want_r_uncapped) > 0.01:
        _fail(
            failures,
            "riposte_chain: pre-cap ratio mismatch want %.4f got %.4f plain=%.4f" % [want_r_uncapped, rip_un, plain_un]
        )
    if def_r.has(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL):
        _fail(failures, "riposte_chain: riposte window should be consumed after wind-up start")
    HarnessFixtures._free_manager_restore_global_rng(mgr_p)
    HarnessFixtures._free_manager_restore_global_rng(mgr_r)


## Tier 4.3: salience  -  telegraph part implies wind-up targeted.


## Tier 4.3: salience  -  telegraph part implies wind-up targeted.
static func _run_feint_move_listing_stance_ai_feint_mult_ordering(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.combatants[1]["guard"] = 0.0
    mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
    mgr.combatants[1]["off_balance_until"] = -1.0
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var enemy: Dictionary = mgr.combatants[1]
    var target_m: float = FeintTempoWindupListingTests._feint_listing_target_readiness_and_footwork_mult(
        enemy, p_id, "oberhau_feint"
    )
    harness_assign_form(mgr, player, CombatWeaponForm.FORM_FOOL)
    var w_plain_c: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_c: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var mult_c: float = CombatWeaponForm.mod(CombatWeaponForm.FORM_FOOL, "ai_feint_listing")
    var form_move_ratio_c: float = (
        CombatWeaponForm.action_weight_mult(CombatantEntityAccess.form_str(player), "oberhau_feint")
        / maxf(0.001, CombatWeaponForm.action_weight_mult(CombatantEntityAccess.form_str(player), "oberhau"))
    )
    var want_c: float = (
        w_plain_c * form_move_ratio_c * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * mult_c
    )
    if absf(w_feint_c - want_c) > 0.0001 * maxf(1.0, absf(w_plain_c)):
        _fail(
            failures,
            (
                "feint_stance_list ctrl: want feint %.6f (plain*base*stance) got %.6f plain=%.6f mult=%s"
                % [want_c, w_feint_c, w_plain_c, str(mult_c)]
            )
        )
    harness_assign_form(mgr, player, CombatWeaponForm.FORM_WALL)
    var w_plain_d: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_d: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var mult_d: float = CombatWeaponForm.mod(CombatWeaponForm.FORM_WALL, "ai_feint_listing")
    var form_move_ratio_d: float = (
        CombatWeaponForm.action_weight_mult(CombatantEntityAccess.form_str(player), "oberhau_feint")
        / maxf(0.001, CombatWeaponForm.action_weight_mult(CombatantEntityAccess.form_str(player), "oberhau"))
    )
    var want_d: float = (
        w_plain_d * form_move_ratio_d * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * mult_d
    )
    if absf(w_feint_d - want_d) > 0.0001 * maxf(1.0, absf(w_plain_d)):
        _fail(
            failures,
            (
                "feint_stance_list def: want feint %.6f got %.6f plain=%.6f mult=%s"
                % [want_d, w_feint_d, w_plain_d, str(mult_d)]
            )
        )
    var r_c: float = w_feint_c / w_plain_c
    var r_d: float = w_feint_d / w_plain_d
    if r_c <= r_d + 1e-6:
        _fail(
            failures, "feint_stance_list: want controlling feint/plain ratio > defensive got c=%.6f d=%.6f" % [r_c, r_d]
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker.opts_from_choice`** omits empty **`feint_part`**; non-**`is_feint`**
## **`_add_attack_target_part`** does not introduce **`feint_part`** on the choice dict.


## Tier 4.2: **`CombatAIActionPicker.opts_from_choice`** omits empty **`feint_part`**; non-**`is_feint`**
## **`_add_attack_target_part`** does not introduce **`feint_part`** on the choice dict.
static func _run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.combatants[1]["guard"] = 0.0
    mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_before: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    CombatAIActionPicker.record_opp_parry_deflect_for_feint_listing(mgr, player, e_id)
    var w_after: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_boost: float = w_before * CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT
    if absf(w_after - want_boost) > 0.0001 * maxf(1.0, absf(w_before)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "feint_list_parry_recent: want feint %.6f got %.6f before=%.6f top=%s"
                    % [
                        want_boost,
                        w_after,
                        w_before,
                        str(CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT),
                    ]
                )
            )
        )
    var tick_now: int = mgr.get_combat_tick_index()
    player[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = {
        str(e_id): tick_now - maxi(100, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS + 2)
    }
    var w_stale: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_stale - w_before) > 0.0001 * maxf(1.0, absf(w_before)):
        _fail(failures, "feint_list_parry_stale: want feint %.6f got %.6f before=%.6f" % [w_before, w_stale, w_before])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`off_balance_until`** ( **`PassiveParryContext.is_off_balance`** ) boosts feint-move listing vs
## that defender (**`(qp)`**).


## Tier 4.2: defender **`off_balance_until`** ( **`PassiveParryContext.is_off_balance`** ) boosts feint-move listing vs
## that defender (**`(qp)`**).
static func _run_feint_move_listing_defender_off_balance_boosts_feint_weight(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var enemy: Dictionary = mgr.combatants[1]
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    player["stance"] = CombatConstants.STANCE_BALANCED
    mgr.recompute_zoc_and_distance()
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var w_balanced: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["off_balance_until"] = CombatTiming.now_seconds() + 10.0
    var w_off: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want_off: float = (
        w_balanced
        * CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
        / CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
    )
    if absf(w_off - want_off) > 0.0001 * maxf(1.0, absf(w_balanced)):
        _fail(
            failures,
            "feint_list_off_balance: want feint %.6f got %.6f settled_base=%.6f" % [want_off, w_off, w_balanced]
        )
    enemy["off_balance_until"] = CombatTiming.now_seconds() - 1.0
    var w_cleared: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_cleared - w_balanced) > 0.0001 * maxf(1.0, absf(w_balanced)):
        _fail(
            failures,
            "feint_list_off_balance_clear: want feint %.6f got %.6f base=%.6f" % [w_balanced, w_cleared, w_balanced]
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: settled **`STATE_WAITING`** (not off-balance) dampens feint listing
## (**`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**); off-balance uses
## **`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** instead.


## Tier 4.2 footwork: settled **`STATE_WAITING`** (not off-balance) dampens feint listing
## (**`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**); off-balance uses
## **`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** instead.
static func _run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures: PackedStringArray) -> void:
    var c_target_only: Dictionary = {"move_id": "oberhau", "target_id": 1, "target_part": "chest"}
    var o_target: Dictionary = CombatAIActionPicker.opts_from_choice(c_target_only)
    if not o_target.has(DataKeys.ACTION_TARGET_PART) or str(o_target.get("target_part", "")) != "chest":
        _fail(failures, "feint_opts: expected target_part chest in opts got %s" % str(o_target))
    if o_target.has(DataKeys.ACTION_FEINT_PART):
        _fail(failures, "feint_opts: non-feint choice should omit feint_part got %s" % str(o_target))
    var c_with_feint: Dictionary = {
        "move_id": "oberhau_feint", "target_id": 1, "target_part": "chest", "feint_part": "head"
    }
    var o_both: Dictionary = CombatAIActionPicker.opts_from_choice(c_with_feint)
    if str(o_both.get("feint_part", "")) != "head":
        _fail(failures, "feint_opts: should forward non-empty feint_part got %s" % str(o_both))
    var c_thrust_feint: Dictionary = {
        "move_id": "thrust_feint",
        "target_id": 1,
        "target_part": "chest",
        "feint_part": "head",
    }
    var o_thrust_feint: Dictionary = CombatAIActionPicker.opts_from_choice(c_thrust_feint)
    if str(o_thrust_feint.get("feint_part", "")) != "head":
        _fail(failures, "feint_opts: thrust_feint should forward non-empty feint_part got %s" % str(o_thrust_feint))
    var c_empty_feint: Dictionary = {
        "move_id": "oberhau_feint", "target_id": 1, "target_part": "chest", "feint_part": ""
    }
    var o_no_feint: Dictionary = CombatAIActionPicker.opts_from_choice(c_empty_feint)
    if o_no_feint.has(DataKeys.ACTION_FEINT_PART):
        _fail(failures, "feint_opts: empty feint_part should be omitted got %s" % str(o_no_feint))
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(e)
    mgr.recompute_zoc_and_distance()
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var choice: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    CombatAIActionPicker._add_attack_target_part(choice, mgr, p_id)
    if str(choice.get("target_part", "")).is_empty():
        _fail(failures, "feint_neg: expected oberhau target_part from _add_attack_target_part")
    if choice.has(DataKeys.ACTION_FEINT_PART) and str(choice.get("feint_part", "")) != "":
        _fail(
            failures,
            "feint_neg: non-feint oberhau must not set non-empty feint_part got %s" % str(choice.get("feint_part", ""))
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Pass **`parry_readiness_for_feint` < 0** for default-args call (no feint read-through). Pass **`atk_id_for_spacing` <
## 0** (default) unless the scan must use the optional spacing arg on **`_guard_zone_modifier`**.


## Pass **`parry_readiness_for_feint` < 0** for default-args call (no feint read-through). Pass **`atk_id_for_spacing` <
## 0** (default) unless the scan must use the optional spacing arg on **`_guard_zone_modifier`**.
static func _run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(
    failures: PackedStringArray
) -> void:
    var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
    var pa_feint: Dictionary = {
        "feint_part": "head",
        "target_part": "left_leg",
        "attack_type": "oberhau_feint",
    }
    var tgt_baited: Dictionary = {
        "guard_zone": "head",
        "guard_line": "high",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    var bait_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_feint, tgt_baited, parts, "oberhau_feint", -1.0, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    )
    if bait_seed < 0:
        _fail(failures, "feint_guard_zone: no PathResolver seed yields bait penalty in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    seed(bait_seed)
    var m_pen: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
    if not is_equal_approx(m_pen, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(
            failures,
            (
                "feint_guard_zone: baited want penalty %.2f got %.2f"
                % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_pen]
            )
        )
    var tgt_readjust: Dictionary = {
        "guard_zone": "left_leg",
        "guard_line": "low",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    var readjust_bonus_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_feint, tgt_readjust, parts, "oberhau_feint", -1.0, CombatConstants.GUARD_ZONE_BONUS
    )
    if readjust_bonus_seed < 0:
        _fail(failures, "feint_guard_zone: no PathResolver seed yields readjust bonus in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    seed(readjust_bonus_seed)
    var m_ok: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_readjust, parts, "oberhau_feint")
    if not is_equal_approx(m_ok, CombatConstants.GUARD_ZONE_BONUS):
        _fail(
            failures, "feint_guard_zone: readjust want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_ok]
        )
    var pa_plain: Dictionary = {"target_part": "head", "attack_type": "oberhau"}
    var tgt_plain: Dictionary = {"guard_zone": "head", "guard_line": "high"}
    var plain_bonus_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_plain, tgt_plain, parts, "oberhau", -1.0, CombatConstants.GUARD_ZONE_BONUS
    )
    if plain_bonus_seed < 0:
        _fail(failures, "feint_guard_zone: no PathResolver seed yields non-feint bonus in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    seed(plain_bonus_seed)
    var m_plain: float = DefenseChoiceResolver._guard_zone_modifier(pa_plain, tgt_plain, parts, "oberhau")
    if not is_equal_approx(m_plain, CombatConstants.GUARD_ZONE_BONUS):
        _fail(
            failures,
            "feint_guard_zone: non-feint want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_plain]
        )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: high passive parry readiness + form can read real line despite **`guard_zone`** still on telegraph
## (**`FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** ×  **`CombatWeaponForm.mod(form_str, "feint_readthrough")`**).
## **`AttackPathResolver`** **`randf`**  -  scan a bait seed for telegraph mismatch, then **`seed(bait_seed)`** before
## each **`_guard_zone_modifier`** so **`expected_part`** matches across cases.


## Tier 4.2: high passive parry readiness + form can read real line despite **`guard_zone`** still on telegraph
## (**`FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** ×  **`CombatWeaponForm.mod(form_str, "feint_readthrough")`**).
## **`AttackPathResolver`** **`randf`**  -  scan a bait seed for telegraph mismatch, then **`seed(bait_seed)`** before
## each **`_guard_zone_modifier`** so **`expected_part`** matches across cases.
static func _run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures: PackedStringArray) -> void:
    var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
    var pa_feint: Dictionary = {
        "feint_part": "head",
        "target_part": "left_leg",
        "attack_type": "oberhau_feint",
    }
    var tgt_baited: Dictionary = {
        "guard_zone": "head",
        "guard_line": "high",
        "stance": "defensive",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    harness_sync_weapon_form_from_stance(tgt_baited, CombatConstants.STANCE_DEFENSIVE)
    var bait_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_feint, tgt_baited, parts, "oberhau_feint", -1.0, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    )
    if bait_seed < 0:
        _fail(failures, "feint_readthrough: no PathResolver seed yields bait penalty in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    seed(bait_seed)
    var m_default_args: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
    if not is_equal_approx(m_default_args, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(
            failures,
            (
                "feint_readthrough: default-args (no readiness) want penalty %.2f got %.2f"
                % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_default_args]
            )
        )
    seed(bait_seed)
    var m_full: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 1.0)
    if not is_equal_approx(m_full, CombatConstants.GUARD_ZONE_BONUS):
        _fail(
            failures,
            (
                "feint_readthrough: readiness 1 defensive want bonus %.2f got %.2f"
                % [CombatConstants.GUARD_ZONE_BONUS, m_full]
            )
        )
    seed(bait_seed)
    var m_mid: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.86)
    if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
        _fail(failures, "feint_readthrough: readiness 0.86 defensive want bonus got %.2f" % m_mid)
    seed(bait_seed)
    var m_low: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.82)
    if not is_equal_approx(m_low, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(failures, "feint_readthrough: readiness 0.82 defensive want penalty got %.2f" % m_low)
    var tgt_agg: Dictionary = {
        "guard_zone": "head",
        "guard_line": "high",
        "stance": "aggressive",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    harness_sync_weapon_form_from_stance(tgt_agg, CombatConstants.STANCE_AGGRESSIVE)
    seed(bait_seed)
    var m_agg: float = DefenseChoiceResolver._guard_zone_modifier(pa_feint, tgt_agg, parts, "oberhau_feint", 0.88)
    if not is_equal_approx(m_agg, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(failures, "feint_readthrough: aggressive 0.88 want penalty got %.2f" % m_agg)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` LONG** scales **`parry_readiness_for_feint`** before
## **`_feint_guard_reads_real_line`** in **`_guard_zone_modifier`** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_*`**);
## same base readiness at **MID** stays sub-threshold, **LONG** crosses (**defensive** ×  WF feint read-through).


## Tier 4.2: **`defender_distance_to` LONG** scales **`parry_readiness_for_feint`** before
## **`_feint_guard_reads_real_line`** in **`_guard_zone_modifier`** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_*`**);
## same base readiness at **MID** stays sub-threshold, **LONG** crosses (**defensive** ×  WF feint read-through).
static func _run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures: PackedStringArray) -> void:
    var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
    var pa_feint: Dictionary = {
        "feint_part": "head",
        "target_part": "left_leg",
        "attack_type": "oberhau_feint",
    }
    var atk_id: int = 42
    var tgt_baited_base: Dictionary = {
        "guard_zone": "head",
        "guard_line": "high",
        "stance": "defensive",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    harness_sync_weapon_form_from_stance(tgt_baited_base, CombatConstants.STANCE_DEFENSIVE)
    var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
    tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
    var tgt_long: Dictionary = tgt_baited_base.duplicate(true)
    tgt_long["distance_to"] = {atk_id: CombatConstants.DISTANCE_LONG}
    var bait_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_feint, tgt_baited_base, parts, "oberhau_feint", -1.0, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    )
    if bait_seed < 0:
        _fail(failures, "feint_gz_spacing: no PathResolver seed yields bait penalty in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    var pr_spacing: float = 0.81
    seed(bait_seed)
    var m_mid: float = DefenseChoiceResolver._guard_zone_modifier(
        pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id
    )
    seed(bait_seed)
    var m_long: float = DefenseChoiceResolver._guard_zone_modifier(
        pa_feint, tgt_long, parts, "oberhau_feint", pr_spacing, atk_id
    )
    if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(
            failures,
            "feint_gz_spacing: mid want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_mid]
        )
    if not is_equal_approx(m_long, CombatConstants.GUARD_ZONE_BONUS):
        _fail(failures, "feint_gz_spacing: long want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_long])
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` CLOSE** scales **`parry_readiness_for_feint`** down before
## **`_feint_guard_reads_real_line`**; same base readiness at **MID** clears the gate, **CLOSE** falls below
## (**defensive** ×  WF feint read-through).


## Tier 4.2: **`defender_distance_to` CLOSE** scales **`parry_readiness_for_feint`** down before
## **`_feint_guard_reads_real_line`**; same base readiness at **MID** clears the gate, **CLOSE** falls below
## (**defensive** ×  WF feint read-through).
static func _run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures: PackedStringArray) -> void:
    var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
    var pa_feint: Dictionary = {
        "feint_part": "head",
        "target_part": "left_leg",
        "attack_type": "oberhau_feint",
    }
    var atk_id: int = 43
    var tgt_baited_base: Dictionary = {
        "guard_zone": "head",
        "guard_line": "high",
        "stance": "defensive",
        CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
    }
    harness_sync_weapon_form_from_stance(tgt_baited_base, CombatConstants.STANCE_DEFENSIVE)
    var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
    tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
    var tgt_close: Dictionary = tgt_baited_base.duplicate(true)
    tgt_close["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
    var bait_seed: int = FeintTempoWindupListingTests._feint_guard_zone_sample_global_seed_for_modifier(
        pa_feint, tgt_baited_base, parts, "oberhau_feint", -1.0, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
    )
    if bait_seed < 0:
        _fail(failures, "feint_gz_spacing_close: no PathResolver seed yields bait penalty in 0..16383")
        seed(_HARNESS_RESTORE_GLOBAL_SEED)
        return
    var pr_spacing: float = 0.835
    seed(bait_seed)
    var m_mid: float = DefenseChoiceResolver._guard_zone_modifier(
        pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id
    )
    seed(bait_seed)
    var m_close: float = DefenseChoiceResolver._guard_zone_modifier(
        pa_feint, tgt_close, parts, "oberhau_feint", pr_spacing, atk_id
    )
    if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
        _fail(
            failures, "feint_gz_spacing_close: mid want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_mid]
        )
    if not is_equal_approx(m_close, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
        _fail(
            failures,
            (
                "feint_gz_spacing_close: close want penalty %.2f got %.2f"
                % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_close]
            )
        )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2 telegraph delay: **`DefenseChoiceResolver._feint_readiness_reveal_mult`**  -  early wind-up damps toward
## **`FEINT_PRE_REVEAL_READINESS_MULT`** until progress >= **`feint_target_reveal_at_progress`** (**`WeaponConstants`**
## / **`pa`**); no feint / reveal **0** -> **1.0**; **`choose_defense`** **`parry_readiness`** echoes the same mult when
## feint passive parry applies.


## Tier 4.2 telegraph delay: **`DefenseChoiceResolver._feint_readiness_reveal_mult`**  -  early wind-up damps toward
## **`FEINT_PRE_REVEAL_READINESS_MULT`** until progress >= **`feint_target_reveal_at_progress`** (**`WeaponConstants`**
## / **`pa`**); no feint / reveal **0** -> **1.0**; **`choose_defense`** **`parry_readiness`** echoes the same mult when
## feint passive parry applies.
static func _run_feint_target_reveal_progress_scales_readiness_mult(failures: PackedStringArray) -> void:
    var pa: Dictionary = {"feint_part": "head", "attack_type": "oberhau_feint"}
    var atk0: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": 0.0,
        "state_duration": 1.0,
    }
    var reveal: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.45))
    var m0: float = DefenseChoiceResolver._feint_readiness_reveal_mult(pa, atk0)
    var want0: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.0)
    if not is_equal_approx(m0, want0):
        _fail(failures, "feint_reveal t=0 want %.6f got %.6f" % [want0, m0])
    var atk_half: Dictionary = atk0.duplicate()
    atk_half["state_timer"] = reveal * 0.5 * atk0["state_duration"]
    var m_h: float = DefenseChoiceResolver._feint_readiness_reveal_mult(pa, atk_half)
    var want_h: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.5)
    if not is_equal_approx(m_h, want_h):
        _fail(failures, "feint_reveal half window want %.6f got %.6f" % [want_h, m_h])
    var atk_edge: Dictionary = atk0.duplicate()
    atk_edge["state_timer"] = reveal * atk0["state_duration"]
    if not is_equal_approx(DefenseChoiceResolver._feint_readiness_reveal_mult(pa, atk_edge), 1.0):
        _fail(failures, "feint_reveal at reveal_at want 1.0")
    var atk_late: Dictionary = atk0.duplicate()
    atk_late["state_timer"] = 0.99
    if not is_equal_approx(DefenseChoiceResolver._feint_readiness_reveal_mult(pa, atk_late), 1.0):
        _fail(failures, "feint_reveal late want 1.0")
    var pa_no_feint: Dictionary = {"feint_part": "", "attack_type": "oberhau"}
    if DefenseChoiceResolver._feint_readiness_reveal_mult(pa_no_feint, atk0) != 1.0:
        _fail(failures, "feint_reveal empty feint_part want 1.0")
    var pa_off: Dictionary = {
        "feint_part": "head",
        "feint_target_reveal_at_progress": 0.0,
        "attack_type": "oberhau_feint",
    }
    if DefenseChoiceResolver._feint_readiness_reveal_mult(pa_off, atk0) != 1.0:
        _fail(failures, "feint_reveal explicit zero want 1.0")
    var atk_rec: Dictionary = atk0.duplicate()
    atk_rec["state"] = CombatConstants.STATE_RECOVERING
    if DefenseChoiceResolver._feint_readiness_reveal_mult(pa, atk_rec) != 1.0:
        _fail(failures, "feint_reveal non-wind_up attacker want 1.0")
    var pa_stab: Dictionary = {"feint_part": "chest", "attack_type": "thrust_feint"}
    var reveal_stab: float = float(WeaponConstants.get_move("thrust_feint").get("feint_target_reveal_at_progress", 0.4))
    if not is_equal_approx(reveal_stab, 0.4):
        _fail(failures, "feint_reveal thrust_feint move want reveal 0.4 got %.6f" % reveal_stab)
    var atk_stab_half: Dictionary = atk0.duplicate()
    atk_stab_half["state_timer"] = reveal_stab * 0.5 * atk0["state_duration"]
    var m_stab_h: float = DefenseChoiceResolver._feint_readiness_reveal_mult(pa_stab, atk_stab_half)
    if not is_equal_approx(m_stab_h, want_h):
        _fail(failures, "feint_reveal thrust half window want %.6f got %.6f" % [want_h, m_stab_h])
    # choose_defense: reported parry_readiness scales by same mult during feint wind-up early vs late.
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(attacker)
    defender["stance"] = "balanced"
    defender["guard"] = 0.44
    defender["state"] = CombatConstants.STATE_WAITING
    defender["guard_zone"] = "chest"
    defender["guard_line"] = "high"
    defender["stamina"] = CombatConstants.STAMINA_MAX
    CombatantEntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
    var def_n2: Node = CombatantEntityAccess.scene_node(defender)
    var parts2: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n2)
    if parts2.is_empty():
        _fail(failures, "feint_reveal choose_def: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_fe: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch_fe: Dictionary = WeaponConstants.get_archetype(
        str(move_fe.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa_cd: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "head",
        "target_part": "chest",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    attacker["state"] = CombatConstants.STATE_WIND_UP
    attacker["state_duration"] = 1.0
    attacker["state_timer"] = 0.0
    seed(92003)
    var dc_e: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0
    )
    attacker["state_timer"] = 0.99
    seed(92003)
    var dc_l2: Dictionary = DefenseChoiceResolver.choose_defense(
        pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0
    )
    var pr_e: float = float(dc_e.get("parry_readiness", -1.0))
    var pr_l2: float = float(dc_l2.get("parry_readiness", -1.0))
    if pr_e <= 1e-8 or pr_l2 <= 1e-8:
        _fail(failures, "feint_reveal choose_def: parry_readiness too small pr_e=%.6f pr_l=%.6f" % [pr_e, pr_l2])
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not is_equal_approx(pr_e / pr_l2, want0):
        _fail(
            failures,
            (
                "feint_reveal choose_def: early/late readiness ratio want %.6f got %.6f (pr_e=%.6f pr_l=%.6f)"
                % [want0, pr_e / pr_l2, pr_e, pr_l2]
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2b (P4e): feint-move listing **`read_m`** damps early wind-up via **`_feint_readiness_reveal_mult`** (parity
## with **`choose_defense`**).


## Tier 4.2b (P4e): feint-move listing **`read_m`** damps early wind-up via **`_feint_readiness_reveal_mult`** (parity
## with **`choose_defense`**).
static func _run_feint_move_listing_reveal_progress_dampens_early_wind_up(failures: PackedStringArray) -> void:
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    mgr.recompute_zoc_and_distance()
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 1.0
    enemy["off_balance_until"] = -1.0
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var reveal: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.45))
    var pa: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "head",
        "target_part": "chest",
        "target_id": e_id,
        "feint_target_reveal_at_progress": reveal,
    }
    player["pending_attack"] = pa
    player["state"] = CombatConstants.STATE_WIND_UP
    player["state_duration"] = 1.0
    player["state_timer"] = 0.0
    var w_early: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_early: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint", player, pa
    )
    var stance_m: float = CombatWeaponForm.mod(CombatantEntityAccess.form_str(player), "ai_feint_listing")
    var settled_m_reveal: float = 1.0
    if (
        not PassiveParryContext.is_off_balance(enemy)
        and CombatantEntityAccess.state_str(enemy) != CombatConstants.STATE_WIND_UP
    ):
        var readiness_check: float = PassiveParryContext.get_passive_parry_readiness(enemy)
        if readiness_check <= 0.75:
            settled_m_reveal = (FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(
                enemy
            ))
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var want_early: float = (
        w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_early * settled_m_reveal * stance_m
    )
    if absf(w_early - want_early) > 0.0001 * maxf(1.0, absf(w_plain)):
        _fail(
            failures,
            (
                "feint_list_reveal early: want %.6f got %.6f read_m=%.6f settled_m=%.6f"
                % [want_early, w_early, read_early, settled_m_reveal]
            )
        )
    player["state_timer"] = 0.99
    var w_late: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_late: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint", player, pa
    )
    var want_late: float = (
        w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_late * settled_m_reveal * stance_m
    )
    if absf(w_late - want_late) > 0.0001 * maxf(1.0, absf(w_plain)):
        _fail(
            failures,
            (
                "feint_list_reveal late: want %.6f got %.6f read_m=%.6f settled_m=%.6f"
                % [want_late, w_late, read_late, settled_m_reveal]
            )
        )
    if w_late <= w_early + 0.0001:
        _fail(failures, "feint_list_reveal: want late > early got early=%.6f late=%.6f" % [w_early, w_late])
    if read_late <= read_early + 0.0001:
        _fail(
            failures, "feint_list_reveal: read_m late want > early got early=%.6f late=%.6f" % [read_early, read_late]
        )
    player["state"] = CombatConstants.STATE_WAITING
    player.erase("pending_attack")
    var w_waiting: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_waiting: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    if not is_equal_approx(w_waiting, w_late):
        _fail(
            failures,
            "feint_list_reveal waiting: weight should match no-live-pa listing got %.6f late=%.6f" % [w_waiting, w_late]
        )
    if not is_equal_approx(read_waiting, read_late):
        _fail(failures, "feint_list_reveal waiting read_m: want late read_m %.6f got %.6f" % [read_late, read_waiting])
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`DefenseChoiceResolver.choose_defense`**  -  when **`feint_part`** is set and defender does not read
## through (**`guard` ×  stance `feint_readthrough` < `FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`**),
## **`dodge_eval_part`** can follow the telegraph; harness sets
## **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** to **1.0** for a deterministic assert.


## Tier 4.2: **`DefenseChoiceResolver.choose_defense`**  -  when **`feint_part`** is set and defender does not read
## through (**`guard` ×  stance `feint_readthrough` < `FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`**),
## **`dodge_eval_part`** can follow the telegraph; harness sets
## **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** to **1.0** for a deterministic assert.
static func _run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(failures: PackedStringArray) -> void:
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = HarnessFixtures._harness_start_1v1()
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["stance"] = "balanced"
    defender["guard"] = 0.5
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = CombatantEntityAccess.scene_node(defender)
    var parts: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "feint_dodge_eval: targetable parts empty")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    if not parts.has("left_leg"):
        _fail(failures, "feint_dodge_eval: fixture needs left_leg in targetable")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau_feint",
        "feint_part": "left_leg",
        "target_part": "chest",
        "intensity": 0.6,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
        CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
    }
    seed(1337)
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, attacker, defender, parts, "oberhau_feint", arch, -1.0
    )
    if str(dc.get("dodge_eval_part", "")) != "left_leg":
        _fail(
            failures,
            (
                "feint_dodge_eval: want dodge_eval_part left_leg (telegraph bait) got %s"
                % str(dc.get("dodge_eval_part", ""))
            )
        )
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## Tier 4.2 footwork: **`feint_guard_zone_readiness_spacing_mult`** on **`pr_rt`** for
## **`_feint_guard_reads_real_line`** in **`_apply_feint_telegraph_bias_to_dodge_eval_part`**  -  defensive **`guard`**
## ×  WF feint read-through fails at **MID** (**`DISTANCE_MID`**) but clears at **LONG**
## (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG`**). Same global **`seed(s)`** before each **`choose_defense`**:
## **LONG** keeps the initial **`BodyPartConstants.get_weighted_random_part`** draw (scan for **>= ** **`left_leg`**);
## **MID** with harness bias **1.0** always telegraphs **`dodge_eval_part`** to **`feint_part`**.
