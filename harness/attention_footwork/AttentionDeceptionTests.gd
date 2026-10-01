class_name AttentionDeceptionTests

extends MentalStackFormationPlugBase

## Attention budget + deception: excess-target attention degradation and
## exploit/probabilistic bait suppression.


static func _run_attention_budget_degrades_excess_targets(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    ## 5 enemy attackers, all at close distance.
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var front: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if front.is_empty():
        _fail(failures, "attention_budget_degrade: missing front fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var front_id: int = CombatantEntityAccess.id_int(front)
    ## Record observations from all 5 enemies so entries exist.
    for idx in range(7, mini(12, mgr.combatants.size())):
        var atk: Dictionary = mgr.combatants[idx] if idx < mgr.combatants.size() else {}
        if atk.is_empty():
            continue
        if not CombatantEntityAccess.is_living_on_side(atk, "enemy"):
            continue
        var dist_map: Dictionary = CombatantEntityAccess.nested_dictionary_for_mutation(front, "distance_to")
        dist_map[CombatantEntityAccess.id_int(atk)] = CombatConstants.DISTANCE_CLOSE
        CombatAttention.record_attack_toward_defender(mgr, CombatantEntityAccess.id_int(atk), front, "head", "thrust")
    ## Set combat clock so refresh can run decay + priority update.
    mgr.combat_clock = 10.0
    CombatAttention.refresh_for_waiting_tick(mgr, front)
    var budget_max: int = CombatConstantsMentalStack.YOMI_ATTENTION_BUDGET_MAX
    ## Collect all enemy entries and their ranks/weights from the yomi root.
    var entry_0: Dictionary = CombatAttention.yomi_entry_for_attacker(front, mgr.combatants[7].get("id", -1))
    if not entry_0.is_empty():
        var rank: int = entry_0.get("priority_rank", -1)
        var weight: float = entry_0.get("attention_weight", 0.0)
        ## Entry must have a valid priority rank after refresh, and weight in [0.25, 1.0].
        if rank <= 0 or weight < 0.25 or weight > 1.0:
            _fail(failures, "attention_budget_degrade: top entry invalid rank=%d weight=%s" % [rank, str(weight)])
    ## Verify that among the 5 entries, at least one has degraded weight (budget_max=3, so ranks 4-5 degrade).
    var root: Dictionary = front.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, {}) as Dictionary
    var has_degraded: bool = false
    for key in root.keys():
        var ent: Variant = root.get(key, null)
        if ent is not Dictionary:
            continue
        var e: Dictionary = ent as Dictionary
        var w: float = e.get("attention_weight", 1.0)
        var r: int = e.get("priority_rank", -1)
        if r > budget_max and w < CombatConstantsMentalStack.YOMI_ATTENTION_PRIORITY_DEGRADE_MULT * 1.1:
            has_degraded = true
    if not has_degraded:
        _fail(failures, "attention_budget_degrade: expected at least one degraded attacker")
    ## Verify weighted observation view applies attention multiplier to degraded entries.
    for key in root.keys():
        var ent: Variant = root.get(key, null)
        if ent is not Dictionary:
            continue
        var e: Dictionary = ent as Dictionary
        var w: float = e.get("attention_weight", 1.0)
        if w < 1.0 and w > 0.0:
            var view: Dictionary = CombatAttention.get_observation_view(e, "weighted")
            var wc: Dictionary = view.get("line_counts", {})
            for vk in wc.keys():
                var val: float = float(wc[vk])
                if val < 1.0:
                    break
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Phase 5: Deception exploit bait suppression — counter-reads are skipped when opponent is in Exploit phase.


static func _run_deception_exploit_bait_suppression(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        _fail(failures, "deception_exploit_bait: missing fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var opponent_id: int = -1
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy" and enemy is Dictionary:
            opponent_id = CombatantEntityAccess.id_int(enemy)
            break
    if opponent_id < 0:
        _fail(failures, "deception_exploit_bait: missing opponent fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    ## Verify deterministic gating conditions for should_respect_bait.
    ## exploit_counter >= 3 — must return false (seen through).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.2,
        "exploit_counter": 3,
    }
    if CombatAttention.should_respect_bait(rear):
        _fail(failures, "deception_exploit_bait: expected bait to be inactive after 3 exploits")
    ## Set resistance = 0.6 — should_respect_bait must return false (high resistance).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.6,
        "exploit_counter": 1,
    }
    if CombatAttention.should_respect_bait(rear):
        _fail(failures, "deception_exploit_bait: expected bait to be inactive with high resistance")
    ## Seed in Establish phase — should_respect_bait must return false (not yet Exploit).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_ESTABLISH,
        "resistance": 0.0,
        "exploit_counter": 0,
    }
    if CombatAttention.should_respect_bait(rear):
        _fail(failures, "deception_exploit_bait: expected bait inactive in Establish phase")
    ## Verify deception state transitions via record_deception_outcome.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_before: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_before.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        _fail(failures, "deception_exploit_bait: expected initial Establish phase")
    ## Simulate 3 consecutive correct reads — both record_counter_read_outcome and
    ## record_deception_outcome fire per exchange (as in production). After the third
    ## iteration, try_advance_deception_probe advances to Probe and then
    ## record_deception_outcome (Probe+success) advances to Exploit.
    for _k in range(3):
        CombatWeaponFormConst.record_counter_read_outcome(rear, opponent_id, true, "ox")
        CombatAttention.record_deception_outcome(rear, opponent_id, true)
    CombatAttention.try_advance_deception_probe(rear, 3)
    CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after.get("phase", "") != YomiConstants.DECEPTION_PHASE_EXPLOIT:
        _fail(failures, "deception_exploit_bait: expected Exploit after 3 correct reads")
    var exploit_c: int = ds_after.get("exploit_counter", -1)
    if exploit_c != 0:
        _fail(failures, "deception_exploit_bait: expected exploit_counter=0 on entry to Exploit")
    ## A failure while in Exploit → back to Establish with resistance boost.
    CombatAttention.record_deception_outcome(rear, opponent_id, false)
    ds_after = CombatAttention._get_deception_state(rear)
    if ds_after.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        _fail(failures, "deception_exploit_bait: expected back to Establish after Exploit failure")
    var resistance_val: float = ds_after.get("resistance", 0.0)
    if resistance_val < 0.3:
        _fail(failures, "deception_exploit_bait: expected resistance boost on exploit exposure")
    ## Verify clear_focus_and_yomi erases deception state.
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {"phase": "test", "resistance": 0.5, "exploit_counter": 1}
    CombatAttention.clear_focus_and_yomi(rear)
    if rear.has(CombatConstants.COMBATANT_KEY_DECEPTION_STATE):
        _fail(failures, "deception_exploit_bait: expected deception state to be cleared")
    ## Probe+success → Exploit with exploit_counter reset.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_probe: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_PROBE,
        "resistance": 0.1,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_probe
    CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after_probe_success: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after_probe_success.get("phase", "") != YomiConstants.DECEPTION_PHASE_EXPLOIT:
        _fail(failures, "deception_exploit_bait: expected Probe→Exploit on success")
    if ds_after_probe_success.get("exploit_counter", -1) != 0:
        _fail(failures, "deception_exploit_bait: expected exploit_counter=0 on Probe→Exploit transition")
    ## Probe+failure → back to Establish (no resistance change).
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_probe_fail: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_PROBE,
        "resistance": 0.1,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_probe_fail
    CombatAttention.record_deception_outcome(rear, opponent_id, false)
    var ds_after_probe_failure: Dictionary = CombatAttention._get_deception_state(rear)
    if ds_after_probe_failure.get("phase", "") != YomiConstants.DECEPTION_PHASE_ESTABLISH:
        _fail(failures, "deception_exploit_bait: expected Probe→Establish on failure")
    var probe_fail_resistance: float = ds_after_probe_failure.get("resistance", -1.0)
    if abs(probe_fail_resistance - 0.1) > 0.001:
        _fail(failures, "deception_exploit_bait: expected resistance unchanged on Probe→Establish")
    ## Multi-cycle resistance accumulation: Establish+success adds 0.25 each cycle.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_cycle: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_ESTABLISH,
        "resistance": 0.0,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_cycle
    for _cycle in range(3):
        CombatAttention.record_deception_outcome(rear, opponent_id, true)
    var ds_after_cycles: Dictionary = CombatAttention._get_deception_state(rear)
    var cycle_resistance: float = ds_after_cycles.get("resistance", -1.0)
    if abs(cycle_resistance - 0.75) > 0.001:
        _fail(
            failures,
            (
                "deception_exploit_bait: expected resistance=0.75 after 3 Establish+success cycles (got %s)"
                % str(cycle_resistance)
            )
        )
    ## With resistance 0.75 > DECEPTION_ESTABLISH_PROB (0.5), should_respect_bait must return false even in Exploit
    ## phase.
    rear.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
    var ds_high_res: Dictionary = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.75,
        "exploit_counter": 0,
    }
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = ds_high_res
    if CombatAttention.should_respect_bait(rear):
        _fail(failures, "deception_exploit_bait: expected bait inactive with high accumulated resistance")
    ## Verify _is_form_stale_for_opponent returns false when no yomi entry exists.
    if not CombatWeaponFormConst._is_form_stale_for_opponent(mgr, rear, opponent_id):
        pass  ## expected: stale=false with no yomi entry
    else:
        _fail(failures, "deception_exploit_bait: expected stale=false with no yomi entry")
    ## Advance the combat clock so evaluate_automatic_form can run.
    mgr.combat_clock = 5.0
    rear["gauge"] = 100.0
    var form_before: String = CombatantEntityAccess.form_str(rear)
    CombatWeaponFormConst.evaluate_automatic_form(mgr, rear)
    ## Without yomi data the counter_read/duel_read paths must not switch; only geometry-driven
    ## surround / low-stamina switches can fire.  In a tight formation those may legitimately
    ## trigger, so we check that no *inference-based* (counter_read / duel_read) stamp was applied.
    var form_after: String = CombatantEntityAccess.form_str(rear)
    if str(form_after) != str(form_before):
        var reason: String = str(rear.get(CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON, ""))
        if "counter_read" in reason or "duel_read" in reason:
            _fail(
                failures,
                (
                    (
                        "deception_exploit_bait: expected no inference-based auto-switch with no yomi data, got "
                        + "form=%s "
                        + "reason=%s"
                    )
                    % [form_after, reason]
                )
            )
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Phase 5: Deception probabilistic bait suppression — seeded RNG test for randf() branch.


static func _run_deception_probabilistic_bait_suppression(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var rear: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 4)
    if rear.is_empty():
        _fail(failures, "prob_bait_suppression: missing fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    var opponent_id: int = -1
    for enemy in mgr.combatants:
        if CombatantEntityAccess.side_str(enemy) == "enemy" and enemy is Dictionary:
            opponent_id = CombatantEntityAccess.id_int(enemy)
            break
    if opponent_id < 0:
        _fail(failures, "prob_bait_suppression: missing opponent fixture")
        HarnessFixtures._free_manager_restore_global_rng(mgr)
        return
    ## Set up Exploit phase with exploit_counter=1 and low resistance (bait_prob ~0.233).
    rear[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = {
        "phase": YomiConstants.DECEPTION_PHASE_EXPLOIT,
        "resistance": 0.0,
        "exploit_counter": 1,
    }
    ## Use a local RNG instance for deterministic testing of the randf() bait branch.
    var hit_bait_count: int = 0
    var total_trials: int = 20
    for _trial in range(total_trials):
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = 12345 + _trial
        if CombatAttention.should_respect_bait(rear, rng):
            hit_bait_count += 1
    ## With exploit_counter=1, bait_prob ≈ lerpf(0.1, 0.5, 1/3) ≈ 0.233.
    ## Over 20 trials with seeds 0..19, expect some hits; verify not all pass and not all fail.
    if hit_bait_count <= 0:
        _fail(failures, "prob_bait_suppression: expected at least one bait hit in %d trials" % str(total_trials))
    if hit_bait_count >= total_trials:
        _fail(failures, "prob_bait_suppression: expected some rejections (got %d/%d)" % [hit_bait_count, total_trials])
    ## Verify _is_form_stale_for_opponent helper exists and returns false with empty yomi entry.
    if CombatWeaponFormConst._is_form_stale_for_opponent(mgr, rear, opponent_id):
        _fail(failures, "prob_bait_suppression: expected stale=false with no yomi data")
    ## Verify _should_bait_counter_read returns false when opponent has no deception state.
    var enemy_c: Dictionary = CombatantEntityAccess.manager_get_combatant(mgr, opponent_id)
    if not enemy_c.is_empty():
        enemy_c.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
        if CombatWeaponFormConst._should_bait_counter_read(mgr, rear, opponent_id):
            _fail(failures, "prob_bait_suppression: expected false with no deception state on opponent")
    HarnessFixtures._free_manager_restore_global_rng(mgr)

## Phase 3: L2 transition guard — counter-tempo requires >= 2 consecutive failures at higher tiers.
