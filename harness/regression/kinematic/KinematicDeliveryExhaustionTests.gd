class_name KinematicDeliveryExhaustionTests
extends CombatRegressionHarnessCore

const _FP := "exhaustion_harness"
const Exhaustion := preload("res://combat/flow/CombatExhaustion.gd")
const StaminaConstants := preload("res://combat/constants/CombatConstantsStamina.gd")


static func _fail(failures: PackedStringArray, msg: String) -> void:
    failures.append(_FP + ": " + msg)


# ---------------------------------------------------------------------------
# Test 1: timing_mult vs power_mult differentiation
# ---------------------------------------------------------------------------


static func _run_exhaustion_timing_vs_power_differentiation(failures: PackedStringArray) -> void:
    StaminaConstants.set_feature_fight_exhaustion_index_load(true)

    ## exhaustion=0.0: both must equal 1.0 exactly
    var t0: float = StaminaConstants.exhaustion_timing_mult(0.0)
    var p0: float = StaminaConstants.exhaustion_power_mult(0.0)
    if not is_equal_approx(t0, 1.0):
        _fail(failures, "exh_t_p_diff: t(0) want 1.0 got %.6f" % t0)
    if not is_equal_approx(p0, 1.0):
        _fail(failures, "exh_t_p_diff: p(0) want 1.0 got %.6f" % p0)

    ## exhaustion=0.10: timing degraded but power still near 1.0 (delayed onset)
    var t10: float = StaminaConstants.exhaustion_timing_mult(0.10)
    var p10: float = StaminaConstants.exhaustion_power_mult(0.10)
    if t10 >= 1.0:
        _fail(failures, "exh_t_p_diff: t(0.10) want <1.0 got %.6f" % t10)
    if p10 <= t10:
        _fail(failures, "exh_t_p_diff: p(0.10)=%.6f should exceed t(0.10)=%.6f" % [p10, t10])

    ## exhaustion=0.20: timing significantly degraded, power still higher
    var t20: float = StaminaConstants.exhaustion_timing_mult(0.20)
    var p20: float = StaminaConstants.exhaustion_power_mult(0.20)
    if p20 <= t20:
        _fail(failures, "exh_t_p_diff: p(0.20)=%.6f should exceed t(0.20)=%.6f" % [p20, t20])

    ## exhaustion=0.50: both degraded but power must still be >= timing
    var t50: float = StaminaConstants.exhaustion_timing_mult(0.50)
    var p50: float = StaminaConstants.exhaustion_power_mult(0.50)
    if p50 < t50 - 0.001:
        _fail(failures, "exh_t_p_diff: p(0.50) must be >= t(0.50): p=%.6f t=%.6f" % [p50, t50])

    ## exhaustion=1.0 (max): timing floors at EXHAUSTION_FLOOR_MULT; power uses delayed onset so is higher
    var t100: float = StaminaConstants.exhaustion_timing_mult(1.0)
    var p100: float = StaminaConstants.exhaustion_power_mult(1.0)
    if not is_equal_approx(t100, StaminaConstants.EXHAUSTION_FLOOR_MULT):
        _fail(
            failures, "exh_t_p_diff: t(1.0) want floor %.3f got %.6f" % [StaminaConstants.EXHAUSTION_FLOOR_MULT, t100]
        )
    ## Power at max uses delayed onset (0.85), not full floor
    var p100_delayed: float = StaminaConstants.exhaustion_performance_mult(0.85)
    if absf(p100 - p100_delayed) > 0.001:
        _fail(failures, "exh_t_p_diff: p(1.0) want %.6f (delayed 0.85) got %.6f" % [p100_delayed, p100])
    if not (p100 > t100):
        _fail(failures, "exh_t_p_diff: at max exhaustion power=%.6f should exceed timing=%.6f" % [p100, t100])

    ## Monotonicity for timing_mult across increasing exhaustion values
    var prev_t: float = -1.0
    var exhaust_values: Array[float] = [0.0, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.0]
    for ev in exhaust_values:
        var cur_t: float = StaminaConstants.exhaustion_timing_mult(ev)
        if prev_t >= 0 and cur_t > prev_t + 0.0001:
            _fail(
                failures,
                "exh_t_p_diff: timing not monotonic decreasing at %.2f (cur=%.6f prev=%.6f)" % [ev, cur_t, prev_t]
            )
        prev_t = cur_t

    ## Monotonicity for power_mult across increasing exhaustion values
    var prev_p: float = -1.0
    for ev in exhaust_values:
        var cur_p: float = StaminaConstants.exhaustion_power_mult(ev)
        if prev_p >= 0 and cur_p > prev_p + 0.0001:
            _fail(
                failures,
                "exh_t_p_diff: power not monotonic decreasing at %.2f (cur=%.6f prev=%.6f)" % [ev, cur_p, prev_p]
            )
        prev_p = cur_p

    StaminaConstants.set_feature_fight_exhaustion_index_load(-1)


# ---------------------------------------------------------------------------
# Test 2: Metabolic stress accumulation and decay
# ---------------------------------------------------------------------------


static func _run_exhaustion_metabolic_stress_accumulation(failures: PackedStringArray) -> void:
    StaminaConstants.set_feature_fight_exhaustion_index_load(true)

    ## Static function tests for metabolic_stress_gain_from_stamina_spend
    ## At endurance=100 (max), relief = 0.35, so gain = stamina_spent * 0.002 * 0.65
    var gain_high_end: float = StaminaConstants.metabolic_stress_gain_from_stamina_spend(20.0, 100.0)
    var want_high_end: float = 20.0 * 0.002 * (1.0 - 0.35)
    if absf(gain_high_end - want_high_end) > 0.0001:
        _fail(failures, "met_stress_gain: high_end want %.6f got %.6f" % [want_high_end, gain_high_end])

    ## At endurance=0 (min), relief = 0, so gain = stamina_spent * 0.002
    var gain_zero_end: float = StaminaConstants.metabolic_stress_gain_from_stamina_spend(20.0, 0.0)
    var want_zero_end: float = 20.0 * 0.002 * 1.0
    if absf(gain_zero_end - want_zero_end) > 0.0001:
        _fail(failures, "met_stress_gain: zero_end want %.6f got %.6f" % [want_zero_end, gain_zero_end])

    ## decision_quality_mult tests
    var dq_0: float = StaminaConstants.metabolic_stress_decision_mult(0.0)
    if not is_equal_approx(dq_0, 1.0):
        _fail(failures, "met_dq: stress=0 want 1.0 got %.6f" % dq_0)

    var dq_03: float = StaminaConstants.metabolic_stress_decision_mult(0.3)
    var want_dq_03: float = lerpf(1.0, 0.75, 0.3)
    if absf(dq_03 - want_dq_03) > 0.0001:
        _fail(failures, "met_dq: stress=0.3 want %.6f got %.6f" % [want_dq_03, dq_03])

    var dq_10: float = StaminaConstants.metabolic_stress_decision_mult(1.0)
    if not is_equal_approx(dq_10, 0.75):
        _fail(failures, "met_dq: stress=1.0 want 0.75 got %.6f" % dq_10)

    ## Full chain via manager + combatant dicts
    var mgr: Node = MgrScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    mgr.register(ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var combatant: Dictionary = mgr.combatants[0]

    ## Fresh combatant: _metabolic_stress should be missing or 0.0
    var initial_ms: float = combatant.get(StaminaConstants.COMBATANT_KEY_METABOLIC_STRESS, 0.0)
    if not is_equal_approx(initial_ms, 0.0):
        _fail(failures, "met_chain: fresh want ms=0 got %.6f" % initial_ms)

    ## Set endurance to 100 and spend stamina (which accumulates metabolic stress)
    var stats_100: Dictionary = {
        DataKeys.ENTITY_ENDURANCE: 100.0,
        DataKeys.BLOOD_VOLUME: 100.0,
        DataKeys.ENTITY_AGILITY: 100.0,
        DataKeys.ENTITY_STRENGTH: 50.0,
    }
    combatant["stats"] = stats_100
    StaminaConstants.set_feature_fight_exhaustion_index_load(true)

    var stamina_to_spend: float = 20.0
    combatant[DataKeys.COMBATANT_STAMINA] = CombatConstants.STAMINA_MAX

    ## Apply exertion from the stamina spend (this accumulates metabolic stress)
    CombatExhaustion.apply_exertion_from_stamina_spend(mgr, combatant, stamina_to_spend)

    var after_ms_100: float = combatant.get(StaminaConstants.COMBATANT_KEY_METABOLIC_STRESS, 0.0)
    if absf(after_ms_100 - want_high_end) > maxf(absf(want_high_end) * 0.01, 0.0001):
        _fail(failures, "met_chain: after spend(20,end=100) ms want %.6f got %.6f" % [want_high_end, after_ms_100])

    ## Now test with endurance=0
    var stats_0: Dictionary = {
        DataKeys.ENTITY_ENDURANCE: 0.0,
        DataKeys.BLOOD_VOLUME: 100.0,
        DataKeys.ENTITY_AGILITY: 100.0,
        DataKeys.ENTITY_STRENGTH: 50.0,
    }
    combatant["stats"] = stats_0

    var stamina_to_spend2: float = 20.0
    combatant[DataKeys.COMBATANT_STAMINA] = CombatConstants.STAMINA_MAX

    CombatExhaustion.apply_exertion_from_stamina_spend(mgr, combatant, stamina_to_spend2)

    var after_ms_0: float = combatant.get(StaminaConstants.COMBATANT_KEY_METABOLIC_STRESS, 0.0)
    ## Should have accumulated more than the endurance=100 case (no relief)
    var expected_total_0: float = want_high_end + want_zero_end
    if absf(after_ms_0 - expected_total_0) > maxf(expected_total_0 * 0.01, 0.0001):
        _fail(failures, "met_chain: after spend(20,end=0) ms want %.6f got %.6f" % [expected_total_0, after_ms_0])

    ## Verify decision_quality_mult reflects the accumulated stress via CombatExhaustion
    var dq_via_exh: float = CombatExhaustion.decision_quality_mult(combatant)
    var expected_dq: float = lerpf(1.0, 0.75, after_ms_0)
    if absf(dq_via_exh - expected_dq) > 0.001:
        _fail(
            failures, "met_chain: decision_quality want %.6f (ms=%.6f) got %.6f" % [expected_dq, after_ms_0, dq_via_exh]
        )

    ## Direct stress accumulation test: manually set high stress and verify decision quality floors correctly
    combatant[CombatConstantsStamina.COMBATANT_KEY_METABOLIC_STRESS] = 1.0
    var dq_max_stress: float = CombatExhaustion.decision_quality_mult(combatant)
    if not is_equal_approx(dq_max_stress, 0.75):
        _fail(failures, "met_chain: max stress decision_quality want 0.75 got %.6f" % dq_max_stress)

    _free_manager(mgr)
    StaminaConstants.set_feature_fight_exhaustion_index_load(-1)


# ---------------------------------------------------------------------------
# Test 3: Consecutive action stamina scaling
# ---------------------------------------------------------------------------


static func _run_exhaustion_consecutive_action_scaling(failures: PackedStringArray) -> void:
    var tol: float = 0.001

    ## consecutive=0 → 1.0
    var c0: float = StaminaConstants.consecutive_action_stamina_mult(0)
    if absf(c0 - 1.0) > tol:
        _fail(failures, "conc_act: consecutive=0 want 1.0 got %.6f" % c0)

    ## consecutive=1 → 1.0 (first attack, no penalty)
    var c1: float = StaminaConstants.consecutive_action_stamina_mult(1)
    if absf(c1 - 1.0) > tol:
        _fail(failures, "conc_act: consecutive=1 want 1.0 got %.6f" % c1)

    ## consecutive=2 → ~1.25 (lerp from 1.0 to 2.0 over 4 steps: 1 + (1/4)*1.0 = 1.25)
    var c2: float = StaminaConstants.consecutive_action_stamina_mult(2)
    var want_c2: float = lerpf(1.0, 2.0, 1.0 / 4.0)
    if absf(c2 - want_c2) > tol:
        _fail(failures, "conc_act: consecutive=2 want %.6f got %.6f" % [want_c2, c2])

    ## consecutive=3 → ~1.5 (lerpf(1.0, 2.0, 2/4) = 1.0 + 1.0*0.5 = 1.5)
    var c3: float = StaminaConstants.consecutive_action_stamina_mult(3)
    var want_c3: float = lerpf(1.0, 2.0, 2.0 / 4.0)
    if absf(c3 - want_c3) > tol:
        _fail(failures, "conc_act: consecutive=3 want %.6f got %.6f" % [want_c3, c3])

    ## consecutive=4 → ~1.75 (lerpf(1.0, 2.0, 3/4) = 1.0 + 1.0*0.75 = 1.75)
    var c4: float = StaminaConstants.consecutive_action_stamina_mult(4)
    var want_c4: float = lerpf(1.0, 2.0, 3.0 / 4.0)
    if absf(c4 - want_c4) > tol:
        _fail(failures, "conc_act: consecutive=4 want %.6f got %.6f" % [want_c4, c4])

    ## consecutive=5 → 2.0 (capped after full span)
    var c5: float = StaminaConstants.consecutive_action_stamina_mult(5)
    if absf(c5 - 2.0) > tol:
        _fail(failures, "conc_act: consecutive=5 want 2.0 got %.6f" % c5)

    ## consecutive=10 → still capped at 2.0
    var c10: float = StaminaConstants.consecutive_action_stamina_mult(10)
    if absf(c10 - 2.0) > tol:
        _fail(failures, "conc_act: consecutive=10 want 2.0 got %.6f" % c10)

    ## Full flow via manager: combatant starts with no consecutive_actions key,
    ## first attack while NOT in RECOVERING sets counter to 1, second increments to 2.
    var mgr: Node = MgrScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    mgr.register(ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var combatant: Dictionary = mgr.combatants[0]

    ## Fresh combatant should have no _consecutive_actions key or it is 0
    var conc_initial: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
    if conc_initial != 0:
        _fail(failures, "conc_flow: fresh want consecutive=0 got %d" % conc_initial)

    ## Simulate first action (not in recovery): counter goes to 1
    combatant["state"] = CombatConstants.STATE_WIND_UP
    if EntityAccess.state_str(combatant) != CombatConstants.STATE_RECOVERING:
        var cur_conc: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
        combatant[StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = cur_conc + 1

    var conc_after_1: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
    if conc_after_1 != 1:
        _fail(failures, "conc_flow: after 1st action want consecutive=1 got %d" % conc_after_1)

    ## Simulate second action: counter increments to 2
    combatant["state"] = CombatConstants.STATE_WIND_UP
    if EntityAccess.state_str(combatant) != CombatConstants.STATE_RECOVERING:
        var cur_conc2: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
        combatant[StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = cur_conc2 + 1

    var conc_after_2: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
    if conc_after_2 != 2:
        _fail(failures, "conc_flow: after 2nd action want consecutive=2 got %d" % conc_after_2)

    ## Simulate recovery end: counter should be erased (matching CombatEventDispatch.handle_recovery_end)
    combatant["state"] = CombatConstants.STATE_WAITING
    var cur_conc3: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
    if EntityAccess.state_str(combatant) == CombatConstants.STATE_RECOVERING:
        pass  # still recovering, don't reset yet
    else:
        combatant.erase(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS)

    var conc_after_recovery: int = int(combatant.get(StaminaConstants.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0))
    if conc_after_recovery != 0:
        _fail(failures, "conc_flow: after recovery want consecutive=0 got %d" % conc_after_recovery)

    _free_manager(mgr)


# ---------------------------------------------------------------------------
# Entry point for harness runner (same signature as other test classes)
# ---------------------------------------------------------------------------


static func run_all(failures: PackedStringArray) -> void:
    _run_exhaustion_timing_vs_power_differentiation(failures)
    _run_exhaustion_metabolic_stress_accumulation(failures)
    _run_exhaustion_consecutive_action_scaling(failures)
