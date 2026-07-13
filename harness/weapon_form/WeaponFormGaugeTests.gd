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


## WF-T2 suite: mod bands + counter cap + auto-switch thresholds  -  single Phase 0 maintain entry.
static func _run_weapon_form_wf_t2_suite(failures: PackedStringArray) -> void:
    WeaponFormGaugeTests._run_weapon_form_wf_t2_thresholds_locked(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_mod_identity_bands(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_counter_mult_cap(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_duel_wall_recovery_gate(failures)
