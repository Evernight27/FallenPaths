class_name FeintTempoWindupListingTests
extends CombatRegressionHarnessCore
## Tier 4.2 feint / counter-tempo / riposte / defense telegraph tests (compile split).
## Weapon form: **`CombatRegressionHarnessWeaponFormTail`** owns **`form_str`** / **`mod`**  -  stance alias rows here
## stay feint/tempo only.
## Footing harness: tier-4.2 spacing/state **`defense_footwork_*`** / feint listing  -  **not** Tier 4.4 PA
## (**`CombatFootwork`**). LIVE_PATHS **`#wf-layer-labels`** . **`#harness-footwork-catalog`** (feint rows).


static func _feint_listing_read_m_expect_for_move_on_target(
    tgt_enemy: Dictionary,
    combatant_id_for_spacing: int,
    feint_move_id: String,
    attacker: Dictionary = {},
    pa_live: Dictionary = {}
) -> float:
    var pr_def: float = DefenseChoiceResolver.defender_feint_listing_pr_def(
        tgt_enemy, combatant_id_for_spacing, feint_move_id, attacker, pa_live
    )
    return lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)


## Defender footwork on feint listing (off-balance / recovering / settled waiting); **1** otherwise.


## Defender footwork on feint listing (off-balance / recovering / settled waiting); **1** otherwise.
static func _feint_listing_defender_footwork_state_mult_for_target(tgt_enemy: Dictionary) -> float:
    if PassiveParryContext.is_off_balance(tgt_enemy):
        return 1.0
    var st: String = str(tgt_enemy.get("state", ""))
    if st == CombatConstants.STATE_RECOVERING:
        return CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
            str(tgt_enemy.get("recovery_cause", "skip"))
        )
    if st == CombatConstants.STATE_WAITING:
        return CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
    return 1.0


## Defender-side feint-listing mult: readiness lerp - -  footwork state mult (when applicable).


## Defender-side feint-listing mult: readiness lerp - -  footwork state mult (when applicable).
static func _feint_listing_target_readiness_and_footwork_mult(
    tgt_enemy: Dictionary, combatant_id_for_spacing: int, feint_move_id: String
) -> float:
    return (
        FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
            tgt_enemy, combatant_id_for_spacing, feint_move_id
        )
        * FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(tgt_enemy)
    )


static func _feint_guard_zone_sample_global_seed_for_modifier(
    pa: Dictionary,
    tgt: Dictionary,
    parts: Array,
    move_id: String,
    parry_readiness_for_feint: float,
    want_mult: float,
    atk_id_for_spacing: int = -1
) -> int:
    for s: int in range(16384):
        seed(s)
        var m: float
        if parry_readiness_for_feint < 0.0:
            m = DefenseChoiceResolver._guard_zone_modifier(pa, tgt, parts, move_id)
        elif atk_id_for_spacing < 0:
            m = DefenseChoiceResolver._guard_zone_modifier(pa, tgt, parts, move_id, parry_readiness_for_feint)
        else:
            m = DefenseChoiceResolver._guard_zone_modifier(
                pa, tgt, parts, move_id, parry_readiness_for_feint, atk_id_for_spacing
            )
        if is_equal_approx(m, want_mult):
            return s
    return -1


## Tier 4.2: **`DefenseChoiceResolver._guard_zone_modifier`**  -  feint telegraph mismatch ->
## **`GUARD_ZONE_UNGUARDED_PENALTY`**; defender **`guard_zone`** moved to real line -> **`GUARD_ZONE_BONUS`**; non-feint
## unchanged. **`AttackPathResolver`** uses **`randf`**  -  scan stable seeds per fixture, then restore global RNG.


## Tier 4.2: **`DefenseChoiceResolver._guard_zone_modifier`**  -  feint telegraph mismatch ->
## **`GUARD_ZONE_UNGUARDED_PENALTY`**; defender **`guard_zone`** moved to real line -> **`GUARD_ZONE_BONUS`**; non-feint
## unchanged. **`AttackPathResolver`** uses **`randf`**  -  scan stable seeds per fixture, then restore global RNG.
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "left_leg", "feint_part": "head"})
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(p, "pending_attack")
    if str(pa.get("target_part", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures, "feint_windup: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
        )
    if str(pa.get("feint_part", "")) != "head":
        CombatRegressionHarness._fail(
            failures, "feint_windup: pending feint_part want head got %s" % str(pa.get("feint_part", ""))
        )
    if str(e.get("guard_zone", "")) != "head":
        CombatRegressionHarness._fail(
            failures, "feint_windup: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
        )
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup: defender incoming telegraph want head got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    var reveal_expect: float = float(
        WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.0)
    )
    if reveal_expect <= 0.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup: oberhau_feint should define feint_target_reveal_at_progress > 0"
        )
    if not pa.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup: pending_attack should stamp feint_target_reveal_at_progress"
        )
    if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup: feint_target_reveal_at_progress want %s got %s"
                % [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, for stab **`thrust_feint`** on
## **SWORD** ( **`feint_windup_duration_mult`** stamp + telegraph keys).


## Tier 4.2: same as **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, for stab **`thrust_feint`** on
## **SWORD** ( **`feint_windup_duration_mult`** stamp + telegraph keys).
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr, p_id, e_id, "thrust_feint", {"target_part": "chest", "feint_part": "head"})
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(p, "pending_attack")
    if str(pa.get("attack_type", "")) != "thrust_feint":
        CombatRegressionHarness._fail(
            failures,
            "feint_windup_thrust: pending attack_type want thrust_feint got %s" % str(pa.get("attack_type", ""))
        )
    if str(pa.get("target_part", "")) != "chest":
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: pending target_part want chest got %s" % str(pa.get("target_part", ""))
        )
    if str(pa.get("feint_part", "")) != "head":
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: pending feint_part want head got %s" % str(pa.get("feint_part", ""))
        )
    if str(pa.get("move_contact_type", "")) != WeaponConstants.ATTACK_TYPE_STAB:
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: move_contact_type want stab got %s" % str(pa.get("move_contact_type", ""))
        )
    if str(e.get("guard_zone", "")) != "head":
        CombatRegressionHarness._fail(
            failures,
            "feint_windup_thrust: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
        )
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_thrust: defender incoming telegraph want head got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
    var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
    if mult_expect <= 1.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: thrust_feint should define feint_windup_duration_mult > 1"
        )
    if not pa.has("feint_windup_duration_mult"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: pending_attack should stamp feint_windup_duration_mult"
        )
    if not is_equal_approx(float(pa.get("feint_windup_duration_mult", 0.0)), mult_expect):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_thrust: feint_windup_duration_mult want %s got %s"
                % [str(mult_expect), str(pa.get("feint_windup_duration_mult", ""))]
            )
        )
    var reveal_expect: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
    if reveal_expect <= 0.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: thrust_feint should define feint_target_reveal_at_progress > 0"
        )
    if not pa.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_thrust: pending_attack should stamp feint_target_reveal_at_progress"
        )
    if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_thrust: feint_target_reveal_at_progress want %s got %s"
                % [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`WeaponConstants`** move **`feint_windup_duration_mult`** on **`is_feint`** cuts extends
## **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs **`oberhau`** at the
## same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`pa["feint_target_reveal_at_progress"]`** when
## defined.


## Tier 4.2: **`WeaponConstants`** move **`feint_windup_duration_mult`** on **`is_feint`** cuts extends
## **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs **`oberhau`** at the
## same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`pa["feint_target_reveal_at_progress"]`** when
## defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(failures: PackedStringArray) -> void:
    var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
    var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
    if mult_expect <= 1.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult: oberhau_feint should define feint_windup_duration_mult > 1"
        )
    var mgr_o: Node = CombatRegressionHarness._harness_start_1v1()
    var po: Dictionary = mgr_o.combatants[0]
    var eo: Dictionary = mgr_o.combatants[1]
    var po_id: int = CombatantEntityAccess.id_int(po)
    var eo_id: int = CombatantEntityAccess.id_int(eo)
    eo["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_o, po_id, eo_id, "oberhau", {"target_part": "chest"})
    var d_o: float = float(po.get(DataKeys.PA_STATE_DURATION, 0.0))
    var mgr_f: Node = CombatRegressionHarness._harness_start_1v1()
    var pf: Dictionary = mgr_f.combatants[0]
    var ef: Dictionary = mgr_f.combatants[1]
    var pf_id: int = CombatantEntityAccess.id_int(pf)
    var ef_id: int = CombatantEntityAccess.id_int(ef)
    ef["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_f, pf_id, ef_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
    var d_f: float = float(pf.get(DataKeys.PA_STATE_DURATION, 0.0))
    var pa_f: Dictionary = CombatantEntityAccess.nested_dictionary_read(pf, "pending_attack")
    if not pa_f.has("feint_windup_duration_mult"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult: pending_attack should stamp feint_windup_duration_mult"
        )
    var reveal_f: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
    if reveal_f <= 0.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult: oberhau_feint should define feint_target_reveal_at_progress > 0"
        )
    if not pa_f.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult: pending_attack should stamp feint_target_reveal_at_progress"
        )
    if not is_equal_approx(float(pa_f.get("feint_target_reveal_at_progress", -1.0)), reveal_f):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult: feint_target_reveal_at_progress want %s got %s"
                % [str(reveal_f), str(pa_f.get("feint_target_reveal_at_progress", ""))]
            )
        )
    if not is_equal_approx(float(pa_f.get("feint_windup_duration_mult", 0.0)), mult_expect):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult: pa feint_windup_duration_mult want %s got %s"
                % [str(mult_expect), str(pa_f.get("feint_windup_duration_mult", ""))]
            )
        )
    if not is_equal_approx(float(pa_f.get("wind_up_duration", 0.0)), d_f):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult: wind_up_duration should match state_duration got pa=%s state=%s"
                % [str(pa_f.get("wind_up_duration", "")), str(d_f)]
            )
        )
    var want_f: float = d_o * mult_expect
    if absf(d_f - want_f) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult: feint state_duration want ~ d_oberhau*mult got d_f=%s d_o=%s mult=%s"
                % [str(d_f), str(d_o), str(mult_expect)]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_o)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_f)


## Tier 4.2: **`WeaponConstants`** **`thrust_feint`** **`feint_windup_duration_mult`** extends
## **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs honest **`thrust`**
## at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`feint_target_reveal_at_progress`** when
## defined.


## Tier 4.2: **`WeaponConstants`** **`thrust_feint`** **`feint_windup_duration_mult`** extends
## **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs honest **`thrust`**
## at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`feint_target_reveal_at_progress`** when
## defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_thrust(failures: PackedStringArray) -> void:
    var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
    var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
    if mult_expect <= 1.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult_thrust: thrust_feint should define feint_windup_duration_mult > 1"
        )
    var mgr_t: Node = CombatRegressionHarness._harness_start_1v1()
    var pt: Dictionary = mgr_t.combatants[0]
    var et: Dictionary = mgr_t.combatants[1]
    var pt_id: int = CombatantEntityAccess.id_int(pt)
    var et_id: int = CombatantEntityAccess.id_int(et)
    et["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_t, pt_id, et_id, "thrust", {"target_part": "chest"})
    var d_t: float = float(pt.get(DataKeys.PA_STATE_DURATION, 0.0))
    var mgr_tf: Node = CombatRegressionHarness._harness_start_1v1()
    var ptf: Dictionary = mgr_tf.combatants[0]
    var etf: Dictionary = mgr_tf.combatants[1]
    var ptf_id: int = CombatantEntityAccess.id_int(ptf)
    var etf_id: int = CombatantEntityAccess.id_int(etf)
    etf["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED)
    AttackWindUpStarter.start(mgr_tf, ptf_id, etf_id, "thrust_feint", {"target_part": "chest", "feint_part": "head"})
    var d_tf: float = float(ptf.get(DataKeys.PA_STATE_DURATION, 0.0))
    var pa_tf: Dictionary = CombatantEntityAccess.nested_dictionary_read(ptf, "pending_attack")
    if not pa_tf.has("feint_windup_duration_mult"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult_thrust: pending_attack should stamp feint_windup_duration_mult"
        )
    var reveal_tf: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
    if reveal_tf <= 0.0:
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult_thrust: thrust_feint should define feint_target_reveal_at_progress > 0"
        )
    if not pa_tf.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_mult_thrust: pending_attack should stamp feint_target_reveal_at_progress"
        )
    if not is_equal_approx(float(pa_tf.get("feint_target_reveal_at_progress", -1.0)), reveal_tf):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult_thrust: feint_target_reveal_at_progress want %s got %s"
                % [str(reveal_tf), str(pa_tf.get("feint_target_reveal_at_progress", ""))]
            )
        )
    if not is_equal_approx(float(pa_tf.get("feint_windup_duration_mult", 0.0)), mult_expect):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult_thrust: pa feint_windup_duration_mult want %s got %s"
                % [str(mult_expect), str(pa_tf.get("feint_windup_duration_mult", ""))]
            )
        )
    if not is_equal_approx(float(pa_tf.get("wind_up_duration", 0.0)), d_tf):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult_thrust: wind_up_duration should match state_duration got pa=%s state=%s"
                % [str(pa_tf.get("wind_up_duration", "")), str(d_tf)]
            )
        )
    var want_tf: float = d_t * mult_expect
    if absf(d_tf - want_tf) > 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_mult_thrust: feint state_duration want ~ d_thrust*mult got d_tf=%s d_t=%s mult=%s"
                % [str(d_tf), str(d_t), str(mult_expect)]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_t)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_tf)


## Tier 4.2: **`AttackWindUpStarter.start`** with **`target_part`** only (no **`feint_part`**) stamps
## **`pending_attack`** and sets defender **`guard_zone`** to **`target_part`** (non-feint **`oberhau`**). Uses
## **`CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED`** for stable wind-up rolls.


## Tier 4.2: **`AttackWindUpStarter.start`** with **`target_part`** only (no **`feint_part`**) stamps
## **`pending_attack`** and sets defender **`guard_zone`** to **`target_part`** (non-feint **`oberhau`**). Uses
## **`CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED`** for stable wind-up rolls.
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
    AttackWindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "left_leg"})
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(p, "pending_attack")
    if str(pa.get("target_part", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            "feint_windup_target_only: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
        )
    if pa.has(DataKeys.ACTION_FEINT_PART) and str(pa.get("feint_part", "")) != "":
        CombatRegressionHarness._fail(
            failures,
            "feint_windup_target_only: should not stamp non-empty feint_part got %s" % str(pa.get("feint_part", ""))
        )
    if pa.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_target_only: plain oberhau should not stamp feint_target_reveal_at_progress"
        )
    if str(e.get("guard_zone", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_target_only: defender guard_zone telegraph want left_leg got %s"
                % str(e.get("guard_zone", ""))
            )
        )
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_target_only: defender incoming telegraph want left_leg got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, for honest **`thrust`** (no
## **`feint_target_reveal_at_progress`** on **`pending_attack`**).


## Tier 4.2: same as **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, for honest **`thrust`** (no
## **`feint_target_reveal_at_progress`** on **`pending_attack`**).
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    e["guard_zone"] = "chest"
    seed(CombatRegressionHarness._FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
    AttackWindUpStarter.start(mgr, p_id, e_id, "thrust", {"target_part": "left_leg"})
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(p, "pending_attack")
    if str(pa.get("target_part", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            "feint_windup_target_only_thrust: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
        )
    if pa.has(DataKeys.ACTION_FEINT_PART) and str(pa.get("feint_part", "")) != "":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_target_only_thrust: should not stamp non-empty feint_part got %s"
                % str(pa.get("feint_part", ""))
            )
        )
    if pa.has("feint_target_reveal_at_progress"):
        CombatRegressionHarness._fail(
            failures, "feint_windup_target_only_thrust: plain thrust should not stamp feint_target_reveal_at_progress"
        )
    if str(e.get("guard_zone", "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_target_only_thrust: defender guard_zone telegraph want left_leg got %s"
                % str(e.get("guard_zone", ""))
            )
        )
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_windup_target_only_thrust: defender incoming telegraph want left_leg got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._add_attack_target_part`** for **`is_feint`** moves picks **`feint_part`** >=
## **`target_part`** when at least two targetable parts exist (bounded **`seed(0..4095)`** search on Godot
## **4.6.stable**). Restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** after the scan so
## **`run_all()`** order stays stable.


## Tier 4.2: **`CombatAIActionPicker._add_attack_target_part`** for **`is_feint`** moves picks **`feint_part`** >=
## **`target_part`** when at least two targetable parts exist (bounded **`seed(0..4095)`** search on Godot
## **4.6.stable**). Restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** after the scan so
## **`run_all()`** order stays stable.
static func _run_feint_move_ai_distinct_feint_and_target_parts(failures: PackedStringArray) -> void:
    if not WeaponConstants.is_feint_move("oberhau_feint"):
        CombatRegressionHarness._fail(failures, "feint_ai: WeaponConstants.is_feint_move(oberhau_feint) should be true")
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    mgr.recompute_zoc_and_distance()
    var found: bool = false
    for s in range(4096):
        seed(s)
        var choice: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
        CombatAIActionPicker._add_attack_target_part(choice, mgr, p_id)
        var tp: String = str(choice.get("target_part", ""))
        var fp: String = str(choice.get("feint_part", ""))
        if not tp.is_empty() and not fp.is_empty() and fp != tp:
            found = true
            break
    if not found:
        CombatRegressionHarness._fail(
            failures,
            "feint_ai: no seed in 0..4095 produced distinct non-empty feint_part and target_part for oberhau_feint"
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_ai_distinct_feint_and_target_parts`**, for **`thrust_feint`** on **SWORD**.


## Tier 4.2: same as **`_run_feint_move_ai_distinct_feint_and_target_parts`**, for **`thrust_feint`** on **SWORD**.
static func _run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures: PackedStringArray) -> void:
    if not WeaponConstants.is_feint_move("thrust_feint"):
        CombatRegressionHarness._fail(
            failures, "feint_ai_thrust: WeaponConstants.is_feint_move(thrust_feint) should be true"
        )
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(e)
    mgr.recompute_zoc_and_distance()
    var found: bool = false
    for s in range(4096):
        seed(s)
        var choice: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
        CombatAIActionPicker._add_attack_target_part(choice, mgr, p_id)
        var tp: String = str(choice.get("target_part", ""))
        var fp: String = str(choice.get("feint_part", ""))
        if not tp.is_empty() and not fp.is_empty() and fp != tp:
            found = true
            break
    if not found:
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_ai_thrust: no seed in 0..4095 produced distinct non-empty feint_part and target_part for thrust_"
                + "feint"
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  **`oberhau_feint`** vs same-target **`oberhau`** scales
## by **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** (SWORD 1v1 fixture).


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`**  -  **`oberhau_feint`** vs same-target **`oberhau`** scales
## by **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** (SWORD 1v1 fixture).
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.recompute_zoc_and_distance()
    ## Pin defender readiness to **0** (WAITING **`guard`**); isolates base **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`**
    ## vs readiness lerp harness.
    mgr.combatants[1]["guard"] = 0.0
    mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
    var enemy: Dictionary = mgr.combatants[1]
    enemy["off_balance_until"] = -1.0
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    var read_m: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    var settled_m: float = FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(enemy)
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_listing_w: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
                % [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, for **`thrust_feint`**
## vs **`thrust`**.


## Tier 4.2: same as **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, for **`thrust_feint`**
## vs **`thrust`**.
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.recompute_zoc_and_distance()
    var enemy: Dictionary = mgr.combatants[1]
    enemy["guard"] = 0.0
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["off_balance_until"] = -1.0
    var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
    var read_m: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "thrust_feint"
    )
    var settled_m: float = FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(enemy)
    var w_plain: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var want: float = w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
    if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_listing_w_thrust: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
                % [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
            )
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: feint listing mult - -  **`lerpf(1, AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, passive_readiness)`** vs
## low defender **`guard`** (SWORD 1v1).


## Tier 4.2: feint listing mult - -  **`lerpf(1, AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, passive_readiness)`** vs
## low defender **`guard`** (SWORD 1v1).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var enemy: Dictionary = mgr.combatants[1]
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.0
    enemy["off_balance_until"] = -1.0
    var w_plain_lo: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_lo: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_m_lo: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    var settled_m_lo: float = FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(enemy)
    var want_lo: float = w_plain_lo * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_lo * settled_m_lo
    if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
                % [want_lo, w_feint_lo, w_plain_lo]
            )
        )
    enemy["guard"] = 1.0
    var w_plain_hi: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_hi: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_m_hi: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "oberhau_feint"
    )
    var stance_m_hi: float = CombatWeaponForm.mod(CombatantEntityAccess.form_str(mgr.combatants[0]), "ai_feint_listing")
    var settled_m_hi: float = 1.0
    if (
        not PassiveParryContext.is_off_balance(enemy)
        and CombatantEntityAccess.state_str(enemy) != CombatConstants.STATE_WIND_UP
    ):
        var readiness_check: float = PassiveParryContext.get_passive_parry_readiness(enemy)
        if readiness_check <= 0.75:
            settled_m_hi = (FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(enemy))
    var want_hi: float = (
        w_plain_hi * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_hi * settled_m_hi * stance_m_hi
    )
    if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f settled_m"
                + "=%.6f" % [want_hi, w_feint_hi, w_plain_hi, read_m_hi, stance_m_hi, settled_m_hi]
            )
        )
    if not is_equal_approx(w_plain_lo, w_plain_hi):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list: plain oberhau weight should not depend on defender guard lo=%.6f hi=%.6f"
                % [w_plain_lo, w_plain_hi]
            )
        )
    if w_feint_hi <= w_feint_lo + 0.0001:
        CombatRegressionHarness._fail(
            failures, "feint_read_list: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, for
## **`thrust`** / **`thrust_feint`** (stab **`contact_type`** on readiness lerp).


## Tier 4.2: same as **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, for
## **`thrust`** / **`thrust_feint`** (stab **`contact_type`** on readiness lerp).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var enemy: Dictionary = mgr.combatants[1]
    mgr.recompute_zoc_and_distance()
    var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.0
    enemy["off_balance_until"] = -1.0
    var w_plain_lo: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_lo: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_m_lo_t: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "thrust_feint"
    )
    var settled_m_lo_t: float = FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(
        enemy
    )
    var want_lo: float = (
        w_plain_lo * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_lo_t * settled_m_lo_t
    )
    if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list_thrust lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
                % [want_lo, w_feint_lo, w_plain_lo]
            )
        )
    enemy["guard"] = 1.0
    var w_plain_hi: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_hi: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    var read_m_hi_t: float = FeintTempoWindupListingTests._feint_listing_read_m_expect_for_move_on_target(
        enemy, p_id, "thrust_feint"
    )
    var stance_m_hi_t: float = CombatWeaponForm.mod(
        CombatantEntityAccess.form_str(mgr.combatants[0]), "ai_feint_listing"
    )
    var settled_m_hi_t: float = 1.0
    if (
        not PassiveParryContext.is_off_balance(enemy)
        and CombatantEntityAccess.state_str(enemy) != CombatConstants.STATE_WIND_UP
    ):
        var readiness_check: float = PassiveParryContext.get_passive_parry_readiness(enemy)
        if readiness_check <= 0.75:
            settled_m_hi_t = (FeintTempoWindupListingTests._feint_listing_defender_footwork_state_mult_for_target(
                enemy
            ))
    var want_hi: float = (
        w_plain_hi * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_hi_t * settled_m_hi_t * stance_m_hi_t
    )
    if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list_thrust hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f se"
                + "ttled_m=%.6f" % [want_hi, w_feint_hi, w_plain_hi, read_m_hi_t, stance_m_hi_t, settled_m_hi_t]
            )
        )
    if not is_equal_approx(w_plain_lo, w_plain_hi):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_read_list_thrust: plain thrust weight should not depend on defender guard lo=%.6f hi=%.6f"
                % [w_plain_lo, w_plain_hi]
            )
        )
    if w_feint_hi <= w_feint_lo + 0.0001:
        CombatRegressionHarness._fail(
            failures, "feint_read_list_thrust: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing  -  LONG **`distance_to[attacker]`** on defender damps readiness lerp vs MID
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG`**).


## Tier 4.2 footwork: feint listing  -  LONG **`distance_to[attacker]`** on defender damps readiness lerp vs MID
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG`**).
static func _run_feint_move_listing_spacing_long_dampens_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.55
    mgr.recompute_zoc_and_distance()
    var pr_def: float = DefenseChoiceResolver.defender_feint_listing_pr_def(
        enemy, p_id, "oberhau_feint", {}, {}, true, false
    )
    var pr_long: float = clampf(
        pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
    )
    var read_m: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)
    var read_l: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long)
    var want_ratio: float = read_l / read_m
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
    var w_plain_m: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_m: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
    var w_plain_l: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_l: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_sp_long: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
                % [w_plain_m, w_plain_l]
            )
        )
    elif w_feint_l >= w_feint_m - 1e-9:
        CombatRegressionHarness._fail(
            failures, "feint_list_sp_long: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
        )
    else:
        var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
        if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
            CombatRegressionHarness._fail(
                failures,
                (
                    "feint_list_sp_long: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
                    % [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
                )
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing  -  CLOSE **`distance_to[attacker]`** on defender boosts readiness lerp vs MID
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE`**).


## Tier 4.2 footwork: feint listing  -  CLOSE **`distance_to[attacker]`** on defender boosts readiness lerp vs MID
## (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE`**).
static func _run_feint_move_listing_spacing_close_boosts_vs_mid(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    player["stance"] = CombatConstants.STANCE_BALANCED
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["guard"] = 0.55
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
                "feint_list_sp_close: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
                % [w_plain_m, w_plain_c]
            )
        )
    elif w_feint_c <= w_feint_m + 1e-9:
        CombatRegressionHarness._fail(
            failures, "feint_list_sp_close: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
        )
    else:
        var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
        if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
            CombatRegressionHarness._fail(
                failures,
                (
                    "feint_list_sp_close: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
                    % [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
                )
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing  -  LONG damps vs MID when defender **`STATE_RECOVERING`**
## (**`READINESS_BY_CAUSE`**, not **`guard`**); same **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`** as WAITING.


## Tier 4.2 footwork: feint listing  -  LONG damps vs MID when defender **`STATE_RECOVERING`**
## (**`READINESS_BY_CAUSE`**, not **`guard`**); same **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`** as WAITING.
static func _run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(
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
    var pr_long: float = clampf(
        pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
    )
    var read_m: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)
    var read_l: float = lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long)
    var want_ratio: float = read_l / read_m
    var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
    var w_plain_m: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_m: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    CombatantEntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
    var w_plain_l: float = CombatAIActionPicker._get_action_weight(a_plain, p_id, mgr, true)
    var w_feint_l: float = CombatAIActionPicker._get_action_weight(a_feint, p_id, mgr, true)
    if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
        CombatRegressionHarness._fail(
            failures,
            (
                "feint_list_sp_long_recov: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
                % [w_plain_m, w_plain_l]
            )
        )
    elif w_feint_l >= w_feint_m - 1e-9:
        CombatRegressionHarness._fail(
            failures, "feint_list_sp_long_recov: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
        )
    else:
        var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
        if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
            CombatRegressionHarness._fail(
                failures,
                (
                    "feint_list_sp_long_recov: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
                    % [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
                )
            )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)

## Tier 4.2 footwork: feint listing  -  CLOSE boosts vs MID when defender **`STATE_RECOVERING`**; same spacing mults as
## WAITING harness.
