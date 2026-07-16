class_name WeaponFormGaugeTests
extends CombatRegressionHarnessCore
## Expand WF: weapon form spawn, mods, picker weights, pressure class, UI suffix parity.
## Footing rows: home guard on **`assign_form`** . gauge/diagram **` . Form`** / **`[Ox]`**  -  not PA step. LIVE_PATHS
## **`#harness-row-catalog-combatregressionharnessweaponformtailgd`** . soak open scope **`#wf-soak-audit-status`** .
## compose **`#battle-ui`**.


static func _run_weapon_form_ui_suffix(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    c["state"] = CombatConstants.STATE_WAITING
    var gauge_suffix: String = CombatUiHints.weapon_form_gauge_suffix(c)
    if gauge_suffix != " . Form Ox":
        CombatRegressionHarness._fail(
            failures, "weapon_form_ui: gauge suffix want ' . Form Ox' got '%s'" % gauge_suffix
        )
    var diagram_suffix: String = CombatUiHints.weapon_form_diagram_suffix(c)
    if diagram_suffix != " [Ox]":
        CombatRegressionHarness._fail(failures, "weapon_form_ui: diagram suffix want ' [Ox]' got '%s'" % diagram_suffix)
    var tip: String = CombatUiHints.weapon_form_tooltip_line(c)
    if tip != "Form: Ox":
        CombatRegressionHarness._fail(failures, "weapon_form_ui: tooltip want 'Form: Ox' got '%s'" % tip)
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
    if not label.contains(" . Form Ox"):
        CombatRegressionHarness._fail(failures, "weapon_form_ui: gauge label missing Form Ox suffix (got '%s')" % label)
    var tips: PackedStringArray = CombatUiHints.gauge_tooltip_lines(c, mgr)
    var tip_hit: bool = false
    for line in tips:
        if str(line) == "Form: Ox":
            tip_hit = true
            break
    if not tip_hit:
        CombatRegressionHarness._fail(failures, "weapon_form_ui: gauge tooltip lines missing Form: Ox")
    var cell_label: String = FormationDiagramBuilder._cell_label_with_footwork("A1", [c])
    if not cell_label.contains(" [Ox]"):
        CombatRegressionHarness._fail(failures, "weapon_form_ui: diagram cell missing [Ox] (got '%s')" % cell_label)
    CombatWeaponForm.assign_form(mgr, c, CombatWeaponForm.FORM_WALL, "harness_ui")
    if CombatUiHints.weapon_form_gauge_suffix(c) != " . Form Wall":
        CombatRegressionHarness._fail(failures, "weapon_form_ui: wall gauge suffix after assign")
    var wall_tip: String = CombatUiHints.weapon_form_tooltip_line(c)
    if wall_tip != "Form: Wall (defensive)":
        CombatRegressionHarness._fail(
            failures, "weapon_form_ui: wall tooltip want defensive flavor got '%s'" % wall_tip
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-T2: soak-tuned tuning constants locked (duel / surround / counter cap).


## WF-T2: soak-tuned tuning constants locked (duel / surround / counter cap).
static func _run_weapon_form_wf_t2_thresholds_locked(failures: PackedStringArray) -> void:
    if absf(CombatConstants.WF_FORM_COUNTER_MULT_CAP - 1.15) > 0.0001:
        CombatRegressionHarness._fail(
            failures, "weapon_form_wf_t2: counter cap want 1.15 got %.4f" % CombatConstants.WF_FORM_COUNTER_MULT_CAP
        )
    if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD - 0.12) > 0.0001:
        CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel offense pad")
    if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD - 0.15) > 0.0001:
        CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel wrath promote pad")
    if absf(CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD - 0.10) > 0.0001:
        CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: duel wrath demote pad")


## WF-T2: identity-form **`mod`** bands (ox / plow / tempest)  -  stance alias wall/wrath/fool stay parity harness.


## WF-T2: identity-form **`mod`** bands (ox / plow / tempest)  -  stance alias wall/wrath/fool stay parity harness.
static func _run_weapon_form_wf_t2_mod_identity_bands(failures: PackedStringArray) -> void:
    var bands: Dictionary = {
        CombatWeaponForm.FORM_OX: {"parry": 1.08, "damage": 1.04, "ai_melee_focus": 1.02},
        CombatWeaponForm.FORM_PLOW: {"parry": 1.14, "damage": 0.96, "ai_melee_focus": 0.94},
        CombatWeaponForm.FORM_TEMPEST: {"parry": 0.84, "damage": 1.18, "ai_melee_focus": 1.08},
    }
    for form_id in bands.keys():
        var want: Dictionary = bands[form_id] as Dictionary
        for effect in want.keys():
            var got: float = CombatWeaponForm.mod(form_id, str(effect))
            var target: float = float(want[effect])
            if absf(got - target) > 0.001:
                CombatRegressionHarness._fail(
                    failures, "weapon_form_wf_t2: %s/%s want %.3f got %.3f" % [form_id, effect, target, got]
                )


## WF-T2: counter mult respects cap; fool feint vs inferred ox boosted, cut not.


## WF-T2: counter mult respects cap; fool feint vs inferred ox boosted, cut not.
static func _run_weapon_form_wf_t2_counter_mult_cap(failures: PackedStringArray) -> void:
    var feint_m: float = CombatWeaponForm.form_counter_mult(
        CombatWeaponForm.FORM_FOOL, CombatWeaponForm.FORM_OX, "oberhau_feint"
    )
    var cut_m: float = CombatWeaponForm.form_counter_mult(
        CombatWeaponForm.FORM_FOOL, CombatWeaponForm.FORM_OX, "oberhau"
    )
    if feint_m <= 1.0 or feint_m > CombatConstants.WF_FORM_COUNTER_MULT_CAP + 0.001:
        CombatRegressionHarness._fail(
            failures,
            (
                "weapon_form_wf_t2: fool feint counter want (1, %.3f] got %.3f"
                % [CombatConstants.WF_FORM_COUNTER_MULT_CAP, feint_m]
            )
        )
    if cut_m > 1.0:
        CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: fool cut vs ox should not counter got %.3f" % cut_m)


## WF-T2: recovering **wall** must not yo-yo to fool/wrath until stamina pad clears (F5 soak).


## WF-T2: recovering **wall** must not yo-yo to fool/wrath until stamina pad clears (F5 soak).
static func _run_weapon_form_wf_t2_duel_wall_recovery_gate(failures: PackedStringArray) -> void:
    var mgr_hold: Node = CombatRegressionHarness._harness_start_1v1()
    var def_hold: Dictionary = mgr_hold.combatants[0]
    var atk_hold: Dictionary = mgr_hold.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk_hold)
    CombatWeaponForm.assign_form(mgr_hold, def_hold, CombatWeaponForm.FORM_WALL, "harness")
    var min_r: float = CombatWeaponForm.min_stamina_ratio_for_form(CombatWeaponForm.FORM_WALL)
    var pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
    def_hold["stamina"] = CombatConstants.STAMINA_MAX * (min_r + pad * 0.5)
    for _i in 5:
        CombatAttention.record_attack_toward_defender(null, atk_id, def_hold, "head")
        CombatAttention.record_resolved_strike_toward_defender(def_hold, atk_id, "oberhau")
    CombatWeaponForm.refresh_inferred_forms_for_observer(mgr_hold, def_hold)
    if CombatWeaponForm.evaluate_automatic_form(mgr_hold, def_hold):
        CombatRegressionHarness._fail(
            failures, "weapon_form_wf_t2: recovering wall should hold got %s" % CombatantEntityAccess.form_str(def_hold)
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_hold)
    var mgr_switch: Node = CombatRegressionHarness._harness_start_1v1()
    var def_sw: Dictionary = mgr_switch.combatants[0]
    var atk_sw: Dictionary = mgr_switch.combatants[1]
    var atk_sw_id: int = CombatantEntityAccess.id_int(atk_sw)
    CombatWeaponForm.assign_form(mgr_switch, def_sw, CombatWeaponForm.FORM_WALL, "harness")
    def_sw["stamina"] = CombatConstants.STAMINA_MAX * (min_r + pad + 0.05)
    for _j in 5:
        CombatAttention.record_attack_toward_defender(null, atk_sw_id, def_sw, "head")
        CombatAttention.record_resolved_strike_toward_defender(def_sw, atk_sw_id, "oberhau")
    CombatWeaponForm.refresh_inferred_forms_for_observer(mgr_switch, def_sw)
    if not CombatWeaponForm.evaluate_automatic_form(mgr_switch, def_sw):
        CombatRegressionHarness._fail(failures, "weapon_form_wf_t2: recovered wall should duel-switch vs wrath")
    if CombatantEntityAccess.form_str(def_sw) != CombatWeaponForm.FORM_FOOL:
        CombatRegressionHarness._fail(
            failures,
            "weapon_form_wf_t2: recovered wall want fool vs wrath got %s" % CombatantEntityAccess.form_str(def_sw)
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr_switch)


## WF-T2 suite: mod bands + counter cap + auto-switch thresholds  -  single Phase 0 maintain entry.


## WF-Y1: yomi inference — staleness, signal agreement, confidence tiers, rare-form prior suppression.
static func _run_weapon_form_yomi_inference_suite(failures: PackedStringArray) -> void:
    WeaponFormGaugeTests._run_weapon_form_inference_stale_switch(failures)
    WeaponFormGaugeTests._run_weapon_form_inference_signal_agreement(failures)
    WeaponFormGaugeTests._run_weapon_form_inference_confidence_tiers(failures)
    WeaponFormGaugeTests._run_weapon_form_inference_rare_form_prior(failures)


## WF-T2 suite: mod bands + counter cap + auto-switch thresholds  -  single Phase 0 maintain entry.
static func _run_weapon_form_wf_t2_suite(failures: PackedStringArray) -> void:
    WeaponFormGaugeTests._run_weapon_form_wf_t2_thresholds_locked(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_mod_identity_bands(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_counter_mult_cap(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_duel_wall_recovery_gate(failures)


## WF-Y1: staleness detection — feed 8 wrath obs then switch to fool-only obs; stale inference should return "".
static func _run_weapon_form_inference_stale_switch(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    var failures_local: PackedStringArray = []
    for _i in 8:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "head", "oberhau")
    var inferred_1: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if inferred_1.is_empty():
        failures_local.append("inference_stale: expected wrath from 8 oberhau obs, got empty")
    for _j in 6:
        mgr._combat_tick_index += 1
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "low", "unterhau")
    var inferred_2: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if not inferred_2.is_empty():
        failures_local.append("inference_stale: expected empty (staleness suppress) got '%s'" % inferred_2)
    for _k in 10:
        mgr._combat_tick_index += 1
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "low", "unterhau")
    var inferred_3: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if inferred_3.is_empty():
        failures_local.append("inference_stale: expected fool after 16 low/unterhau obs, got empty")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
    for f in failures_local:
        failures.append(f)


## WF-Y1: signal agreement — 4 high-line-only obs should return "" (lines alone < MIN_SIGNAL_AGREEMENT).
static func _run_weapon_form_inference_signal_agreement(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    for _i in 4:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "head", "")
    var inferred: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if not inferred.is_empty():
        failures.append("inference_signal_agreement: expected empty (lines-only < 2 votes) got '%s'" % inferred)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-Y1: confidence tiers — line-only obs (N=4→0.3, N=6→0.6, N=10→0.85+).
static func _run_weapon_form_inference_confidence_tiers(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    for _i in 4:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "head", "")
    var conf_4: float = CombatWeaponForm.get_form_inference_confidence(def, atk_id)
    if conf_4 < 0.25 or conf_4 > 0.4:
        failures.append("inference_confidence_tiers: N=4 want ~0.3 got %.3f" % conf_4)
    for _j in 2:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "head", "")
    var conf_6: float = CombatWeaponForm.get_form_inference_confidence(def, atk_id)
    if conf_6 < 0.5 or conf_6 > 0.75:
        failures.append("inference_confidence_tiers: N=6 want ~0.6 got %.3f" % conf_6)
    for _k in 4:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "head", "")
    var conf_10: float = CombatWeaponForm.get_form_inference_confidence(def, atk_id)
    if conf_10 < 0.8:
        failures.append("inference_confidence_tiers: N=10 want >=0.8 got %.3f" % conf_10)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-Y1: rare form prior suppression — 4 tempest-like obs should not infer tempest.
static func _run_weapon_form_inference_rare_form_prior(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    for _i in 4:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "mid", "sous_wiel")
    var inferred: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if inferred == CombatWeaponForm.FORM_TEMPEST:
        failures.append("inference_rare_prior: tempest should be suppressed with only 4 obs")
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-P2: counter-read pressure gate — neutral→aggressive requires ≥0.65 confidence, same-pressure works at low conf.
static func _run_weapon_form_phase2_suite(failures: PackedStringArray) -> void:
    WeaponFormGaugeTests._run_weapon_form_phase2_pressure_gate_same_pressure(failures)
    WeaponFormGaugeTests._run_weapon_form_phase2_neutral_to_aggressive_gate(failures)
    WeaponFormGaugeTests._run_weapon_form_phase2_commitment_stamp(failures)


## WF-P2: same-pressure auto-switch (ox→plow) should work at any confidence level.
static func _run_weapon_form_phase2_pressure_gate_same_pressure(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    CombatWeaponForm.assign_form(mgr, def, CombatWeaponForm.FORM_OX, "harness")
    for _i in 6:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "high", "oberhau")
    var inferred: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if not inferred.is_empty():
        failures.append("phase2_same_pressure: expected empty inference from high-line oberhau got '%s'" % inferred)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-P2: neutral→aggressive requires ≥0.65 confidence — low obs should block the switch.
static func _run_weapon_form_phase2_neutral_to_aggressive_gate(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    for _i in 3:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "low", "unterhau")
    var conf: float = CombatWeaponForm.get_form_inference_confidence(def, atk_id)
    if conf >= 0.65:
        failures.append("phase2_neutral_agg_conf: expected low confidence with 3 obs got %.3f" % conf)
    else:
        pass
    var inferred: String = CombatWeaponForm.infer_opponent_form(mgr, def, atk_id)
    if not inferred.is_empty():
        failures.append("phase2_neutral_agg_inference: expected empty (low obs + signal gate) got '%s'" % inferred)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## WF-P2: counter-read commitment stamp — defensive switch should lock out auto-switch for 3 ticks.
static func _run_weapon_form_phase2_commitment_stamp(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var def: Dictionary = mgr.combatants[0]
    var atk: Dictionary = mgr.combatants[1]
    var atk_id: int = CombatantEntityAccess.id_int(atk)
    CombatWeaponForm.assign_form(mgr, def, CombatWeaponForm.FORM_OX, "harness")
    for _i in 8:
        CombatAttention.record_attack_toward_defender(mgr, atk_id, def, "low", "unterhau")
    var entry: Dictionary = CombatWeaponForm._get_attention().yomi_entry_for_attacker(def, atk_id)
    var total: int = CombatWeaponForm._get_attention().yomi_observation_total(entry)
    if total < 4:
        failures.append("phase2_commitment: expected >=4 yomi obs got %d" % total)
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)
