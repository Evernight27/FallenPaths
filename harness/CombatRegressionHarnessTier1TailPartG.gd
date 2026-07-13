class_name CombatRegressionHarnessTier1TailPartG
extends RefCounted

## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _run_surround_sector_load_formula(failures: PackedStringArray) -> void:
    var d: Dictionary = {"stats": {"perception": 100.0}}
    var m_int_two_threats: float = TacticalCombat.surround_defense_multiplier(d, 2)
    var m_sector: float = TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)
    if not is_equal_approx(m_int_two_threats, m_sector):
        CombatRegressionHarness._fail(
            failures, "surround_sector: int n=2 %.4f vs sector wsum=2 %.4f" % [m_int_two_threats, m_sector]
        )
    var m_mild: float = TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 1.15)
    if m_mild <= m_int_two_threats + 0.01:
        CombatRegressionHarness._fail(
            failures,
            (
                "surround_sector: compressed wsum=1.15 should be milder than int n=2 (%.4f vs %.4f)"
                % [m_mild, m_int_two_threats]
            )
        )


## Tier 3.1: two adjacent-file enemies vs center defender  -  summed sector weight stays below two full flank weights.


## Tier 3.1: two adjacent-file enemies vs center defender  -  summed sector weight stays below two full flank weights.
static func _run_surround_threat_weight_sum_three_file_line(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.combatants[0]["file"] = 1
    mgr.combatants[1]["file"] = 0
    mgr.combatants[2]["file"] = 2
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var def_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    if TacticalCombat.count_engaging_threats(mgr, def_id) != 2:
        CombatRegressionHarness._fail(failures, "surround_weight_sum: expected two engaging threats")
        CombatRegressionHarness._free_manager(mgr)
        return
    var wsum: float = TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
    if wsum >= 2.0 - 0.02:
        CombatRegressionHarness._fail(
            failures, "surround_weight_sum: adjacent pair should sum < 2 full weights, got %.4f" % wsum
        )
    if wsum < 0.9:
        CombatRegressionHarness._fail(
            failures, "surround_weight_sum: expected meaningful stacked weight, got %.4f" % wsum
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: **`surround_defense_multiplier_from_pa_with_sector`**  -  integer **`surround_threat_count`** vs sector
## **`surround_threat_weight_sum`** (explicit flag; production uses **`is_feature_sector_surround_load`**).


## Tier 3.1: **`surround_defense_multiplier_from_pa_with_sector`**  -  integer **`surround_threat_count`** vs sector
## **`surround_threat_weight_sum`** (explicit flag; production uses **`is_feature_sector_surround_load`**).
static func _run_surround_defense_multiplier_from_pa_both_paths(failures: PackedStringArray) -> void:
    var d: Dictionary = {"stats": {"perception": 100.0}}
    var pa_two: Dictionary = {"surround_threat_count": 2}
    var m_int_path: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, false)
    var m_sector_equiv: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, true)
    if not is_equal_approx(m_int_path, TacticalCombat.surround_defense_multiplier(d, 2)):
        CombatRegressionHarness._fail(
            failures, "surround_from_pa: int path should match surround_defense_multiplier(n=2)"
        )
    if not is_equal_approx(m_sector_equiv, TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)):
        CombatRegressionHarness._fail(failures, "surround_from_pa: sector path with count-only pa should match wsum=2")
    if not is_equal_approx(m_int_path, m_sector_equiv):
        CombatRegressionHarness._fail(
            failures, "surround_from_pa: n=2 int vs sector(count fallback) %.6f vs %.6f" % [m_int_path, m_sector_equiv]
        )
    var pa_mixed: Dictionary = {"surround_threat_count": 2, "surround_threat_weight_sum": 1.15}
    var m_split_two: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, false)
    var m_sector_mild: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, true)
    if not is_equal_approx(m_split_two, m_int_path):
        CombatRegressionHarness._fail(failures, "surround_from_pa: mixed pa int path should still use count=2")
    if m_sector_mild <= m_split_two + 0.001:
        CombatRegressionHarness._fail(
            failures,
            "surround_from_pa: sector wsum=1.15 should beat int n=2 split (%.6f vs %.6f)" % [m_sector_mild, m_split_two]
        )


## Tier 3.1: live **`compute_surround_threat_weight_sum`** matches
## **`surround_defense_multiplier_from_pa_with_sector(..., true)`** with **`pa`** shaped like **`AttackResolver`**
## (count + weight sum).


## Tier 3.1: live **`compute_surround_threat_weight_sum`** matches
## **`surround_defense_multiplier_from_pa_with_sector(..., true)`** with **`pa`** shaped like **`AttackResolver`**
## (count + weight sum).
static func _run_surround_live_weight_sum_matches_from_pa_sector_path(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.combatants[0]["file"] = 1
    mgr.combatants[1]["file"] = 0
    mgr.combatants[2]["file"] = 2
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var def: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var n_threats: int = TacticalCombat.count_engaging_threats(mgr, def_id)
    if n_threats != 2:
        CombatRegressionHarness._fail(failures, "surround_live_pa: expected two engaging threats got %d" % n_threats)
        CombatRegressionHarness._free_manager(mgr)
        return
    var wsum: float = TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
    if wsum >= 2.0 - 0.02 or wsum < 0.9:
        CombatRegressionHarness._fail(
            failures, "surround_live_pa: unexpected wsum=%.4f (want compressed flank pair)" % wsum
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
    var m_sector: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
    var m_ref: float = TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)
    if not is_equal_approx(m_sector, m_ref):
        CombatRegressionHarness._fail(
            failures, "surround_live_pa: sector from_pa %.6f vs harness wsum ref %.6f" % [m_sector, m_ref]
        )
    var m_int: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
    var m_int_ref: float = TacticalCombat.surround_defense_multiplier(def, n_threats)
    if not is_equal_approx(m_int, m_int_ref):
        CombatRegressionHarness._fail(
            failures, "surround_live_pa: int from_pa %.6f vs surround_defense_multiplier %.6f" % [m_int, m_int_ref]
        )
    if m_sector <= m_int + 0.001:
        CombatRegressionHarness._fail(
            failures,
            (
                "surround_live_pa: sector path should be milder than int n=2 (%.6f vs %.6f) wsum=%.4f"
                % [m_sector, m_int, wsum]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: one engaging threat  -  integer **n<=1** and sector **`wsum`<=`SURROUND_SECTOR_LOAD_FREE`** both stay
## neutral (**1.0**).


## Tier 3.1: one engaging threat  -  integer **n<=1** and sector **`wsum`<=`SURROUND_SECTOR_LOAD_FREE`** both stay
## neutral (**1.0**).
static func _run_surround_single_threat_int_and_sector_neutral(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var def: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var n_threats: int = TacticalCombat.count_engaging_threats(mgr, def_id)
    if n_threats != 1:
        CombatRegressionHarness._fail(failures, "surround_single: expected one engaging threat got %d" % n_threats)
        CombatRegressionHarness._free_manager(mgr)
        return
    var wsum: float = TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
    if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + 0.02:
        CombatRegressionHarness._fail(
            failures,
            (
                "surround_single: wsum=%.4f should sit in free tier (<=%.3f)"
                % [wsum, CombatConstants.SURROUND_SECTOR_LOAD_FREE]
            )
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
    var m_int: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
    var m_sec: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
    if not is_equal_approx(m_int, 1.0):
        CombatRegressionHarness._fail(failures, "surround_single: int path want 1.0 got %.6f" % m_int)
    if not is_equal_approx(m_sec, 1.0):
        CombatRegressionHarness._fail(
            failures, "surround_single: sector path want 1.0 got %.6f (wsum=%.4f)" % [m_sec, wsum]
        )
    if not is_equal_approx(m_sec, TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)):
        CombatRegressionHarness._fail(failures, "surround_single: sector from_pa vs harness ref mismatch")
    CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: **`is_feature_sector_surround_load`**  -  `surround_defense_multiplier_from_pa` follows runtime toggle (int
## path off, sector path on).


## Tier 3.1: **`is_feature_sector_surround_load`**  -  `surround_defense_multiplier_from_pa` follows runtime toggle (int
## path off, sector path on).
static func _run_sector_surround_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
    var prev_flag: bool = CombatConstants.is_feature_sector_surround_load()
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.combatants[0]["file"] = 1
    mgr.combatants[1]["file"] = 0
    mgr.combatants[2]["file"] = 2
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var def: Dictionary = mgr.combatants[0]
    var def_id: int = CombatantEntityAccess.id_int(def)
    var n_threats: int = TacticalCombat.count_engaging_threats(mgr, def_id)
    var wsum: float = TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
    var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
    if n_threats != 2 or wsum >= 2.0 - 0.02 or wsum < 0.9:
        CombatConstants.set_feature_sector_surround_load(prev_flag)
        CombatRegressionHarness._free_manager(mgr)
        CombatRegressionHarness._fail(
            failures, "sector_flag_toggle: need compressed two-threat layout (n=%d wsum=%.4f)" % [n_threats, wsum]
        )
        return
    var m_int: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
    var m_sec: float = TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
    CombatConstants.set_feature_sector_surround_load(false)
    var from_pa_off: float = TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
    if not is_equal_approx(from_pa_off, m_int):
        CombatConstants.set_feature_sector_surround_load(prev_flag)
        CombatRegressionHarness._free_manager(mgr)
        CombatRegressionHarness._fail(
            failures, "sector_flag_toggle: flag off from_pa %.6f vs int ref %.6f" % [from_pa_off, m_int]
        )
        return
    CombatConstants.set_feature_sector_surround_load(true)
    var from_pa_on: float = TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
    if not is_equal_approx(from_pa_on, m_sec):
        CombatConstants.set_feature_sector_surround_load(prev_flag)
        CombatRegressionHarness._free_manager(mgr)
        CombatRegressionHarness._fail(
            failures, "sector_flag_toggle: flag on from_pa %.6f vs sector ref %.6f" % [from_pa_on, m_sec]
        )
        return
    if from_pa_on <= from_pa_off + 0.001:
        CombatConstants.set_feature_sector_surround_load(prev_flag)
        CombatRegressionHarness._free_manager(mgr)
        CombatRegressionHarness._fail(
            failures,
            (
                "sector_flag_toggle: sector-on %.6f should exceed int-off %.6f (milder surround)"
                % [from_pa_on, from_pa_off]
            )
        )
        return
    CombatConstants.set_feature_sector_surround_load(prev_flag)
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `posture_cohesion_targeting_mult` rises with line cohesion in LINE posture; OPEN uses inverse (looser line
## -> higher mult).


## Tier 1.6: `posture_cohesion_targeting_mult` rises with line cohesion in LINE posture; OPEN uses inverse (looser line
## -> higher mult).
static func _run_ai_targeting_posture_cohesion_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var pfid: String = CombatantEntityAccess.formation_id_str(p)
    var fd: Dictionary = FormationSlots.formation_record_for_manager(mgr, pfid)
    fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    fd["line_cohesion"] = 0.0
    var m_line_lo: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p)
    fd["line_cohesion"] = 1.0
    var m_line_hi: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p)
    if m_line_hi < m_line_lo + 0.001:
        CombatRegressionHarness._fail(
            failures,
            "ai_targeting_posture: LINE mult should increase with cohesion (lo=%.4f hi=%.4f)" % [m_line_lo, m_line_hi]
        )
    fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
    fd["line_cohesion"] = 1.0
    var m_open_tight: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p)
    fd["line_cohesion"] = 0.0
    var m_open_loose: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p)
    if m_open_loose < m_open_tight + 0.001:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_posture: OPEN mult should increase when cohesion drops (tight=%.4f loose=%.4f)"
                % [m_open_tight, m_open_loose]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`distributed_pressure_mult`**  -  ally doctrine commit to the same defender lowers
## **`hostile_pair_targeting_weight_mult`** for a second attacker (cached engagement-mode mult so snapshot stays
## stable).


## Tier 1.6: **`distributed_pressure_mult`**  -  ally doctrine commit to the same defender lowers
## **`hostile_pair_targeting_weight_mult`** for a second attacker (cached engagement-mode mult so snapshot stays
## stable).
static func _run_hostile_pair_distributed_pressure_ally_commit(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.combat_clock = 10.0
    mgr.recompute_zoc_and_distance()
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var e0: Dictionary = mgr.combatants[2]
    if not CombatantEntityAccess.is_player_side(p0) or not CombatantEntityAccess.is_player_side(p1):
        CombatRegressionHarness._fail(failures, "dist_pressure: expected first two combatants on player side")
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatantEntityAccess.is_enemy_side(e0):
        CombatRegressionHarness._fail(failures, "dist_pressure: expected third combatant enemy")
        CombatRegressionHarness._free_manager(mgr)
        return
    p0["doctrine_target_commit_id"] = -1
    p1["doctrine_target_commit_id"] = -1
    var p0id: int = CombatantEntityAccess.id_int(p0)
    var p1id: int = CombatantEntityAccess.id_int(p1)
    var e0id: int = CombatantEntityAccess.id_int(e0)
    var m_mode: float = CombatTargetScoring.engagement_mode_targeting_mult(mgr)
    var dp_none: float = CombatTargetScoring.distributed_pressure_mult(mgr, p0, e0id)
    var w_before: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
    CombatTargetScoring.on_combat_commitment(mgr, p1id, e0id)
    var dp_ally: float = CombatTargetScoring.distributed_pressure_mult(mgr, p0, e0id)
    var w_after: float = CombatTargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
    if dp_ally >= dp_none - 1e-6:
        CombatRegressionHarness._fail(
            failures,
            "dist_pressure: distributed mult should drop when ally commits none=%.6f ally=%.6f" % [dp_none, dp_ally]
        )
    if w_after >= w_before - 1e-6:
        CombatRegressionHarness._fail(
            failures, "dist_pressure: hostile weight should drop before=%.6f after=%.6f" % [w_before, w_after]
        )
    var cnt: int = CombatTargetScoring.ally_pressure_count(mgr, e0id, "player", p0id)
    if cnt != 1:
        CombatRegressionHarness._fail(failures, "dist_pressure: expected ally_pressure_count=1 got %d" % cnt)
    p1["doctrine_target_commit_id"] = -1
    p1.erase("doctrine_commit_until")
    var dp_restored: float = CombatTargetScoring.distributed_pressure_mult(mgr, p0, e0id)
    if not is_equal_approx(dp_restored, dp_none):
        CombatRegressionHarness._fail(
            failures,
            (
                "dist_pressure: clearing commit should restore pressure mult restored=%.6f none=%.6f"
                % [dp_restored, dp_none]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / 1.9: **`CombatTargetScoring.ally_pressure_count`**  -  committed rank>0 allies count only when
## **`CombatMeleeRankTargeting.melee_pair_rank_allowed`** to the committed defender
## (**`depth_polearm_valid_line_threat`** for home depth vs rank-0).


## Tier 1.6 / 1.9: **`CombatTargetScoring.ally_pressure_count`**  -  committed rank>0 allies count only when
## **`CombatMeleeRankTargeting.melee_pair_rank_allowed`** to the committed defender
## (**`depth_polearm_valid_line_threat`** for home depth vs rank-0).
static func _run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures: PackedStringArray) -> void:
    var mgr_near: Node = CombatManager.new()
    mgr_near.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_near.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr_near.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_near.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    for c in mgr_near.combatants:
        c["gauge"] = 100.0
    mgr_near.combat_clock = 10.0
    mgr_near.recompute_zoc_and_distance()
    var p0n: Dictionary = mgr_near.combatants[0]
    var p1n: Dictionary = mgr_near.combatants[1]
    var e0n: Dictionary = mgr_near.combatants[2]
    var p0nid: int = CombatantEntityAccess.id_int(p0n)
    var p1nid: int = CombatantEntityAccess.id_int(p1n)
    var e0nid: int = CombatantEntityAccess.id_int(e0n)
    if not CombatMeleeRankTargeting.melee_pair_rank_allowed(mgr_near, p1n, e0n):
        CombatRegressionHarness._fail(
            failures, "ally_press_dep: near layout expected _melee_pair_rank_allowed depth->e0"
        )
        CombatRegressionHarness._free_manager(mgr_near)
        return
    CombatTargetScoring.on_combat_commitment(mgr_near, p1nid, e0nid)
    var cnt_near: int = CombatTargetScoring.ally_pressure_count(mgr_near, e0nid, "player", p0nid)
    if cnt_near != 1:
        CombatRegressionHarness._fail(failures, "ally_press_dep: near expected ally_pressure_count=1 got %d" % cnt_near)
    p1n["doctrine_target_commit_id"] = -1
    CombatRegressionHarness._free_manager(mgr_near)

    var mgr_far: Node = CombatManager.new()
    mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr_far.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    for _i in 3:
        mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    for c2 in mgr_far.combatants:
        c2["gauge"] = 100.0
    mgr_far.combat_clock = 10.0
    mgr_far.recompute_zoc_and_distance()
    var depth_far: Dictionary = mgr_far.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr_far, depth_far):
        CombatRegressionHarness._fail(failures, "ally_press_dep: far layout expected open depth lane")
        CombatRegressionHarness._free_manager(mgr_far)
        return
    for i in range(2, 5):
        (mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
    mgr_far.recompute_zoc_and_distance()
    var e0_far: Dictionary = mgr_far.combatants[2]
    if CombatMeleeRankTargeting.melee_pair_rank_allowed(mgr_far, depth_far, e0_far):
        CombatRegressionHarness._fail(
            failures, "ally_press_dep: far enemies expected no _melee_pair_rank_allowed depth->e0"
        )
        CombatRegressionHarness._free_manager(mgr_far)
        return
    var p0f: Dictionary = mgr_far.combatants[0]
    var p0fid: int = CombatantEntityAccess.id_int(p0f)
    var e0fid: int = CombatantEntityAccess.id_int(e0_far)
    var p1fid: int = CombatantEntityAccess.id_int(depth_far)
    CombatTargetScoring.on_combat_commitment(mgr_far, p1fid, e0fid)
    var cnt_far: int = CombatTargetScoring.ally_pressure_count(mgr_far, e0fid, "player", p0fid)
    if cnt_far != 0:
        CombatRegressionHarness._fail(
            failures, "ally_press_dep: far-line committed depth should not count pressure got %d" % cnt_far
        )
    CombatRegressionHarness._free_manager(mgr_far)


## Tier 1.6: **`CombatTargetScoring.hold_lane_mult`**  -  **`hold_lane`** doctrine hedges listed weights vs
## **non**-file-opposed rank-0 pairs; file-opposed front returns **1.0**.


## Tier 1.6: **`CombatTargetScoring.hold_lane_mult`**  -  **`hold_lane`** doctrine hedges listed weights vs
## **non**-file-opposed rank-0 pairs; file-opposed front returns **1.0**.
static func _run_targeting_hold_lane_off_file_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    var p: Dictionary = mgr.combatants[0]
    var e_anchor: Dictionary = mgr.combatants[1]
    var e: Dictionary = mgr.combatants[2]
    p["file"] = 0
    e_anchor["file"] = 0
    e["file"] = 1
    p["rank"] = 0
    e_anchor["rank"] = 0
    e["rank"] = 0
    mgr.recompute_zoc_and_distance()
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    var m_off: float = CombatTargetScoring.hold_lane_mult(mgr, p, e)
    if not is_equal_approx(m_off, CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "hold_lane_mult: off-file expected %.4f got %.4f"
                % [CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT, m_off]
            )
        )
    e["file"] = 0
    mgr.recompute_zoc_and_distance()
    var m_same: float = CombatTargetScoring.hold_lane_mult(mgr, p, e)
    if not is_equal_approx(m_same, 1.0):
        CombatRegressionHarness._fail(
            failures, "hold_lane_mult: file-opposed front should be neutral got %.4f" % m_same
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    var m_pinch: float = CombatTargetScoring.hold_lane_mult(mgr, p, e)
    if not is_equal_approx(m_pinch, 1.0):
        CombatRegressionHarness._fail(
            failures, "hold_lane_mult: pinch doctrine should not apply hold hedge got %.4f" % m_pinch
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    if not is_equal_approx(CombatTargetScoring.hold_lane_mult(mgr, p, e), 1.0):
        CombatRegressionHarness._fail(failures, "hold_lane_mult: default doctrine should be neutral")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.file_opposed_mult`**  -  same-file rank-0 pair (or depth polearm using same-file
## rank-0 ally) applies **`DOCTRINE_FILE_OPPOSED_WEIGHT_MULT`**; off-file -> **1.0**.


## Tier 1.6: **`CombatTargetScoring.file_opposed_mult`**  -  same-file rank-0 pair (or depth polearm using same-file
## rank-0 ally) applies **`DOCTRINE_FILE_OPPOSED_WEIGHT_MULT`**; off-file -> **1.0**.
static func _run_targeting_file_opposed_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    var p: Dictionary = mgr.combatants[0]
    var e_anchor: Dictionary = mgr.combatants[1]
    var e: Dictionary = mgr.combatants[2]
    p["file"] = 0
    e_anchor["file"] = 0
    e["file"] = 1
    p["rank"] = 0
    e_anchor["rank"] = 0
    e["rank"] = 0
    mgr.recompute_zoc_and_distance()
    var m_off: float = CombatTargetScoring.file_opposed_mult(mgr, p, e)
    if not is_equal_approx(m_off, 1.0):
        CombatRegressionHarness._fail(failures, "file_opposed_mult: off-file rank-0 expected 1.0 got %.4f" % m_off)
    e["file"] = 0
    mgr.recompute_zoc_and_distance()
    var m_front: float = CombatTargetScoring.file_opposed_mult(mgr, p, e)
    if not is_equal_approx(m_front, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "file_opposed_mult: same-file rank-0 expected %.4f got %.4f"
                % [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_front]
            )
        )
    CombatRegressionHarness._free_manager(mgr)
    var mgr2: Node = CombatManager.new()
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    var p2_preset := {"files": 2, "ranks": 2, "density": "normal"}
    var e2_preset := {"files": 2, "ranks": 1, "density": "normal"}
    mgr2.start(p2_preset, e2_preset)
    for c in mgr2.combatants:
        c["gauge"] = 100.0
    var front: Dictionary = mgr2.combatants[0]
    var depth: Dictionary = mgr2.combatants[1]
    var en_same: Dictionary = mgr2.combatants[2]
    var en_off: Dictionary = mgr2.combatants[3]
    front["file"] = 0
    front["rank"] = 0
    depth["file"] = 0
    depth["rank"] = 1
    en_same["file"] = 0
    en_same["rank"] = 0
    en_off["file"] = 1
    en_off["rank"] = 0
    mgr2.recompute_zoc_and_distance()
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr2, depth):
        CombatRegressionHarness._fail(failures, "file_opposed_mult_depth: expected depth spear lane open")
        CombatRegressionHarness._free_manager(mgr2)
        return
    var m_depth_same: float = CombatTargetScoring.file_opposed_mult(mgr2, depth, en_same)
    if not is_equal_approx(m_depth_same, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "file_opposed_mult_depth: front ally file-opposed expected %.4f got %.4f"
                % [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_depth_same]
            )
        )
    var m_depth_off: float = CombatTargetScoring.file_opposed_mult(mgr2, depth, en_off)
    if not is_equal_approx(m_depth_off, 1.0):
        CombatRegressionHarness._fail(
            failures, "file_opposed_mult_depth: off-file enemy expected 1.0 got %.4f" % m_depth_off
        )
    CombatRegressionHarness._free_manager(mgr2)


## Tier 1.6: **`CombatTargetScoring.pinch_score_mult`**  -  **`pinch_center`** + **`wing_lacks_file_opposed`** nudges
## weight toward enemies nearer the hostile line center ( **`DOCTRINE_PINCH_INWARD_BIAS_PER_FILE`** ).


## Tier 1.6: **`CombatTargetScoring.pinch_score_mult`**  -  **`pinch_center`** + **`wing_lacks_file_opposed`** nudges
## weight toward enemies nearer the hostile line center ( **`DOCTRINE_PINCH_INWARD_BIAS_PER_FILE`** ).
static func _run_targeting_pinch_center_inward_bonus(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    p["file"] = 0
    e["file"] = 1
    p["rank"] = 0
    e["rank"] = 1
    mgr.recompute_zoc_and_distance()
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
    if not CombatTargetScoring.wing_lacks_file_opposed(mgr, p):
        CombatRegressionHarness._fail(
            failures, "pinch_bonus: expected wing_lacks (no rank-0 mapped opposition; depth-only hostile)"
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    var ec: float = 0.0
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, "enemy"):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        ec = float(CombatantEntityAccess.file_int(c))
        break
    var inward: float = absf(float(CombatantEntityAccess.file_int(e)) - ec)
    var want: float = 1.0 + CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
    var m_pinch: float = CombatTargetScoring.pinch_score_mult(mgr, p, e)
    if not is_equal_approx(m_pinch, want):
        CombatRegressionHarness._fail(
            failures, "pinch_bonus: expected %.6f got %.6f (inward=%.4f)" % [want, m_pinch, inward]
        )
    e["rank"] = 0
    e["file"] = 0
    mgr.recompute_zoc_and_distance()
    var m_opposed: float = CombatTargetScoring.pinch_score_mult(mgr, p, e)
    if not is_equal_approx(m_opposed, 1.0):
        CombatRegressionHarness._fail(
            failures, "pinch_bonus: file-opposed front should suppress pinch got %.4f" % m_opposed
        )
    e["file"] = 1
    e["rank"] = 1
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    var m_hold_doc: float = CombatTargetScoring.pinch_score_mult(mgr, p, e)
    if not is_equal_approx(m_hold_doc, 1.0):
        CombatRegressionHarness._fail(
            failures, "pinch_bonus: hold_lane doctrine should not apply pinch inward got %.4f" % m_hold_doc
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    if not is_equal_approx(CombatTargetScoring.pinch_score_mult(mgr, p, e), 1.0):
        CombatRegressionHarness._fail(failures, "pinch_bonus: default doctrine should be neutral")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.commitment_match_mult`** after **`on_combat_commitment`** (
## **`DOCTRINE_COMMIT_MATCH_WEIGHT_MULT`** ).


## Tier 1.6: **`CombatTargetScoring.commitment_match_mult`** after **`on_combat_commitment`** (
## **`DOCTRINE_COMMIT_MATCH_WEIGHT_MULT`** ).
static func _run_targeting_commitment_match_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var pid: int = CombatantEntityAccess.id_int(p)
    var eid: int = CombatantEntityAccess.id_int(e)
    p["doctrine_target_commit_id"] = -1
    var m_neutral: float = CombatTargetScoring.commitment_match_mult(p, eid)
    if not is_equal_approx(m_neutral, 1.0):
        CombatRegressionHarness._fail(failures, "commit_match: no commit should be 1.0 got %.4f" % m_neutral)
    mgr.combat_clock = 0.0
    CombatTargetScoring.on_combat_commitment(mgr, pid, eid)
    var m_match: float = CombatTargetScoring.commitment_match_mult(p, eid)
    if not is_equal_approx(m_match, CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
        CombatRegressionHarness._fail(
            failures,
            "commit_match: expected %.4f got %.4f" % [CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT, m_match]
        )
    if not is_equal_approx(CombatTargetScoring.commitment_match_mult(p, eid + 9999), 1.0):
        CombatRegressionHarness._fail(failures, "commit_match: wrong target id should be neutral")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.soft_geometry_score`** = **`1/(1 + effective_pair_eff_dist - -
## DOCTRINE_SOFT_DISTANCE_SCALE)`**; larger eff -> lower score (monotone).


## Tier 1.6: **`CombatTargetScoring.soft_geometry_score`** = **`1/(1 + effective_pair_eff_dist - -
## DOCTRINE_SOFT_DISTANCE_SCALE)`**; larger eff -> lower score (monotone).
static func _run_targeting_soft_geometry_eff_dist_formula(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    for c in mgr.combatants:
        c["gauge"] = 100.0
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    if not CombatantEntityAccess.is_player_side(p):
        CombatRegressionHarness._fail(failures, "soft_geom: expected combatants[0] player")
        CombatRegressionHarness._free_manager(mgr)
        return
    if not CombatantEntityAccess.is_enemy_side(e0) or not CombatantEntityAccess.is_enemy_side(e1):
        CombatRegressionHarness._fail(failures, "soft_geom: expected combatants[1 - 2] enemy")
        CombatRegressionHarness._free_manager(mgr)
        return
    p["file"] = 1
    p["rank"] = 0
    e0["file"] = 0
    e0["rank"] = 0
    e1["file"] = 2
    e1["rank"] = 0
    mgr.recompute_zoc_and_distance()
    var eff0: float = CombatPairGeometry.effective_pair_eff_dist(mgr, p, e0)
    var eff1: float = CombatPairGeometry.effective_pair_eff_dist(mgr, p, e1)
    var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
    var s0: float = CombatTargetScoring.soft_geometry_score(mgr, p, e0)
    var s1: float = CombatTargetScoring.soft_geometry_score(mgr, p, e1)
    var want0: float = 1.0 / (1.0 + eff0 * k)
    var want1: float = 1.0 / (1.0 + eff1 * k)
    if not is_equal_approx(s0, want0):
        CombatRegressionHarness._fail(
            failures, "soft_geom: pair0 formula want %.6f got %.6f eff=%.4f" % [want0, s0, eff0]
        )
    if not is_equal_approx(s1, want1):
        CombatRegressionHarness._fail(
            failures, "soft_geom: pair1 formula want %.6f got %.6f eff=%.4f" % [want1, s1, eff1]
        )
    if absf(eff0 - eff1) > 0.02:
        if eff0 < eff1 and not (s0 > s1 + 1e-5):
            CombatRegressionHarness._fail(
                failures,
                "soft_geom: lower eff should score higher eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
            )
        if eff0 > eff1 and not (s0 < s1 - 1e-5):
            CombatRegressionHarness._fail(
                failures,
                "soft_geom: higher eff should score lower eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
            )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears stale **`doctrine_target_commit_id`** after
## **`doctrine_commit_until`** vs **`combat_clock`**.


## Tier 1.6: **`prune_expired_commitments`** clears stale **`doctrine_target_commit_id`** after
## **`doctrine_commit_until`** vs **`combat_clock`**.
static func _run_targeting_prune_expired_doctrine_commitment(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var pid: int = CombatantEntityAccess.id_int(p)
    var eid: int = CombatantEntityAccess.id_int(e)
    mgr.combat_clock = 0.0
    CombatTargetScoring.on_combat_commitment(mgr, pid, eid)
    if not is_equal_approx(
        CombatTargetScoring.commitment_match_mult(p, eid), CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT
    ):
        CombatRegressionHarness._fail(failures, "prune_commit: expected match mult after on_combat_commitment")
    mgr.combat_clock = float(p.get("doctrine_commit_until", 0.0)) + 0.25
    CombatTargetScoring.prune_expired_commitments(mgr)
    if int(p.get("doctrine_target_commit_id", -2)) != -1:
        CombatRegressionHarness._fail(failures, "prune_commit: expected doctrine_target_commit_id cleared after expiry")
    if not is_equal_approx(CombatTargetScoring.commitment_match_mult(p, eid), 1.0):
        CombatRegressionHarness._fail(failures, "prune_commit: commitment_match_mult should be neutral after prune")
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears doctrine commit when the **committed target** is no longer alive
## (before clock expiry).


## Tier 1.6: **`prune_expired_commitments`** clears doctrine commit when the **committed target** is no longer alive
## (before clock expiry).
static func _run_targeting_prune_commitment_when_target_dies(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var pid: int = CombatantEntityAccess.id_int(p)
    var eid: int = CombatantEntityAccess.id_int(e)
    mgr.combat_clock = 0.0
    CombatTargetScoring.on_combat_commitment(mgr, pid, eid)
    if int(p.get("doctrine_target_commit_id", -2)) != eid:
        CombatRegressionHarness._fail(failures, "prune_dead_tgt: expected live commit before kill")
    e["alive"] = false
    CombatTargetScoring.prune_expired_commitments(mgr)
    if int(p.get("doctrine_target_commit_id", -2)) != -1:
        CombatRegressionHarness._fail(failures, "prune_dead_tgt: expected commit cleared when target dies")
    if not is_equal_approx(CombatTargetScoring.commitment_match_mult(p, eid), 1.0):
        CombatRegressionHarness._fail(
            failures, "prune_dead_tgt: commitment_match_mult should be neutral after dead-target prune"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`clear_all_targeting_state_for_dead_defender`** (death hook) clears **all** allies' doctrine commits and
## **close_block** rows keyed to the dead defender.


## Tier 1.6: **`clear_all_targeting_state_for_dead_defender`** (death hook) clears **all** allies' doctrine commits and
## **close_block** rows keyed to the dead defender.
static func _run_targeting_clear_all_state_for_dead_defender(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var e0: Dictionary = mgr.combatants[2]
    var pid0: int = CombatantEntityAccess.id_int(p0)
    var pid1: int = CombatantEntityAccess.id_int(p1)
    var eid: int = CombatantEntityAccess.id_int(e0)
    mgr.combat_clock = 0.0
    CombatTargetScoring.on_combat_commitment(mgr, pid0, eid)
    CombatTargetScoring.on_combat_commitment(mgr, pid1, eid)
    if int(p0.get("doctrine_target_commit_id", -2)) != eid or int(p1.get("doctrine_target_commit_id", -2)) != eid:
        CombatRegressionHarness._fail(failures, "clear_dead_def: expected both allies committed to dead target id")
    var blk0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
    blk0[eid] = 999.0
    p0["close_block_until_by_target_id"] = blk0
    var blk1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
    blk1[eid] = 888.0
    p1["close_block_until_by_target_id"] = blk1
    CombatTargetScoring.clear_all_targeting_state_for_dead_defender(mgr, eid)
    if int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1:
        CombatRegressionHarness._fail(
            failures, "clear_dead_def: expected doctrine_target_commit_id cleared for both allies"
        )
    var b0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
    var b1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
    if b0.has(eid) or b1.has(eid):
        CombatRegressionHarness._fail(
            failures, "clear_dead_def: expected close_block_until_by_target_id entries for dead id erased"
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 breadth: `opponent_formation_targeting_mult`  -  solid enemy LINE hedges listed weights; ragged LINE
## presses; OPEN uses fixed nudge.


## Tier 1.6 breadth: `opponent_formation_targeting_mult`  -  solid enemy LINE hedges listed weights; ragged LINE
## presses; OPEN uses fixed nudge.
static func _run_ai_targeting_opponent_formation_mult(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var opp: Dictionary = mgr.combatants[1]
    var efid: String = CombatantEntityAccess.formation_id_str(opp)
    var efd: Dictionary = FormationSlots.formation_record_for_manager(mgr, efid)
    efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    efd["line_cohesion"] = 1.0
    var m_solid: float = CombatTargetScoring.opponent_formation_targeting_mult(mgr, opp)
    efd["line_cohesion"] = 0.0
    var m_ragged: float = CombatTargetScoring.opponent_formation_targeting_mult(mgr, opp)
    if m_solid >= m_ragged - 0.001:
        CombatRegressionHarness._fail(
            failures,
            "ai_targeting_opp_form: LINE solid should hedge vs ragged (solid=%.4f ragged=%.4f)" % [m_solid, m_ragged]
        )
    efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
    var m_open: float = CombatTargetScoring.opponent_formation_targeting_mult(mgr, opp)
    if not is_equal_approx(m_open, CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_opp_form: OPEN expected %.4f got %.4f"
                % [CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT, m_open]
            )
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`formation_dict_cache`** on **`opponent_formation_targeting_mult`**,
## **`posture_cohesion_targeting_mult`** matches live **`ZoneOfControl.formation_for_combatant_cached`**.


## Tier 1.6: **`formation_dict_cache`** on **`opponent_formation_targeting_mult`**,
## **`posture_cohesion_targeting_mult`** matches live **`ZoneOfControl.formation_for_combatant_cached`**.
static func _run_targeting_formation_dict_cache_matches_live(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var opp: Dictionary = mgr.combatants[1]
    var pfid: String = CombatantEntityAccess.formation_id_str(p)
    var pfd: Dictionary = FormationSlots.formation_record_for_manager(mgr, pfid)
    pfd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    pfd["line_cohesion"] = 0.42
    var ofid: String = CombatantEntityAccess.formation_id_str(opp)
    var ofd: Dictionary = FormationSlots.formation_record_for_manager(mgr, ofid)
    ofd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
    ofd["line_cohesion"] = 0.61
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var zg_po: Dictionary = ZoneOfControl.zone_geometry_for_pair(mgr, p, opp)
    var fd_p: Dictionary = ZoneOfControl.zone_geometry_formation_a_from_pair_pack(zg_po)
    var fd_o: Dictionary = ZoneOfControl.zone_geometry_formation_b_from_pair_pack(zg_po)
    var m_pc_l: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p)
    var m_pc_c: float = CombatTargetScoring.posture_cohesion_targeting_mult(mgr, p, fd_p)
    if not is_equal_approx(m_pc_l, m_pc_c):
        CombatRegressionHarness._fail(
            failures, "tgt_fd_cache: posture_cohesion live %.6f vs cache %.6f" % [m_pc_l, m_pc_c]
        )
    var m_of_l: float = CombatTargetScoring.opponent_formation_targeting_mult(mgr, opp)
    var m_of_c: float = CombatTargetScoring.opponent_formation_targeting_mult(mgr, opp, fd_o)
    if not is_equal_approx(m_of_l, m_of_c):
        CombatRegressionHarness._fail(
            failures, "tgt_fd_cache: opponent_formation live %.6f vs cache %.6f" % [m_of_l, m_of_c]
        )
    CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / 1.7: `engagement_mode_targeting_mult` tracks resolved duel / skirmish / formation.


## Tier 1.6 / 1.7: `engagement_mode_targeting_mult` tracks resolved duel / skirmish / formation.
static func _run_ai_targeting_engagement_mode_mult(failures: PackedStringArray) -> void:
    var d: Node = CombatManager.new()
    d.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    d.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    if CombatEngagementMode.engagement_mode(d) != CombatConstants.ENGAGEMENT_MODE_DUEL:
        CombatRegressionHarness._fail(
            failures, "ai_targeting_eng_mode: expected duel for 1v1 got %s" % CombatEngagementMode.engagement_mode(d)
        )
    var m_duel: float = CombatTargetScoring.engagement_mode_targeting_mult(d)
    if not is_equal_approx(m_duel, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_eng_mode: duel mult want %.4f got %.4f"
                % [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT, m_duel]
            )
        )
    CombatRegressionHarness._free_manager(d)
    var s: Node = CombatManager.new()
    for _i in 3:
        s.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 3:
        s.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    s.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.snapshot(s).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_eng_mode: 3v3 expected raw skirmish got %s"
                % str(CombatEngagementMode.snapshot(s).get("raw_mode", ""))
            )
        )
    var m_sk: float = CombatTargetScoring.engagement_mode_targeting_mult(s)
    if not is_equal_approx(m_sk, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_eng_mode: skirmish mult want %.4f got %.4f"
                % [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT, m_sk]
            )
        )
    CombatRegressionHarness._free_manager(s)
    var f: Node = CombatManager.new()
    for _i in 4:
        f.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    for _j in 4:
        f.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    if CombatEngagementMode.engagement_mode(f) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
        CombatRegressionHarness._fail(
            failures,
            "ai_targeting_eng_mode: expected formation for 4v4 line got %s" % CombatEngagementMode.engagement_mode(f)
        )
    var m_form: float = CombatTargetScoring.engagement_mode_targeting_mult(f)
    if not is_equal_approx(m_form, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_targeting_eng_mode: formation mult want %.4f got %.4f"
                % [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT, m_form]
            )
        )
    CombatRegressionHarness._free_manager(f)

## Tier 1.6: **`hostile_pair_targeting_weight_mult`**  -  passing **`engagement_mode_targeting_mult(manager)`** as
## **`cached_engagement_mode_targeting_mult`** matches the **null** overload (same snapshot).
