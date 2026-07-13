class_name CombatRegressionHarnessTier1TailPartH
extends RefCounted

## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_hostile_pair_cached_engagement_mode_matches_live(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var w_live: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e)
    var em: float = CombatTargetScoring.engagement_mode_targeting_mult(mgr)
    var w_cached: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em)
    if not is_equal_approx(w_live, w_cached):
        CombatRegressionHarness._fail(
            failures, "hostile_pair_em_cache: live %.8f vs cached-arg %.8f (em=%.8f)" % [w_live, w_cached, em]
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: depth spear lane parry mults in `DefenseChoiceResolver` (tight -> `parry_c_d`; open + stab -> `parry_p_a`).


## Tier 3.1: depth spear lane parry mults in `DefenseChoiceResolver` (tight -> `parry_c_d`; open + stab -> `parry_p_a`).
static func _run_ai_targeting_stance_mult_ordering(failures: PackedStringArray) -> void:
    var m_def: float = CombatTargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_DEFENSIVE})
    var m_bal: float = CombatTargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_BALANCED})
    var m_agg: float = CombatTargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_AGGRESSIVE})
    if not (m_def < m_bal + 0.001 and m_bal < m_agg + 0.001):
        CombatRegressionHarness._fail(
            failures, "ai_targeting_stance: expected def<bal<agg got %.4f %.4f %.4f" % [m_def, m_bal, m_agg]
        )


## Tier 1.6: `hostile_pair_targeting_weight_mult` - -  **`AI_TARGETING_INCAP_HOSTILE_MULT`** vs incapacitated opponent
## (`CoreEntity` consciousness below threshold; dirty flag off so value sticks).
## Rank-0 pair must **not** be file-opposed (equal-width off-file slots; mapped offset 0)  -  incap mult is isolated
## from file-opposed hedge.


## Tier 1.6: `hostile_pair_targeting_weight_mult` - -  **`AI_TARGETING_INCAP_HOSTILE_MULT`** vs incapacitated opponent
## (`CoreEntity` consciousness below threshold; dirty flag off so value sticks).
## Rank-0 pair must **not** be file-opposed (equal-width off-file slots; mapped offset 0)  -  incap mult is isolated
## from file-opposed hedge.
static func _run_ai_targeting_incap_hostile_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_enemy = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ent_enemy, "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e_anchor: Dictionary = mgr.combatants[2]
    var opp: Dictionary = mgr.combatants[1]
    p["file"] = 0
    e_anchor["file"] = 0
    e_anchor["rank"] = 0
    opp["file"] = 1
    opp["rank"] = 0
    mgr.recompute_zoc_and_distance()
    if CombatTargetScoring.is_file_opposed_rank0_pair(mgr, p, opp):
        CombatRegressionHarness._fail(failures, "ai_incap: setup want off-file pair (not mapped-opposed)")
    var w_up: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
    if w_up <= 0.0:
        CombatRegressionHarness._fail(failures, "ai_incap: baseline hostile weight should be > 0")
        CombatRegressionHarness._free_manager(mgr)
        return
    ent_enemy.consciousness = 5.0
    var w_down: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
    var raw_down: float = w_up * CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT
    var expected_w: float = clampf(
        raw_down, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN, CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX
    )
    if abs(w_down - expected_w) > 0.03:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_incap: expected down=%.6f ~= clamp(up*mult)=%.6f (up=%.6f raw=%.6f mult=%.4f)"
                % [w_down, expected_w, w_up, raw_down, CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT]
            )
        )
    if not CombatantEntityAccess.is_incapacitated(opp):
        CombatRegressionHarness._fail(failures, "ai_incap: test setup failed  -  opponent should read as incapacitated")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `AvailableActionsBuilder` does not list melee / `attempt_close` vs incapacitated enemies.


## Tier 1.6: `AvailableActionsBuilder` does not list melee / `attempt_close` vs incapacitated enemies.
static func _run_no_hostile_actions_listed_vs_incap_enemy(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_enemy = CombatRegressionHarness._new_entity("SWORD")
    ent_enemy.consciousness = 5.0
    mgr.register(ent_enemy, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    if not CombatantEntityAccess.is_incapacitated(e):
        CombatRegressionHarness._fail(failures, "incap_acts: enemy should be incapacitated for test")
        CombatRegressionHarness._free_manager(mgr)
        return
    p["gauge"] = 100.0
    p["state"] = CombatConstants.STATE_WAITING
    var pid: int = CombatantEntityAccess.id_int(p)
    var eid: int = CombatantEntityAccess.id_int(e)
    var acts: Array = mgr.get_available_actions(pid)
    if CombatListedActions.actions_any_vs_target(acts, eid):
        var bad: Dictionary = CombatListedActions.first_action_vs_target(acts, eid)
        CombatRegressionHarness._fail(
            failures,
            (
                "incap_acts: unexpected action vs incap enemy move_id=%s full=%s"
                % [CombatListedActions.entry_move_id(bad), str(bad)]
            )
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / stalemate: all rank-0 enemies incap -> `any_enemy_rank0` false -> rank-1 pass may list vs deeper hostiles
## (no soft-lock).


## Tier 1.6 / stalemate: all rank-0 enemies incap -> `any_enemy_rank0` false -> rank-1 pass may list vs deeper hostiles
## (no soft-lock).
static func _run_stalemate_melee_rank1_when_rank0_incap(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ent_e0 = CombatRegressionHarness._new_entity("SWORD")
    ent_e0.consciousness = 5.0
    mgr.register(ent_e0, "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
    mgr.recompute_zoc_and_distance()
    var p: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
            break
    if p.is_empty():
        CombatRegressionHarness._fail(failures, "stalemate_incap: no player combatant after start")
        CombatRegressionHarness._free_manager(mgr)
        return
    var e0: Dictionary = {}
    var e1: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_enemy_side(c):
            continue
        var rr: int = CombatantEntityAccess.rank_int(c)
        if rr == 0:
            e0 = c
        elif rr == 1:
            e1 = c
    if e0.is_empty() or e1.is_empty():
        CombatRegressionHarness._fail(failures, "stalemate_incap: missing enemy rank0 or rank1 after start")
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatantEntityAccess.is_incapacitated(e0) or CombatantEntityAccess.is_incapacitated(e1):
        CombatRegressionHarness._fail(failures, "stalemate_incap: e0 should be incap, e1 upright")
        CombatRegressionHarness._free_manager(mgr)
        return
    var any_r0: bool = false
    for oc in mgr.combatants:
        if CombatantEntityAccess.is_player_side(oc):
            continue
        if CombatantEntityAccess.rank_int(oc) != 0:
            continue
        if CombatMeleeRankTargeting.opp_matches_melee_rank_target(mgr, p, oc, 0):
            any_r0 = true
            break
    if any_r0:
        CombatRegressionHarness._fail(failures, "stalemate_incap: expected no _opp_matches rank0 after incap")
        CombatRegressionHarness._free_manager(mgr)
        return
    p["gauge"] = 100.0
    p["state"] = CombatConstants.STATE_WAITING
    var pid: int = CombatantEntityAccess.id_int(p)
    var e0id: int = CombatantEntityAccess.id_int(e0)
    var e1id: int = CombatantEntityAccess.id_int(e1)
    var acts: Array = mgr.get_available_actions(pid)
    if CombatListedActions.actions_any_vs_target(acts, e0id):
        CombatRegressionHarness._fail(
            failures,
            (
                "stalemate_incap: should not list actions vs incap rank0 got %s"
                % str(CombatListedActions.first_action_vs_target(acts, e0id))
            )
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatListedActions.actions_any_vs_target(acts, e1id):
        CombatRegressionHarness._fail(
            failures, "stalemate_incap: expected at least one action vs rank1 enemy acts=%s" % str(acts)
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 3.2: weapon part mass fractions must cover the whole weapon; parry contact uses the intended part.


## Tier 3.2: weapon part mass fractions must cover the whole weapon; parry contact uses the intended part.
static func _run_ordered_melee_opponents_file_opposed_sort(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p: Dictionary = {}
    var e_same: Dictionary = {}
    var e_off: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
        elif e_same.is_empty():
            e_same = c
        else:
            e_off = c
    p["file"] = 0
    p["rank"] = 0
    e_same["file"] = 0
    e_same["rank"] = 0
    e_off["file"] = 2
    e_off["rank"] = 0
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var ordered: Array = CombatTargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
    if ordered.size() < 2:
        CombatRegressionHarness._fail(failures, "melee_order_fo: need >=2 rank0 opponents got %d" % ordered.size())
        CombatRegressionHarness._free_manager(mgr)
        return
    var want_id: int = CombatantEntityAccess.id_int(e_same, -998)
    if CombatantEntityAccess.id_int(ordered[0], -999) != want_id:
        var w_same: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_same)
        var w_off: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_off)
        var id_list: Array = []
        for x in ordered:
            id_list.append(CombatantEntityAccess.id_int(x, -1))
        CombatRegressionHarness._fail(
            failures,
            (
                "melee_order_fo: file-opposed enemy id=%d should sort first got order=%s w_same=%.4f w_off=%.4f"
                % [want_id, str(id_list), w_same, w_off]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `ordered_melee_opponents` tiebreak uses full hostile weight (committed doctrine target first when
## file-opposed ties).


## Tier 1.6: `ordered_melee_opponents` tiebreak uses full hostile weight (committed doctrine target first when
## file-opposed ties).
static func _run_ordered_melee_opponents_commitment_tiebreak(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p: Dictionary = {}
    var e1: Dictionary = {}
    var e2: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
        elif e1.is_empty():
            e1 = c
        else:
            e2 = c
    p["file"] = 1
    e1["file"] = 0
    e2["file"] = 2
    mgr.recompute_zoc_and_distance()
    var pid: int = CombatantEntityAccess.id_int(p)
    var e1id: int = CombatantEntityAccess.id_int(e1)
    CombatTargetScoring.on_combat_commitment(mgr, pid, e1id)
    var ordered: Array = CombatTargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
    if ordered.is_empty():
        CombatRegressionHarness._fail(failures, "melee_order_commit: ordered list empty")
    else:
        var first_id: int = CombatantEntityAccess.id_int(ordered[0], -999)
        if first_id != e1id:
            var id_list: Array = []
            for x in ordered:
                id_list.append(CombatantEntityAccess.id_int(x, -1))
            CombatRegressionHarness._fail(
                failures,
                (
                    "melee_order_commit: expected committed opponent first got first_id=%d want e1=%d order=%s"
                    % [first_id, e1id, str(id_list)]
                )
            )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: cached **`zone_geometry_line_context`** on **`ordered_melee_opponents`** matches a fresh resolve (listing
## sort stability).


## Tier 1.6: cached **`zone_geometry_line_context`** on **`ordered_melee_opponents`** matches a fresh resolve (listing
## sort stability).
static func _run_ordered_melee_opponents_actor_zone_cache_parity(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p: Dictionary = {}
    var e0: Dictionary = {}
    var e1: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
        elif e0.is_empty():
            e0 = c
        else:
            e1 = c
    p["file"] = 1
    p["rank"] = 0
    e0["file"] = 0
    e0["rank"] = 0
    e1["file"] = 2
    e1["rank"] = 0
    mgr.recompute_zoc_and_distance()
    var fresh: Array = CombatTargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
    var ctx: Dictionary = ZoneOfControl.zone_geometry_line_context(mgr, p)
    var cached: Array = CombatTargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0, ctx)
    var ids_fresh: Array = []
    var ids_cached: Array = []
    for x in fresh:
        ids_fresh.append(CombatantEntityAccess.id_int(x))
    for x in cached:
        ids_cached.append(CombatantEntityAccess.id_int(x))
    CombatRegressionHarness._free_manager(mgr)
    if ids_fresh != ids_cached:
        CombatRegressionHarness._fail(
            failures, "melee_order_ctx: fresh %s != cached %s" % [str(ids_fresh), str(ids_cached)]
        )


## **`AvailableActionsBuilder.build`** is deterministic across back-to-back calls on the same combat state.


## **`AvailableActionsBuilder.build`** is deterministic across back-to-back calls on the same combat state.
static func _run_available_actions_build_double_invoke_parity(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 2, "density": "tight"})
    var p: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
            break
    p["file"] = 1
    p["rank"] = 0
    mgr.recompute_zoc_and_distance()
    var pid: int = CombatantEntityAccess.id_int(p)
    var sig_a: String = CombatListedActions.compact_signature(AvailableActionsBuilder.build(mgr, pid))
    var sig_b: String = CombatListedActions.compact_signature(AvailableActionsBuilder.build(mgr, pid))
    CombatRegressionHarness._free_manager(mgr)
    if sig_a != sig_b:
        CombatRegressionHarness._fail(failures, "actions_build_parity: first=%s second=%s" % [sig_a, sig_b])


## Tier 1.6: cached opponent **`zone_geometry_line_context`** matches pair-resolve weight on
## **`hostile_pair_targeting_weight_mult`**.


## Tier 1.6: cached opponent **`zone_geometry_line_context`** matches pair-resolve weight on
## **`hostile_pair_targeting_weight_mult`**.
static func _run_hostile_pair_opp_zone_cache_parity(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "tight"})
    var p: Dictionary = {}
    var e: Dictionary = {}
    for c in mgr.combatants:
        if CombatantEntityAccess.is_player_side(c):
            p = c
        else:
            e = c
    p["file"] = 1
    p["rank"] = 0
    e["file"] = 1
    e["rank"] = 0
    mgr.recompute_zoc_and_distance()
    var em: float = CombatTargetScoring.engagement_mode_targeting_mult(mgr)
    var ctx_p: Dictionary = ZoneOfControl.zone_geometry_line_context(mgr, p)
    var zone_by_id: Dictionary = ZoneOfControl.zone_geometry_line_context_by_combatant_id(mgr)
    var eid: int = CombatantEntityAccess.id_int(e)
    var ctx_e: Dictionary = zone_by_id.get(eid, {}) as Dictionary
    var w_pair: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em, ctx_p)
    var w_cached: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em, ctx_p, ctx_e)
    CombatRegressionHarness._free_manager(mgr)
    if not is_equal_approx(w_pair, w_cached):
        CombatRegressionHarness._fail(failures, "hostile_pair_opp_ctx: pair=%.6f cached=%.6f" % [w_pair, w_cached])


## Tier 4.2: **`AttackWindUpStarter.start`** with **`feint_part`** / **`target_part`** options stamps
## **`pending_attack`** (incl. **`feint_target_reveal_at_progress`** when the move defines it), sets defender
## **`guard_zone`** to the telegraph (**`feint_part`** when present). Uses
## **`CombatRegressionHarness.CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED`** for stable upstream wind-up rolls;
## restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** before teardown.


## Tier 4.2: **`AttackWindUpStarter.start`** with **`feint_part`** / **`target_part`** options stamps
## **`pending_attack`** (incl. **`feint_target_reveal_at_progress`** when the move defines it), sets defender
## **`guard_zone`** to the telegraph (**`feint_part`** when present). Uses
## **`CombatRegressionHarness.CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED`** for stable upstream wind-up rolls;
## restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** before teardown.
static func _run_depth_spear_tight_lane_parry_mult_invariant(failures: PackedStringArray) -> void:
    var m0: float = DefenseChoiceResolver.depth_spear_tight_lane_parry_c_d_mult({})
    var m_open: float = (
        DefenseChoiceResolver
        . depth_spear_tight_lane_parry_c_d_mult(
            {
                "depth_polearm_attack": true,
                "depth_polearm_allows_low_targets": true,
                "depth_polearm_lane_type": "open",
            }
        )
    )
    var m_tight: float = (
        DefenseChoiceResolver
        . depth_spear_tight_lane_parry_c_d_mult(
            {
                "depth_polearm_attack": true,
                "depth_polearm_allows_low_targets": false,
                "depth_polearm_lane_type": "over_shoulder",
            }
        )
    )
    var m_empty_allows: float = DefenseChoiceResolver.depth_spear_tight_lane_parry_c_d_mult(
        {"depth_polearm_attack": true, "depth_polearm_allows_low_targets": true, "depth_polearm_lane_type": ""}
    )
    var m_empty_tight: float = DefenseChoiceResolver.depth_spear_tight_lane_parry_c_d_mult(
        {"depth_polearm_attack": true, "depth_polearm_allows_low_targets": false, "depth_polearm_lane_type": ""}
    )
    if not is_equal_approx(m0, 1.0) or not is_equal_approx(m_open, 1.0):
        CombatRegressionHarness._fail(
            failures,
            "depth_spear_parry_mult: expected 1.0 for non-depth or open lane got m0=%.4f m_open=%.4f" % [m0, m_open]
        )
    if not is_equal_approx(m_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_mult: tight lane want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_tight]
            )
        )
    if not is_equal_approx(m_empty_allows, 1.0):
        CombatRegressionHarness._fail(
            failures,
            "depth_spear_parry_mult: empty lane_type + allows_low should follow open got %.4f" % m_empty_allows
        )
    if not is_equal_approx(m_empty_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_mult: empty lane_type + tight allows_low want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_empty_tight]
            )
        )
    var pa_open: Dictionary = {
        "depth_polearm_attack": true,
        "depth_polearm_allows_low_targets": true,
        "depth_polearm_lane_type": "open",
    }
    var pa_tight: Dictionary = {
        "depth_polearm_attack": true,
        "depth_polearm_allows_low_targets": false,
        "depth_polearm_lane_type": "over_shoulder",
    }
    var a_stab: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "thrust")
    var pa_baseline_lane: Dictionary = {
        "depth_polearm_attack": true,
        "depth_polearm_allows_low_targets": true,
        "depth_polearm_lane_type": "",
    }
    var a_baseline_stab: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult(
        pa_baseline_lane, "thrust"
    )
    var a_tight_stab: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult(pa_tight, "thrust")
    var a_slash: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "slash")
    var a0: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult({}, "thrust")
    if not is_equal_approx(a_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_p_a: open+stab want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_stab]
            )
        )
    if not is_equal_approx(a_baseline_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_p_a: empty lane_type + allows_low stab want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_baseline_stab]
            )
        )
    var pa_open_tight_bool: Dictionary = {
        "depth_polearm_attack": true,
        "depth_polearm_allows_low_targets": false,
        "depth_polearm_lane_type": "open",
    }
    var a_open_id_over_allows: float = DefenseChoiceResolver.depth_spear_open_lane_stab_parry_p_a_mult(
        pa_open_tight_bool, "thrust"
    )
    if not is_equal_approx(a_open_id_over_allows, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_p_a: explicit open lane id should win over allows_low=false got %.4f"
                % a_open_id_over_allows
            )
        )
    if not is_equal_approx(a_tight_stab, 1.0) or not is_equal_approx(a_slash, 1.0) or not is_equal_approx(a0, 1.0):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_parry_p_a: expected 1.0 for tight stab / open slash / non-depth got tight=%.4f slash=%"
                + ".4f a0=%.4f" % [a_tight_stab, a_slash, a0]
            )
        )


## Tier 3.1: **`CombatConstants.STRIKE_MEASURE_*`** drive **`strike_measure_ratio_for_weapon_eff_dist`** (formula lock).


## Tier 3.1: **`CombatConstants.STRIKE_MEASURE_*`** drive **`strike_measure_ratio_for_weapon_eff_dist`** (formula lock).
static func _run_depth_spear_thrust_closing_factor_invariant(failures: PackedStringArray) -> void:
    var f0: float = StrikePhysics.depth_polearm_thrust_closing_factor({})
    var f_cut: float = StrikePhysics.depth_polearm_thrust_closing_factor(
        {"depth_polearm_attack": true, "attack_type": "spear_slash"}
    )
    var f_stab: float = StrikePhysics.depth_polearm_thrust_closing_factor(
        {"depth_polearm_attack": true, "attack_type": "spear_thrust"}
    )
    var f_stab_open: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "open",
            }
        )
    )
    var f_stab_tight: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "over_shoulder",
            }
        )
    )
    var f_stab_shoulder_overrides_allows: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "over_shoulder",
                "depth_polearm_allows_low_targets": true,
            }
        )
    )
    var f_stab_empty_tight: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "",
                "depth_polearm_allows_low_targets": false,
            }
        )
    )
    var f_stab_garbage_tight: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "bogus",
                "depth_polearm_allows_low_targets": false,
            }
        )
    )
    var f_stab_open_ignores_allows: float = (
        StrikePhysics
        . depth_polearm_thrust_closing_factor(
            {
                "depth_polearm_attack": true,
                "attack_type": "spear_thrust",
                "depth_polearm_lane_type": "open",
                "depth_polearm_allows_low_targets": false,
            }
        )
    )
    if not is_equal_approx(f0, 1.0) or not is_equal_approx(f_cut, 1.0):
        CombatRegressionHarness._fail(
            failures, "depth_spear_closing: expected 1.0 for empty / non-stab got f0=%.4f f_cut=%.4f" % [f0, f_cut]
        )
    if not is_equal_approx(f_stab, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_closing: stab want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab]
            )
        )
    if not is_equal_approx(f_stab_open, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_closing: stab+open lane want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open]
            )
        )
    if not is_equal_approx(f_stab_tight, 1.0):
        CombatRegressionHarness._fail(failures, "depth_spear_closing: stab+tight lane want 1.0 got %.4f" % f_stab_tight)
    if not is_equal_approx(f_stab_shoulder_overrides_allows, 1.0):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_closing: over_shoulder lane id must override allows_low=true got %.4f"
                % f_stab_shoulder_overrides_allows
            )
        )
    if not is_equal_approx(f_stab_empty_tight, 1.0):
        CombatRegressionHarness._fail(
            failures, "depth_spear_closing: empty lane + allows_low false want 1.0 got %.4f" % f_stab_empty_tight
        )
    if not is_equal_approx(f_stab_garbage_tight, 1.0):
        CombatRegressionHarness._fail(
            failures, "depth_spear_closing: unknown lane + allows_low false want 1.0 got %.4f" % f_stab_garbage_tight
        )
    if not is_equal_approx(f_stab_open_ignores_allows, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "depth_spear_closing: explicit open lane should ignore allows_low want %.4f got %.4f"
                % [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open_ignores_allows]
            )
        )


## Tier 1.6: **`ordered_melee_opponents`**  -  **`is_melee_file_opposed_priority`** sorts **before**
## **`hostile_pair_targeting_weight_mult`** (same-file rank-0 line pair ahead of lateral rank-0).


## Tier 1.6: **`ordered_melee_opponents`**  -  **`is_melee_file_opposed_priority`** sorts **before**
## **`hostile_pair_targeting_weight_mult`** (same-file rank-0 line pair ahead of lateral rank-0).
static func _run_spear_lane_profile_preset_normalized(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start(
        {"files": 1, "ranks": 1, "density": "normal", CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE: "full"},
        {"files": 1, "ranks": 1}
    )
    var sp: String = str(mgr.formations["player"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
    if sp != CombatConstants.SPEAR_LANE_PROFILE_OPEN:
        CombatRegressionHarness._fail(failures, "spear_lane_preset: expected open from alias 'full' got %s" % sp)
    var se: String = str(mgr.formations["enemy"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
    if se != CombatConstants.SPEAR_LANE_PROFILE_AUTO:
        CombatRegressionHarness._fail(
            failures, "spear_lane_preset: enemy default profile should be auto/empty got %s" % se
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`Weapon.depth_melee_eligible`** from **`WeaponConstants`** definitions  -  **SPEAR** **true**; **SWORD**
## default **false** ( **`CombatDepthPolearm.depth_polearm_lane_open`** gate).


## Tier 1.9: **`Weapon.depth_melee_eligible`** from **`WeaponConstants`** definitions  -  **SPEAR** **true**; **SWORD**
## default **false** ( **`CombatDepthPolearm.depth_polearm_lane_open`** gate).
static func _run_weapon_depth_melee_eligible_fixture(failures: PackedStringArray) -> void:
    var w_spear: Weapon = Weapon.create_from_definition("SPEAR")
    var w_sword: Weapon = Weapon.create_from_definition("SWORD")
    if w_spear == null or w_sword == null:
        CombatRegressionHarness._fail(failures, "depth_melee_elig: missing weapon fixtures")
        return
    if not w_spear.depth_melee_eligible:
        CombatRegressionHarness._fail(failures, "depth_melee_elig: SPEAR should be depth_melee_eligible")
    if w_sword.depth_melee_eligible:
        CombatRegressionHarness._fail(failures, "depth_melee_elig: SWORD should not be depth_melee_eligible by default")


## Tier 1.9: rank>1 without **`depth_melee_eligible`** weapon -> **`depth_polearm_lane_open`** **false** even with
## same-file living rank-0 ally (lane predicate, not only **`can_melee_threaten`**).


## Tier 1.9: rank>1 without **`depth_melee_eligible`** weapon -> **`depth_polearm_lane_open`** **false** even with
## same-file living rank-0 ally (lane predicate, not only **`can_melee_threaten`**).
static func _run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth_sw: Dictionary = mgr.combatants[1]
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, depth_sw):
        CombatRegressionHarness._fail(
            failures, "depth_lane_non_eligible: rank-1 sword must not open depth polearm lane (rank-0 ally present)"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** at **`rank` <= 0** (lane is for **home** depth ranks only).


## Tier 1.9: **`depth_polearm_lane_open`** is **false** at **`rank` <= 0** (lane is for **home** depth ranks only).
static func _run_depth_polearm_lane_open_false_at_rank_zero(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var front: Dictionary = mgr.combatants[0]
    if CombatantEntityAccess.rank_int(front) != 0:
        CombatRegressionHarness._fail(
            failures,
            "depth_lane_r0: expected player spear at rank 0 got rank %s" % str(CombatantEntityAccess.rank_int(front))
        )
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, front):
        CombatRegressionHarness._fail(failures, "depth_lane_r0: rank-0 spear must not open depth polearm lane")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: no **living** same-file rank-0 partner -> **`depth_polearm_lane_open`** **false** (even with
## **`depth_melee_eligible`** weapon).


## Tier 1.9: no **living** same-file rank-0 partner -> **`depth_polearm_lane_open`** **false** (even with
## **`depth_melee_eligible`** weapon).
static func _run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var depth_f1: Dictionary = {}
    var front_f1: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.file_int(c) != 1:
            continue
        if CombatantEntityAccess.rank_int(c) == 1:
            depth_f1 = c
        elif CombatantEntityAccess.rank_int(c) == 0:
            front_f1 = c
    if depth_f1.is_empty() or front_f1.is_empty():
        CombatRegressionHarness._fail(failures, "depth_lane_no_r0: expected player rank-0 + rank-1 at file 1")
        CombatRegressionHarness._free_manager(mgr)
        return
    front_f1["alive"] = false
    mgr.recompute_zoc_and_distance()
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, depth_f1):
        CombatRegressionHarness._fail(
            failures, "depth_lane_no_r0: rank-1 spear file 1 must not open lane when same-file rank-0 is dead"
        )
    var depth_f0: Dictionary = {}
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.file_int(c) == 0 and CombatantEntityAccess.rank_int(c) == 1:
            depth_f0 = c
            break
    if depth_f0.is_empty():
        CombatRegressionHarness._fail(failures, "depth_lane_no_r0: expected player rank-1 at file 0")
    elif not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth_f0):
        CombatRegressionHarness._fail(
            failures, "depth_lane_no_r0: rank-1 spear file 0 should still open lane (living same-file rank-0 at file 0)"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`CombatDistanceBands.depth_polearm_lane_open_by_combatant_id`** matches
## **`CombatDepthPolearm.depth_polearm_lane_open`** ( **`zone_geometry_fid_str`** `fid` ).


## Tier 1.9: **`CombatDistanceBands.depth_polearm_lane_open_by_combatant_id`** matches
## **`CombatDepthPolearm.depth_polearm_lane_open`** ( **`zone_geometry_fid_str`** `fid` ).
static func _run_depth_polearm_lane_cache_matches_builder(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    mgr.recompute_zoc_and_distance()
    CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:1file")
    CombatRegressionHarness._free_manager(mgr)

    var mgr2: Node = CombatManager.new()
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr2.start({"files": 2, "ranks": 2, "density": "normal"}, e_preset)
    var front_f1: Dictionary = {}
    for c in mgr2.combatants:
        if not CombatantEntityAccess.is_player_side(c):
            continue
        if CombatantEntityAccess.file_int(c) != 1 or CombatantEntityAccess.rank_int(c) != 0:
            continue
        front_f1 = c
        break
    if front_f1.is_empty():
        CombatRegressionHarness._fail(failures, "depth_lane_cache:2wide expected rank-0 file 1")
        CombatRegressionHarness._free_manager(mgr2)
        return
    front_f1["alive"] = false
    mgr2.recompute_zoc_and_distance()
    CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(
        mgr2, failures, "depth_lane_cache:2wide_dead_r0f1"
    )
    CombatRegressionHarness._free_manager(mgr2)


## Tier 1.9: same-file rank-0 partner **incapacitated** -> **`depth_polearm_lane_open`** **false**
## (**`same_file_living_rank0_ally`** skips incap).


## Tier 1.9: same-file rank-0 partner **incapacitated** -> **`depth_polearm_lane_open`** **false**
## (**`same_file_living_rank0_ally`** skips incap).
static func _run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var ent_r0: CoreEntity = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ent_r0, "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var front: Dictionary = mgr.combatants[0]
    var depth: Dictionary = mgr.combatants[1]
    ent_r0.consciousness = 5.0
    mgr.recompute_zoc_and_distance()
    if not CombatantEntityAccess.is_incapacitated(front):
        CombatRegressionHarness._fail(failures, "depth_lane_r0_incap: rank-0 ally should read incapacitated")
        CombatRegressionHarness._free_manager(mgr)
        return
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(
            failures, "depth_lane_r0_incap: rank-1 spear must not open lane when same-file rank-0 is incapacitated"
        )
    CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:r0_incap")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open(manager, c, "")`** matches **`depth_polearm_lane_open(manager, c, fid)`** when
## **`fid == zone_geometry_fid_str(manager, c)`** (explicit **`zone_geometry_fid`** contract).


## Tier 1.9: **`depth_polearm_lane_open(manager, c, "")`** matches **`depth_polearm_lane_open(manager, c, fid)`** when
## **`fid == zone_geometry_fid_str(manager, c)`** (explicit **`zone_geometry_fid`** contract).
static func _run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c):
            continue
        var fid: String = ZoneOfControl.zone_geometry_fid_str(mgr, c)
        var o_default: bool = CombatDepthPolearm.depth_polearm_lane_open(mgr, c, "")
        var o_explicit: bool = CombatDepthPolearm.depth_polearm_lane_open(mgr, c, fid)
        if o_default != o_explicit:
            CombatRegressionHarness._fail(
                failures,
                (
                    "depth_lane_fid_rt: id=%d default=%s explicit_fid=%s fid=%s"
                    % [CombatantEntityAccess.id_int(c), str(o_default), str(o_explicit), fid]
                )
            )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`**  -  open depth lane + **strict** + **tight** + no lane stress
## -> **false** (over-shoulder); **`spear_lane_profile` open** on same geometry -> **true**.


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`**  -  open depth lane + **strict** + **tight** + no lane stress
## -> **false** (over-shoulder); **`spear_lane_profile` open** on same geometry -> **true**.
static func _run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        CombatRegressionHarness._fail(failures, "depth_allows_low: expected open depth polearm lane for setup")
        CombatRegressionHarness._free_manager(mgr)
        return
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
    if CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth):
        CombatRegressionHarness._fail(
            failures, "depth_allows_low: strict+tight+lane open+no wedge should not allow low targets"
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    if not CombatDepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth):
        CombatRegressionHarness._fail(
            failures, "depth_allows_low: spear_lane_profile open should allow low targets on tight formation"
        )
    CombatRegressionHarness._free_manager(mgr)

## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** **`pa`** depth keys match
## **`depth_polearm_lane_allows_low_targets`** ( **`assume_depth_lane_open` true** ) and
## **`DEPTH_POLEARM_LANE_TYPE_*`**.
