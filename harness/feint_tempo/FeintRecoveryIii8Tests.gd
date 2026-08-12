class_name FeintTempoRecoveryIii8Tests
extends CombatRegressionHarnessCore

const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func _run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(
    failures: PackedStringArray
) -> void:
    var mgr: Node = _CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var enemy: Dictionary = mgr.combatants[1]
    mgr.recompute_zoc_and_distance()
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 1.0
    if not WeaponConstants.is_feint_move("thrust_feint"):
        _CombatRegressionHarness._fail(failures, "feint_list_incoming_ct: thrust_feint should register as is_feint")
        _CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var a_plain_c: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint_c: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var a_plain_s: Dictionary = {"move_id": "thrust", "target_id": e_id}
    var a_feint_s: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
    var wpc: float = CombatAIActionPicker._get_action_weight(a_plain_c, p_id, mgr, true)
    var wfc: float = CombatAIActionPicker._get_action_weight(a_feint_c, p_id, mgr, true)
    var wps: float = CombatAIActionPicker._get_action_weight(a_plain_s, p_id, mgr, true)
    var wfs: float = CombatAIActionPicker._get_action_weight(a_feint_s, p_id, mgr, true)
    if wpc <= 1e-8 or wps <= 1e-8:
        _CombatRegressionHarness._fail(
            failures, "feint_list_incoming_ct: plain weights too small pc=%.8f ps=%.8f" % [wpc, wps]
        )
        _CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var boost_c: float = wfc / wpc
    var boost_s: float = wfs / wps
    if boost_s >= boost_c - 1e-5:
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_incoming_ct: stab feint/thrust plain boost %.6f should be < cut feint/oberhau plain %.6f"
                % [boost_s, boost_c]
            )
        )
    _CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  feint listing defender readiness matches
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** after passive - -  incoming
## **`contact_type`** ( **`w_feint_lo` / `w_feint_hi` == read_m ratio**; attacker stamina full).


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  feint listing defender readiness matches
## **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** after passive - -  incoming
## **`contact_type`** ( **`w_feint_lo` / `w_feint_hi` == read_m ratio**; attacker stamina full).
static func _run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(
    failures: PackedStringArray
) -> void:
    var mgr: Node = _CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    player["stance"] = CombatConstants.STANCE_BALANCED
    player["stamina"] = CombatConstants.STAMINA_MAX
    enemy["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.44
    mgr.recompute_zoc_and_distance()
    var pr_base: float = DefenseChoiceResolver.defender_feint_listing_pr_def(
        enemy, p_id, "oberhau_feint", {}, {}, false, false
    )
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    var pr_hi: float = clampf(
        (
            pr_base
            * CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
                CombatantEntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
            )
        ),
        0.0,
        1.0
    )
    var read_hi: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_hi)
    enemy["stamina"] = 0.0
    var pr_lo: float = clampf(
        (
            pr_base
            * CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
                CombatantEntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
            )
        ),
        0.0,
        1.0
    )
    var read_lo: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_lo)
    var want: float = read_lo / read_hi
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    var w_plain_hi: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_hi: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    enemy["stamina"] = 0.0
    var w_plain_lo: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_lo: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if not is_equal_approx(w_plain_lo, w_plain_hi):
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_def_stam: plain weight should not depend on defender stamina lo=%.6f hi=%.6f"
                % [w_plain_lo, w_plain_hi]
            )
        )
    elif w_feint_hi <= 1e-8:
        _CombatRegressionHarness._fail(
            failures, "feint_list_def_stam: full-stamina feint weight too small %.8f" % w_feint_hi
        )
    elif not is_equal_approx(w_feint_lo / w_feint_hi, want):
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_def_stam: feint weight ratio want %.6f got %.6f (w_lo=%.6f w_hi=%.6f)"
                % [want, w_feint_lo / w_feint_hi, w_feint_lo, w_feint_hi]
            )
        )
    _CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: defender low stamina on feint **`read_m`** - -  attacker low stamina on **`AI_FEINT_LISTING_STAMINA_*`**
## multiply independently (**`w_ll/w_ml` == `w_lm/w_mm`** for **`oberhau_feint`**).


## Tier 4.2: defender low stamina on feint **`read_m`** - -  attacker low stamina on **`AI_FEINT_LISTING_STAMINA_*`**
## multiply independently (**`w_ll/w_ml` == `w_lm/w_mm`** for **`oberhau_feint`**).
static func _run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(
    failures: PackedStringArray
) -> void:
    var mgr: Node = _CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    player["stance"] = CombatConstants.STANCE_BALANCED
    enemy["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.44
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    player["stamina"] = CombatConstants.STAMINA_MAX
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    mgr.recompute_zoc_and_distance()
    var w_mm: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    enemy["stamina"] = CombatConstants.STAMINA_MAX
    mgr.recompute_zoc_and_distance()
    var w_ml: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    player["stamina"] = CombatConstants.STAMINA_MAX
    enemy["stamina"] = 0.0
    mgr.recompute_zoc_and_distance()
    var w_lm: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
    enemy["stamina"] = 0.0
    mgr.recompute_zoc_and_distance()
    var w_ll: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if w_mm <= 1e-8 or w_ml <= 1e-8:
        _CombatRegressionHarness._fail(
            failures, "feint_list_stam_ortho: feint weights too small mm=%.8f ml=%.8f" % [w_mm, w_ml]
        )
        _CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var lhs: float = w_ll / w_ml
    var rhs: float = w_lm / w_mm
    if not is_equal_approx(lhs, rhs):
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_stam_ortho: w_ll/w_ml %.6f vs w_lm/w_mm %.6f (mm=%.6f ml=%.6f lm=%.6f ll=%.6f)"
                % [lhs, rhs, w_mm, w_ml, w_lm, w_ll]
            )
        )
    _CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: second **`AttackWindUpStarter.start`** without resolve clears prior defender
## **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** then restamps for the new wind-up.


## Tier 4.2: second **`AttackWindUpStarter.start`** without resolve clears prior defender
## **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** then restamps for the new wind-up.
static func _run_feint_telegraph_scrubbed_on_combat_manager_restart(failures: PackedStringArray) -> void:
    var mgr: Node = _CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(_CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "left_leg", "feint_part": "head"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_restart: expected telegraph head before second start got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if e.has(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART):
        _CombatRegressionHarness._fail(
            failures,
            (
                "feint_restart: second start should scrub incoming telegraph key got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    _CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.1: `stance_ai_targeting_mult` orders defensive < balanced < aggressive. See
## `docs/LIVE_PATHS.md#tier-4--ai--footwork--flurry`.


## III-8: compatibility **`parry_deflect`** cause alias aligns passive readiness + tier-4.2 footwork with
## **`attack_deflect`**.
static func _run_recovery_cause_parry_deflect_alias_aligns_readiness_and_footwork(failures: PackedStringArray) -> void:
    var def_curve: Array = CombatConstants.readiness_curve_for_cause("attack_deflect")
    var alias_curve: Array = CombatConstants.readiness_curve_for_cause("parry_deflect")
    if alias_curve != def_curve:
        _CombatRegressionHarness._fail(
            failures, "recovery_cause_alias: readiness parry_deflect want %s got %s" % [def_curve, alias_curve]
        )
    var m_def: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_deflect")
    var m_alias: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("parry_deflect")
    if not is_equal_approx(m_def, m_alias):
        _CombatRegressionHarness._fail(
            failures, "recovery_cause_alias: footwork parry_deflect want %.4f got %.4f" % [m_def, m_alias]
        )
    var c: Dictionary = {
        "state": CombatConstants.STATE_RECOVERING,
        "state_duration": 1.0,
        "state_timer": 0.5,
        "recovery_cause": "parry_deflect",
    }
    var c_canon: Dictionary = c.duplicate(true)
    c_canon["recovery_cause"] = "attack_deflect"
    var r_alias: float = PassiveParryContext.get_passive_parry_readiness(c)
    var r_canon: float = PassiveParryContext.get_passive_parry_readiness(c_canon)
    if not is_equal_approx(r_alias, r_canon):
        _CombatRegressionHarness._fail(
            failures, "recovery_cause_alias: passive readiness want %.4f got %.4f" % [r_canon, r_alias]
        )
    var m_partial: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("parry_partial")
    if not is_equal_approx(m_def, m_partial):
        _CombatRegressionHarness._fail(
            failures, "recovery_cause_alias: footwork parry_partial want %.4f got %.4f" % [m_def, m_partial]
        )


## III-8: canonical causes share readiness curves + inverse feint/dodge footwork mults.


## III-8: canonical causes share readiness curves + inverse feint/dodge footwork mults.
static func _run_iii8_recovery_cause_table_parity(failures: PackedStringArray) -> void:
    var causes: Array = ["attack_hit", "attack_miss", "attack_deflect", "skip"]
    for k in causes:
        if not CombatConstants.DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE.has(k):
            _CombatRegressionHarness._fail(failures, "iii8_table: missing footwork mult for cause %s" % k)
        var curve: Array = CombatConstants.readiness_curve_for_cause(str(k))
        if curve.size() < 2:
            _CombatRegressionHarness._fail(failures, "iii8_table: readiness curve for %s want [early, late]" % k)
        var dodge_m: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause(str(k))
        var feint_m: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(str(k))
        if not is_equal_approx(feint_m, 1.0 / dodge_m):
            _CombatRegressionHarness._fail(
                failures,
                "iii8_table: feint/dodge inverse mismatch for %s dodge=%.4f feint=%.4f" % [k, dodge_m, feint_m]
            )
    var m_hit: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
    var m_miss: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_miss")
    if m_hit > m_miss + 0.01:
        pass  # attack_hit dodge mult exceeds attack_miss (miss recovery is more punishing).
    else:
        _CombatRegressionHarness._fail(
            failures, "iii8_table: attack_hit dodge mult want > attack_miss got hit=%.4f miss=%.4f" % [m_hit, m_miss]
        )
    var hit_curve: Array = CombatConstants.readiness_curve_for_cause("attack_hit")
    var miss_curve: Array = CombatConstants.readiness_curve_for_cause("attack_miss")
    if float(miss_curve[1]) <= float(hit_curve[1]):
        _CombatRegressionHarness._fail(failures, "iii8_table: attack_miss late readiness want > attack_hit")

