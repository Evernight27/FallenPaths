class_name Tier1EngagementTelemetryTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")
## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_engagement_classifier_multi_seed(failures: PackedStringArray) -> void:
    var rng := RandomNumberGenerator.new()
    for scenario_seed in 64:
        rng.seed = scenario_seed
        var pn: int = rng.randi_range(1, 8)
        var en: int = rng.randi_range(1, 8)
        var mgr: Node = CombatManager.new()
        for _i in pn:
            mgr.register(_new_entity("SWORD"), "player")
        for _j in en:
            mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({}, {})
        var snap: Dictionary = CombatEngagementMode.snapshot(mgr)
        var raw: String = str(snap.get("raw_mode", ""))
        if raw == CombatConstants.ENGAGEMENT_MODE_FORMATION:
            if not CombatEngagementMode.can_enter_formation_from_snapshot(snap):
                _fail(
                    failures,
                    "classifier_fuzz seed=%d: raw formation but can_enter false snap=%s" % [scenario_seed, str(snap)]
                )
        Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(
            failures, mgr, "classifier_fuzz seed=%d" % scenario_seed
        )
        var resolved: String = CombatEngagementMode.engagement_mode(mgr)
        var resolved_again: String = CombatEngagementMode.engagement_mode(mgr)
        if resolved_again != resolved:
            _fail(
                failures,
                (
                    "classifier_fuzz seed=%d: engagement_mode not idempotent %s vs %s"
                    % [scenario_seed, resolved, resolved_again]
                )
            )
        if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
            if not CombatEngagementMode.can_enter_formation_from_snapshot(snap):
                _fail(
                    failures,
                    (
                        "classifier_fuzz seed=%d: cold resolved formation but can_enter false snap=%s"
                        % [scenario_seed, str(snap)]
                    )
                )
        HarnessFixtures._free_manager(mgr)


## Tier 1.7 (P8): Option 2 active-count floor  -  if either side has fewer actives than formation minimum, raw mode is
## never `formation`.


## Tier 1.7 (P8): Option 2 active-count floor  -  if either side has fewer actives than formation minimum, raw mode is
## never `formation`.
static func _run_engagement_active_count_gate_exhaustive(failures: PackedStringArray) -> void:
    var min_act: int = int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
    for pn in range(1, 8):
        for en in range(1, 8):
            if pn >= min_act and en >= min_act:
                continue
            var mgr: Node = CombatManager.new()
            for _i in pn:
                mgr.register(_new_entity("SWORD"), "player")
            for _j in en:
                mgr.register(_new_entity("SWORD"), "enemy")
            mgr.start({}, {})
            var snap: Dictionary = CombatEngagementMode.snapshot(mgr)
            if str(snap.get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_FORMATION:
                _fail(
                    failures,
                    "active_gate: raw formation with active below min pn=%d en=%d snap=%s" % [pn, en, str(snap)]
                )
            var resolved: String = CombatEngagementMode.engagement_mode(mgr)
            if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
                _fail(
                    failures,
                    "active_gate: resolved formation with active below min pn=%d en=%d snap=%s" % [pn, en, str(snap)]
                )
            HarnessFixtures._free_manager(mgr)


## Tier 1.7 (P8): second `start()` on same manager must not keep prior `formation` hysteresis (regression guard for
## `clear_resolved_mode_cache`).


## Tier 1.7 (P8): second `start()` on same manager must not keep prior `formation` hysteresis (regression guard for
## `clear_resolved_mode_cache`).
static func _run_engagement_mode_cache_reset_on_second_start(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    var m0: String = CombatEngagementMode.engagement_mode(mgr)
    if m0 != CombatConstants.ENGAGEMENT_MODE_FORMATION:
        _fail(
            failures, "mode_cache_reset: expected first start formation-line mode got %s" % m0
        )
    # Rebuild as tiny duel on the **same** manager node.
    for c in mgr.combatants:
        var n: Node = CombatantEntityAccess.scene_node(c)
        if n != null:
            n.free()
    mgr.combatants.clear()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var m1: String = CombatEngagementMode.engagement_mode(mgr)
    if m1 != CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(
            failures, "mode_cache_reset: after 1v1 restart expected duel got %s (stale formation cache?)" % m1
        )
    HarnessFixtures._free_manager(mgr)


## Tier 1.8 soak: deaths-only path must not return to resolved formation after leaving it (hysteresis / classifier
## stability).


## Tier 1.8 soak: deaths-only path must not return to resolved formation after leaving it (hysteresis / classifier
## stability).
static func _run_engagement_attrition_monotone(failures: PackedStringArray) -> void:
    var rng := RandomNumberGenerator.new()
    for scenario_seed in 32:
        rng.seed = scenario_seed
        var pn: int = rng.randi_range(4, 8)
        var en: int = rng.randi_range(4, 8)
        var mgr: Node = CombatManager.new()
        for _i in pn:
            mgr.register(_new_entity("SWORD"), "player")
        for _j in en:
            mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({}, {})
        var order: Array = []
        for c in mgr.combatants:
            order.append(CombatantEntityAccess.id_int(c))
        HarnessFixtures._shuffle_int_array_in_place(order, rng)
        var left_formation: bool = false
        for cid in order:
            var cur: Variant = mgr._get_by_id(int(cid))
            if cur == null or not CombatantEntityAccess.alive_bool(cur):
                continue
            HarnessFixtures._soak_kill_combatant(mgr, int(cid))
            var resolved: String = CombatEngagementMode.engagement_mode(mgr)
            if resolved != CombatConstants.ENGAGEMENT_MODE_FORMATION:
                left_formation = true
            elif left_formation:
                _fail(
                    failures,
                    (
                        "attrition_monotone seed=%d: re-entered formation after leaving (last_kill_id=%d)"
                        % [scenario_seed, cid]
                    )
                )
                break
            Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(
                failures, mgr, "attrition_monotone seed=%d after_kill=%d" % [scenario_seed, cid]
            )
            var pa: int = CombatEngagementMode.count_active_for_side(mgr, "player")
            var ea: int = CombatEngagementMode.count_active_for_side(mgr, "enemy")
            if pa <= 0 or ea <= 0:
                break
        HarnessFixtures._free_manager(mgr)


## Tier 1.8 (P9): telemetry meta + embedded snapshot agree with resolved mode; no spurious transitions on cold start.


## Tier 1.8 (P9): telemetry meta + embedded snapshot agree with resolved mode; no spurious transitions on cold start.
static func _run_telemetry_lock_multi_seed(failures: PackedStringArray) -> void:
    var rng := RandomNumberGenerator.new()
    for scenario_seed in 48:
        rng.seed = scenario_seed
        var pn: int = rng.randi_range(1, 8)
        var en: int = rng.randi_range(1, 8)
        var mgr: Node = CombatManager.new()
        for _i in pn:
            mgr.register(_new_entity("SWORD"), "player")
        for _j in en:
            mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({}, {})
        if not mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
            _fail(
                failures, "telemetry_lock seed=%d: missing combat telemetry meta" % scenario_seed
            )
        else:
            var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
            var mode: String = CombatEngagementMode.engagement_mode(mgr)
            if str(tel.get("last_resolved_mode", "")) != mode:
                _fail(
                    failures,
                    (
                        "telemetry_lock seed=%d: tel.last_resolved_mode=%s vs engagement_mode=%s"
                        % [scenario_seed, tel.get("last_resolved_mode"), mode]
                    )
                )
            if int(tel.get("engagement_mode_transitions", -1)) != 0:
                _fail(
                    failures,
                    (
                        "telemetry_lock seed=%d: expected 0 mode transitions on cold start got %s"
                        % [scenario_seed, str(tel.get("engagement_mode_transitions"))]
                    )
                )
            if not tel.has("invalid_melee_resolve_blocked") or not tel.has("invalid_close_resolve_blocked"):
                _fail(
                    failures,
                    (
                        "telemetry_lock seed=%d: tel missing invalid_* keys (got keys=%s)"
                        % [scenario_seed, str(tel.keys())]
                    )
                )
            if (
                int(tel.get("invalid_melee_resolve_blocked", -1)) != 0
                or int(tel.get("invalid_close_resolve_blocked", -1)) != 0
            ):
                _fail(
                    failures,
                    (
                        "telemetry_lock seed=%d: expected 0 invalid melee/close on cold start tel=%s"
                        % [scenario_seed, str(tel)]
                    )
                )
        Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(
            failures, mgr, "telemetry_lock seed=%d" % scenario_seed
        )
        if mgr.has_meta("_tactical_mode_snapshot"):
            var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
            if not ts.has("telemetry"):
                _fail(
                    failures, "telemetry_lock seed=%d: _tactical_mode_snapshot missing telemetry" % scenario_seed
                )
            else:
                var emb: Dictionary = ts["telemetry"] as Dictionary
                var mode2: String = CombatEngagementMode.engagement_mode(mgr)
                if str(emb.get("last_resolved_mode", "")) != mode2:
                    _fail(
                        failures,
                        "telemetry_lock seed=%d: snapshot.telemetry last_resolved_mode mismatch" % scenario_seed
                    )
                if not emb.has("invalid_melee_resolve_blocked") or not emb.has("invalid_close_resolve_blocked"):
                    _fail(
                        failures, "telemetry_lock seed=%d: embedded telemetry missing invalid_* keys" % scenario_seed
                    )
                if (
                    int(emb.get("invalid_melee_resolve_blocked", -1)) != 0
                    or int(emb.get("invalid_close_resolve_blocked", -1)) != 0
                ):
                    _fail(
                        failures,
                        (
                            "telemetry_lock seed=%d: embedded telemetry expected 0 invalid counters got %s"
                            % [scenario_seed, str(emb)]
                        )
                    )
        HarnessFixtures._free_manager(mgr)


## Tier 1.9 (P10) multi-seed: `can_melee_threaten` implies MID/CLOSE band and a listed weapon strike vs that rank-0
## enemy.


## Tier 1.9 (P10) multi-seed: `can_melee_threaten` implies MID/CLOSE band and a listed weapon strike vs that rank-0
## enemy.
static func _run_depth_polearm_band_vs_actions_fuzz(failures: PackedStringArray) -> void:
    var rng := RandomNumberGenerator.new()
    for scenario_seed in 48:
        rng.seed = scenario_seed
        var pf: int = rng.randi_range(1, 4)
        var ef: int = rng.randi_range(1, 4)
        var mgr: Node = CombatManager.new()
        for _i in pf:
            mgr.register(_new_entity("SWORD"), "player")
        for _j in pf:
            mgr.register(_new_entity("SPEAR"), "player")
        for _k in ef:
            mgr.register(_new_entity("SWORD"), "enemy")
        mgr.start({"files": pf, "ranks": 2, "density": "normal"}, {"files": ef, "ranks": 1, "density": "normal"})
        var fs: int = rng.randi_range(0, pf - 1)
        var depth_idx: int = pf + fs
        if depth_idx >= mgr.combatants.size():
            _fail(failures, "depth_polearm_band_acts seed=%d: bad depth idx" % scenario_seed)
            HarnessFixtures._free_manager(mgr)
            continue
        var depth: Dictionary = mgr.combatants[depth_idx]
        if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
            _fail(
                failures, "depth_polearm_band_acts seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs]
            )
            HarnessFixtures._free_manager(mgr)
            continue
        depth["gauge"] = 100.0
        var w_depth: Variant = CombatantEntityAccess.get_weapon(depth)
        var atk_ids: Dictionary = {}
        if w_depth != null and w_depth is Weapon:
            atk_ids = (w_depth as Weapon).attack_types
        for c in mgr.combatants:
            if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
                continue
            if CombatantEntityAccess.rank_int(c, -1) != 0:
                continue
            if not CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c):
                continue
            if not CombatMeleeListing.can_melee_threaten(mgr, depth, c):
                continue
            var dist: String = CombatantEntityAccess.distance_to_opponent_band(
                depth, CombatantEntityAccess.id_int(c, -2), ""
            )
            if dist == CombatConstants.DISTANCE_LONG:
                _fail(
                    failures,
                    (
                        "depth_polearm_band_acts seed=%d: threaten true but distance LONG vs id=%s"
                        % [scenario_seed, str(CombatantEntityAccess.id_int(c))]
                    )
                )
                continue
            if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
                _fail(
                    failures,
                    (
                        "depth_polearm_band_acts seed=%d: expected CLOSE/MID vs id=%s got %s"
                        % [scenario_seed, str(CombatantEntityAccess.id_int(c)), dist]
                    )
                )
                continue
            var acts: Array = mgr.get_available_actions(CombatantEntityAccess.id_int(depth))
            if not CombatListedActions.actions_include_any_move_in_vs_target(
                acts, CombatantEntityAccess.id_int(c), atk_ids
            ):
                _fail(
                    failures,
                    (
                        ("depth_polearm_band_acts seed=%d: threaten true but no weapon strike vs id=%s dist=%s acts=%s")
                        % [scenario_seed, str(CombatantEntityAccess.id_int(c)), dist, str(acts)]
                    )
                )
        HarnessFixtures._free_manager(mgr)


static func _run_surround_production_path_dampens_defense_vs_compressed_flanks(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_sector_surround_load():
        return
    var def: Dictionary = {"stats": {"perception": 100.0}, "stance": "balanced"}
    var pa: Dictionary = {
        "surround_threat_count": 2,
        "surround_threat_weight_sum": 1.15,
        "tactical_ambush_mult": 1.0,
    }
    var m_prod: float = TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
    var m_int: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
    if m_prod <= m_int + 0.001:
        _fail(
            failures,
            (
                "surround_prod_defense: sector mult %.6f should exceed integer %.6f (milder) wsum=%.4f"
                % [m_prod, m_int, float(pa["surround_threat_weight_sum"])]
            )
        )
    if not is_equal_approx(m_prod, TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, 1.15)):
        _fail(failures, "surround_prod_defense: production mult %.6f vs harness ref" % m_prod)


## Tier 1.9 auto profile: `line_discipline` / `engagement_posture` steer over-shoulder vs open when `spear_lane_profile`
## is auto (**OPEN** and **DUEL** open lows under tight when not strict-only).


## Tier 1.9 auto profile: `line_discipline` / `engagement_posture` steer over-shoulder vs open when `spear_lane_profile`
## is auto (**OPEN** and **DUEL** open lows under tight when not strict-only).
static func _run_telemetry_invalid_melee_resolve_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    AttackWindUpStarter.start(mgr, p_id, e_id, "thrust")
    var p: Dictionary = mgr.combatants[0]
    if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
        p["distance_to"] = {}
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    var res: Dictionary = AttackResolver.resolve_attack(mgr, p_id)
    if str(res.get("action", "")) != "skip":
        _fail(
            failures, "telemetry_melee_geom: expected skip when LONG+threaten false got %s" % str(res)
        )
    if float(res.get("recovery_duration", 0.0)) <= 0.0:
        _fail(failures, "telemetry_melee_geom: expected positive recovery on abort")
    if not mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "telemetry_melee_geom: missing telemetry meta")
    else:
        var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
        if int(tel.get("invalid_melee_resolve_blocked", 0)) < 1:
            _fail(
                failures, "telemetry_melee_geom: expected invalid_melee_resolve_blocked >= 1 got %s" % str(tel)
            )
    HarnessFixtures._free_manager(mgr)


## Tier 1.8: `attempt_close` is not listed when pair band is MID/CLOSE (matches `resolve_close_attempt` LONG-only).


## Tier 1.8: `attempt_close` is not listed when pair band is MID/CLOSE (matches `resolve_close_attempt` LONG-only).
static func _run_telemetry_invalid_close_resolve_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p: Dictionary = mgr.combatants[0]
    var en: Dictionary = mgr.combatants[1]
    if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
        p["distance_to"] = {}
    if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
        en["distance_to"] = {}
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if not mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "telemetry_close: missing telemetry meta after blocked close")
    else:
        var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
        if int(tel.get("invalid_close_resolve_blocked", 0)) < 1:
            _fail(
                failures, "telemetry_close: expected invalid_close_resolve_blocked >= 1 got %s" % str(tel)
            )
    HarnessFixtures._free_manager(mgr)


## Failed pressure-vs-evasion close emits `reason: contest_failed` for UI / tooling (not only generic `close_failed`).


## Failed pressure-vs-evasion close emits `reason: contest_failed` for UI / tooling (not only generic `close_failed`).
static func _run_attempt_close_listed_only_at_long(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p: Dictionary = mgr.combatants[0]
    var en: Dictionary = mgr.combatants[1]
    if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
        p["distance_to"] = {}
    if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
        en["distance_to"] = {}
    p["gauge"] = 100.0
    en["gauge"] = 100.0
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
    var acts_mid: Array = AvailableActionsBuilder.build(mgr, p_id)
    if CombatListedActions.actions_include_move_vs_target(acts_mid, e_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        _fail(
            failures, "attempt_close_list: must not list close vs MID opponent (target %d)" % e_id
        )
        HarnessFixtures._free_manager(mgr)
        return
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
    var acts_long: Array = AvailableActionsBuilder.build(mgr, p_id)
    if CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(p), CombatPairGeometry.effective_pair_eff_dist(mgr, p, en)
    ):
        if not CombatListedActions.action_list_has_hostile_melee_strike(acts_long, p_id):
            _fail(failures, "attempt_close_list: in-swing at LONG want strikes not close-only")
        if CombatListedActions.actions_include_move_vs_target(acts_long, e_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
            _fail(failures, "attempt_close_list: in-swing at LONG must not list attempt_close")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatListedActions.actions_include_move_vs_target(acts_long, e_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        _fail(failures, "attempt_close_list: expected attempt_close vs LONG opponent")
    HarnessFixtures._free_manager(mgr)
    # Out-of-reach LONG: 7v3 outer wing (mapped gap 2, eff > sword reach).
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_wing.is_empty() or e_wing.is_empty():
        _fail(failures, "attempt_close_list: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager(wide)
        return
    var p_w_id: int = CombatantEntityAccess.id_int(p_wing)
    var e_w_id: int = CombatantEntityAccess.id_int(e_wing)
    p_wing["gauge"] = 100.0
    CombatantEntityAccess.nested_dictionary_for_mutation(p_wing, "distance_to")[e_w_id] = (
        CombatConstants.DISTANCE_LONG
    )
    CombatantEntityAccess.nested_dictionary_for_mutation(e_wing, "distance_to")[p_w_id] = (
        CombatConstants.DISTANCE_LONG
    )
    if CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(p_wing), CombatPairGeometry.effective_pair_eff_dist(wide, p_wing, e_wing)
    ):
        _fail(failures, "attempt_close_list: wing setup want out-of-reach eff_dist")
        HarnessFixtures._free_manager(wide)
        return
    var acts_wing: Array = AvailableActionsBuilder.build(wide, p_w_id)
    if not CombatListedActions.actions_include_move_vs_target(acts_wing, e_w_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        _fail(failures, "attempt_close_list: wing at LONG want attempt_close when out of reach")
    HarnessFixtures._free_manager(wide)


## Utility pick: cooldown-blocked **`attempt_close`** must weight 0 (defense in depth vs stale menu).


## Utility pick: cooldown-blocked **`attempt_close`** must weight 0 (defense in depth vs stale menu).
static func _run_attempt_close_ai_weight_zero_when_pair_blocked(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p: Dictionary = mgr.combatants[0]
    p["gauge"] = 100.0
    if typeof(p.get("close_block_until_by_target_id", null)) != TYPE_DICTIONARY:
        p["close_block_until_by_target_id"] = {}
    (p["close_block_until_by_target_id"] as Dictionary)[e_id] = 999999.0
    var a_close: Dictionary = {
        "target_id": e_id,
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
    }
    if CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true) > 0.001:
        _fail(
            failures, "attempt_close_blocked_weight: want zero weight when pair cooldown active"
        )
    HarnessFixtures._free_manager(mgr)


## Tier 1.8: `CombatAIActionPicker` must not weight stale `attempt_close` at MID/CLOSE (defense in depth vs listing).


## Tier 1.8: `CombatAIActionPicker` must not weight stale `attempt_close` at MID/CLOSE (defense in depth vs listing).
static func _run_attempt_close_ai_weight_zero_when_not_long(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var p: Dictionary = mgr.combatants[0]
    var en: Dictionary = mgr.combatants[1]
    if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
        p["distance_to"] = {}
    if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
        en["distance_to"] = {}
    p["gauge"] = 100.0
    en["gauge"] = 100.0
    var a_close: Dictionary = {
        "target_id": e_id,
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
    }
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
    if CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true) > 0.001:
        _fail(
            failures,
            (
                "attempt_close_weight: MID band should zero weight got %.6f"
                % CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true)
            )
        )
        HarnessFixtures._free_manager(mgr)
        return
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
    var w_long: float = CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true)
    var in_swing: bool = CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(p), CombatPairGeometry.effective_pair_eff_dist(mgr, p, en)
    )
    if in_swing:
        if w_long > 0.001:
            _fail(
                failures, "attempt_close_weight: in-swing LONG should zero weight got %.6f" % w_long
            )
    else:
        if w_long <= 0.001:
            _fail(
                failures, "attempt_close_weight: out-of-reach LONG should allow positive weight got %.6f" % w_long
            )
    HarnessFixtures._free_manager(mgr)


## III-4 **3e**: utility pick dampens focus-line weight during mop-up.


## III-4 **3e**: utility pick dampens focus-line weight during mop-up.
static func _run_envelop_focus_ai_weight_damp_mop_up(failures: PackedStringArray) -> void:
    var mgr_mop: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_mop, "player", 0, 3)
    if player.is_empty():
        _fail(failures, "focus_weight_mop_up: missing player fixture")
        HarnessFixtures._free_manager(mgr_mop)
        return
    player["guard_line"] = "low"
    player.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
    var p_id: int = CombatantEntityAccess.id_int(player)
    var a_focus: Dictionary = {
        "target_id": p_id,
        "move_id": CombatConstants.MOVE_ID_FOCUS_HIGH,
    }
    var w_mop: float = CombatAIActionPicker._get_action_weight(a_focus, p_id, mgr_mop, true)
    var mgr_open: Node = CombatManager.new()
    for _i in 7:
        mgr_open.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr_open.register(_new_entity("SWORD"), "enemy")
    mgr_open.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var open_player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr_open, "player", 0, 3)
    open_player["guard_line"] = "low"
    open_player.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
    var open_id: int = CombatantEntityAccess.id_int(open_player)
    var w_open: float = CombatAIActionPicker._get_action_weight(a_focus, open_id, mgr_open, true)
    if w_mop >= w_open * 0.99:
        _fail(
            failures, "focus_weight_mop_up: want damped weight got mop=%.6f open=%.6f" % [w_mop, w_open]
        )
    HarnessFixtures._free_manager(mgr_mop)
    HarnessFixtures._free_manager(mgr_open)


## III-4 **3e**: utility pick  -  mop-up boosts **`attempt_close`** at LONG only; MID/CLOSE finish with strikes.


## III-4 **3e**: utility pick  -  mop-up boosts **`attempt_close`** at LONG only; MID/CLOSE finish with strikes.
static func _run_attempt_close_ai_weight_mid_mop_up(failures: PackedStringArray) -> void:
    var mgr: Node = Tier1EnvelopPlugSkirmishTests._harness_7v3_mop_up_mgr()
    var player: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 3)
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
            break
    if player.is_empty() or enemy.is_empty():
        _fail(failures, "attempt_close_weight_mop_up: missing fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(player)
    var e_id: int = CombatantEntityAccess.id_int(enemy)
    if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
        player["distance_to"] = {}
    if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
        enemy["distance_to"] = {}
    player["gauge"] = 100.0
    enemy["gauge"] = 100.0
    var a_close: Dictionary = {
        "target_id": e_id,
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
    }
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
    (enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
    var w_mid: float = CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true)
    if w_mid > 0.001:
        _fail(
            failures, "attempt_close_weight_mop_up: MID during mop-up want zero weight (strike finish) got %.6f" % w_mid
        )
    (player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
    var w_long: float = CombatAIActionPicker._get_action_weight(a_close, p_id, mgr, true)
    var in_swing: bool = CombatPairGeometry.melee_reach_covers_eff_dist(
        CombatMeleeListing.melee_weapon_reach(player), CombatPairGeometry.effective_pair_eff_dist(mgr, player, enemy)
    )
    if in_swing:
        if w_long > 0.001:
            _fail(
                failures, "attempt_close_weight_mop_up: in-swing LONG during mop-up want zero weight got %.6f" % w_long
            )
    else:
        if w_long <= 0.001:
            _fail(
                failures,
                "attempt_close_weight_mop_up: out-of-reach LONG during mop-up want positive weight got %.6f" % w_long
            )
    HarnessFixtures._free_manager(mgr)


## Tier 1.8: `resolve_close_attempt` when pair band is not LONG (stale vs `attempt_close` listing) increments telemetry.


## Tier 1.8: `resolve_close_attempt` when pair band is not LONG (stale vs `attempt_close` listing) increments telemetry.
static func _run_close_contest_failed_emits_reason(failures: PackedStringArray) -> void:
    var fixtures: Array = HarnessFixtures._harness_7v3_wing_rank0_fixtures()
    var mgr: Node = fixtures[0] as Node
    var p: Dictionary = fixtures[1] as Dictionary
    var en: Dictionary = fixtures[2] as Dictionary
    if p.is_empty() or en.is_empty():
        _fail(failures, "close_contest: missing 7v3 wing fixtures")
        HarnessFixtures._free_manager(mgr)
        return
    var p_id: int = CombatantEntityAccess.id_int(p)
    var e_id: int = CombatantEntityAccess.id_int(en)
    HarnessFixtures._harness_bind_pair_long_band(p, en)
    var sd: Dictionary = CombatantEntityAccess.stats_dict_for_mutation(p)
    sd["strength"] = 0.0
    var cap: Array = []
    mgr.action_resolved.connect(
        func(_aid: int, _tid: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if cap.is_empty():
        _fail(failures, "close_contest: expected action_resolved payload")
        HarnessFixtures._free_manager(mgr)
        return
    var r: Dictionary = cap[0] as Dictionary
    if str(r.get("outcome", "")) != "close_failed":
        _fail(failures, "close_contest: expected close_failed got %s" % str(r))
    elif str(r.get("reason", "")) != "contest_failed":
        _fail(
            failures, "close_contest: expected reason contest_failed got %s" % str(r.get("reason", ""))
        )
    var line: String = CombatLogFormatter.format_action_line("P", "player", "E", "enemy", r)
    if not line.contains("measure"):
        _fail(
            failures, "close_contest: formatter should mention defender measure got %s" % line
        )
    HarnessFixtures._free_manager(mgr)


## `resolve_close_attempt` must not run the contest vs an incapacitated defender (stale UI / AI only).


## `resolve_close_attempt` must not run the contest vs an incapacitated defender (stale UI / AI only).
static func _run_resolve_close_no_emit_when_target_incap(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    var ent_enemy := _new_entity("SWORD")
    ent_enemy.consciousness = 5.0
    mgr.register(ent_enemy, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    var en: Dictionary = mgr.combatants[1]
    if not CombatantEntityAccess.is_incapacitated(en):
        _fail(failures, "close_skip_incap: enemy should be incap for test")
        HarnessFixtures._free_manager(mgr)
        return
    var p: Dictionary = mgr.combatants[0]
    if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
        p["distance_to"] = {}
    if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
        en["distance_to"] = {}
    (p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
    (en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
    var fired_box: Array = [0]
    mgr.action_resolved.connect(func(_a: int, _t: int, _r: Dictionary) -> void: fired_box[0] = int(fired_box[0]) + 1)
    CombatEngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    if int(fired_box[0]) != 0:
        _fail(
            failures, "close_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0])
        )
    HarnessFixtures._free_manager(mgr)


static func _run_parry_deflect_formatter_clash_context_branches(failures: PackedStringArray) -> void:
    var base_r: Dictionary = {
        "outcome": "parry_deflect", "dmg": 0, "died": false, "part": "", "health_before": -1, "health_after": -1
    }
    var line0: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_r)
    if line0.contains("meas=") or line0.contains("[size=10]"):
        _fail(failures, "parry_fmt: baseline should not include clash suffix got %s" % line0)
    var with_ctx: Dictionary = base_r.duplicate(true)
    with_ctx["parry_clash_context"] = {
        "kinematic_delivery": "thrust", "strike_measure_ratio": 1.2, "parry_control": 0.75
    }
    var line_ctx: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_ctx)
    if CombatConstants.COMBAT_DEBUG_CALIBRATION:
        if not line_ctx.contains("thrust") or not line_ctx.contains("meas=") or not line_ctx.contains("bind="):
            _fail(
                failures, "parry_fmt: calibration on expected thrust/meas/bind in %s" % line_ctx
            )
    else:
        if line_ctx != line0:
            _fail(
                failures, "parry_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_ctx, line0]
            )
    var empty_ctx: Dictionary = base_r.duplicate(true)
    empty_ctx["parry_clash_context"] = {}
    var line_empty: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_ctx)
    if line_empty != line0:
        _fail(
            failures, "parry_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_empty, line0]
        )


## `CombatLogFormatter`  -  **`parry_partial`**: non-empty **`parry_clash_context`** unchanged unless
## **`COMBAT_DEBUG_CALIBRATION`**; suffix includes **`rem=`** (**`remaining_ratio`**).


## `CombatLogFormatter`  -  **`parry_partial`**: non-empty **`parry_clash_context`** unchanged unless
## **`COMBAT_DEBUG_CALIBRATION`**; suffix includes **`rem=`** (**`remaining_ratio`**).
static func _run_parry_partial_formatter_clash_context_branches(failures: PackedStringArray) -> void:
    var base_pp: Dictionary = {
        "outcome": "parry_partial", "dmg": 0, "died": false, "part": "", "health_before": -1, "health_after": -1
    }
    var line_pp0: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_pp)
    if line_pp0.contains("meas=") or line_pp0.contains("[size=10]"):
        _fail(
            failures, "parry_partial_fmt: baseline should not include clash suffix got %s" % line_pp0
        )
    if not line_pp0.contains("partially parried"):
        _fail(
            failures, "parry_partial_fmt: baseline should say partially parried got %s" % line_pp0
        )
    var with_pp: Dictionary = base_pp.duplicate(true)
    with_pp["parry_clash_context"] = {
        "kinematic_delivery": "thrust", "strike_measure_ratio": 1.2, "parry_control": 0.75, "remaining_ratio": 0.11
    }
    var line_pp_ctx: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_pp)
    if CombatConstants.COMBAT_DEBUG_CALIBRATION:
        if (
            not line_pp_ctx.contains("thrust")
            or not line_pp_ctx.contains("meas=")
            or not line_pp_ctx.contains("bind=")
            or not line_pp_ctx.contains("rem=")
        ):
            _fail(
                failures, "parry_partial_fmt: calibration on expected thrust/meas/bind/rem in %s" % line_pp_ctx
            )
    else:
        if line_pp_ctx != line_pp0:
            _fail(
                failures,
                "parry_partial_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_pp_ctx, line_pp0]
            )
    var empty_pp: Dictionary = base_pp.duplicate(true)
    empty_pp["parry_clash_context"] = {}
    var line_pp_empty: String = CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_pp)
    if line_pp_empty != line_pp0:
        _fail(
            failures,
            (
                "parry_partial_fmt: empty parry_clash_context should match baseline got %s vs %s"
                % [line_pp_empty, line_pp0]
            )
        )


static func _run_telemetry_automatic_doctrine_pinch_record(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    TacticalCombat.record_automatic_doctrine_pinch(mgr, "enemy")
    if not mgr.has_meta(TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "telemetry_auto_doc: missing meta after record")
        HarnessFixtures._free_manager(mgr)
        return
    var tel: Dictionary = mgr.get_meta(TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
    if int(tel.get("automatic_doctrine_pinch_count", 0)) != 1:
        _fail(
            failures,
            (
                "telemetry_auto_doc: expected automatic_doctrine_pinch_count 1 got %s"
                % str(tel.get("automatic_doctrine_pinch_count", -1))
            )
        )
        HarnessFixtures._free_manager(mgr)
        return
    var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
    if typeof(lap) != TYPE_DICTIONARY:
        _fail(failures, "telemetry_auto_doc: last_automatic_doctrine_pinch should be a dict")
        HarnessFixtures._free_manager(mgr)
        return
    if str((lap as Dictionary).get("formation_id", "")) != "enemy":
        _fail(failures, "telemetry_auto_doc: last pinch formation_id mismatch")
    HarnessFixtures._free_manager(mgr)


## Snapshot rows carry `formation_doctrine` aligned with `CombatManager.get_formation_doctrine`.


## Snapshot rows carry `formation_doctrine` aligned with `CombatManager.get_formation_doctrine`.
static func _run_combatants_snapshot_formation_doctrine_field(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    var rows: Array = mgr.get_combatants()
    var ok_player: bool = false
    for row in rows:
        if typeof(row) != TYPE_DICTIONARY:
            continue
        var rd: Dictionary = row as Dictionary
        if str(rd.get("formation_id", "")) != "player":
            continue
        ok_player = true
        if str(rd.get("formation_doctrine", "")) != CombatConstants.DOCTRINE_HOLD_LANE:
            _fail(
                failures, "snapshot_doctrine: player row got %s want hold_lane" % str(rd.get("formation_doctrine", ""))
            )
        if str(rd.get("zone_geometry_fid", "")) != "player":
            _fail(
                failures,
                "snapshot zone_geometry_fid: player row got %s want player" % str(rd.get("zone_geometry_fid", ""))
            )
        break
    if not ok_player:
        _fail(failures, "snapshot_doctrine: no player row in get_combatants")
    HarnessFixtures._free_manager(mgr)


static func _run_parry_pack_flank_effective_spacing(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.encounter[CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE] = true
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var e_id: int = CombatantEntityAccess.id_int(mgr.combatants[1])
    mgr.combatants[0]["file"] = 0
    mgr.combatants[1]["file"] = 1
    mgr.recompute_zoc_and_distance()
    var p0: Dictionary = mgr.combatants[0]
    var e_adj: Dictionary = mgr.combatants[1]
    var eff_adj: float = CombatPairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e_adj)
    if eff_adj + 1e-4 >= float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
        _fail(
            failures,
            "parry_pack_flank: adjacent files expected eff spacing < PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f" % eff_adj
        )
    var m_adj: float = ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
    if is_equal_approx(m_adj, CombatConstants.FLANK_PARRY_MOD):
        _fail(
            failures, "parry_pack_flank: adjacent files should not apply flank mod (got %.4f)" % m_adj
        )
    mgr.combatants[1]["file"] = 2
    mgr.recompute_zoc_and_distance()
    var e_far: Dictionary = mgr.combatants[1]
    var eff_far: float = CombatPairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e_far)
    if eff_far + 1e-4 < float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
        _fail(
            failures,
            (
                "parry_pack_flank: |Deltafile|==2 expected eff spacing >= PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
                % eff_far
            )
        )
    var m_far: float = ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
    if not is_equal_approx(m_far, CombatConstants.FLANK_PARRY_MOD):
        _fail(
            failures,
            (
                "parry_pack_flank: |Deltafile|==2 with protection circle should apply flank mod (got %.4f want %.4f)"
                % [m_far, CombatConstants.FLANK_PARRY_MOD]
            )
        )
    HarnessFixtures._free_manager(mgr)
