class_name Tier1DepthPolearmEngagementTests
extends CombatRegressionHarnessCore
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")

## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner  -  may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS
## **`#wf-footing-doc-map`**.


static func _assert_tactical_snapshot_matches(failures: PackedStringArray, mgr: Node, ctx: String) -> void:
    if mgr == null:
        return
    if not mgr.has_meta("_tactical_mode_snapshot"):
        _fail(
            failures, "%s: missing _tactical_mode_snapshot (run _recompute_zoc_and_distance?)" % ctx
        )
        return
    var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
    var resolved: String = CombatEngagementMode.engagement_mode(mgr)
    if str(ts.get("mode", "")) != resolved:
        _fail(
            failures, "%s: tactical mode=%s vs engagement_mode=%s" % [ctx, ts.get("mode"), resolved]
        )


static func _run_depth_polearm(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    # Rank-0 sword, rank-1 spear (same file); one enemy front.
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "depth_polearm: expected open lane (rank-1 spear + rank-0 ally)")
    if CombatMeleeListing.can_melee_threaten(mgr, depth, enemy) != true:
        _fail(
            failures, "depth_polearm: can_melee_threaten should be true vs file-opposed rank-0"
        )
    var dist: String = CombatantEntityAccess.distance_to_opponent_band(
        depth, CombatantEntityAccess.id_int(enemy, -2), ""
    )
    if dist == CombatConstants.DISTANCE_LONG:
        _fail(
            failures, "depth_polearm: distance_to should not be LONG when lane open (got %s)" % dist
        )
    depth.gauge = 100.0
    var acts: Array = mgr.get_available_actions(CombatantEntityAccess.id_int(depth))
    var w_depth: Variant = CombatantEntityAccess.get_weapon(depth)
    var atk_ids: Dictionary = {}
    if w_depth != null and w_depth is Weapon:
        atk_ids = (w_depth as Weapon).attack_types
    if not CombatListedActions.actions_include_any_move_in_vs_target(
        acts, CombatantEntityAccess.id_int(enemy), atk_ids
    ):
        _fail(
            failures, "depth_polearm: expected weapon strike vs enemy in available actions (had %s)" % str(acts)
        )
    # Non-polearm depth: no extra reach to line.
    var mgr2: Node = CombatManager.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start(p_preset, e_preset)
    var depth_sw: Dictionary = mgr2.combatants[1]
    var en2: Dictionary = mgr2.combatants[2]
    if CombatMeleeListing.can_melee_threaten(mgr2, depth_sw, en2):
        _fail(
            failures, "depth_polearm: rank-1 sword must not melee-threaten file-opposed rank-0"
        )
    HarnessFixtures._free_manager(mgr2)
    # Tight density: over-shoulder filter drops legs when lane open (pin strict  -  duel/open posture alone opens lows
    # per Tier 1.9).
    mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
    mgr.formations["player"]["density"] = "tight"
    var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
    var filt_tight: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
        _fail(
            failures, "depth_polearm: tight lane should filter leg targets (got %s)" % str(filt_tight)
        )
    var df: int = CombatantEntityAccess.file_int(depth, 0)
    mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
    var filt_wedge_gap: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt_wedge_gap.has("left_leg") and not filt_wedge_gap.has("right_leg"):
        _fail(
            failures,
            "depth_polearm: lane stress at file should open low targets in tight lane (got %s)" % str(filt_wedge_gap)
        )
    mgr.formations["player"]["density"] = "loose"
    var filt_loose: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt_loose.has("left_leg"):
        _fail(failures, "depth_polearm: loose lane should keep leg targets available")
    # Optional `spear_lane_profile` on formation (Tier 1.9): open on tight; restricted on loose without lane stress.
    mgr.formations["player"]["density"] = "tight"
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
    var filt_prof_open: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if not filt_prof_open.has("left_leg"):
        _fail(
            failures,
            "depth_polearm: spear_lane_profile open + tight should allow leg targets (got %s)" % str(filt_prof_open)
        )
    mgr.formations["player"]["density"] = "loose"
    mgr.formations["player"]["lane_stress_by_file"] = {}
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = (
        CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
    )
    var filt_prof_rest: Array = CombatDepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
    if filt_prof_rest.has("left_leg") or filt_prof_rest.has("right_leg"):
        _fail(
            failures,
            (
                "depth_polearm: spear_lane_profile restricted + loose should filter legs without lane stress (got %s)"
                % str(filt_prof_rest)
            )
        )
    mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: reciprocal bands  -  rank-0 defender is not stuck at LONG vs an enemy depth spear when spear->defender is
## MID/CLOSE.


## Tier 1.9: reciprocal bands  -  rank-0 defender is not stuck at LONG vs an enemy depth spear when spear->defender is
## MID/CLOSE.
static func _run_depth_polearm_reciprocal_distance_bands(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SPEAR"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
    var player: Dictionary = mgr.combatants[0]
    var en_depth: Dictionary = mgr.combatants[2]
    var pid: int = CombatantEntityAccess.id_int(player)
    var did: int = CombatantEntityAccess.id_int(en_depth)
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, en_depth):
        _fail(failures, "depth_polearm_recip: expected enemy depth spear lane open")
    if not CombatMeleeListing.can_melee_threaten(mgr, en_depth, player):
        _fail(failures, "depth_polearm_recip: enemy spear should melee-threaten player rank-0")
    var d_depth_to_p: String = CombatantEntityAccess.distance_to_opponent_band(en_depth, pid, "")
    var d_p_to_depth: String = CombatantEntityAccess.distance_to_opponent_band(player, did, "")
    if d_depth_to_p == CombatConstants.DISTANCE_LONG:
        _fail(
            failures, "depth_polearm_recip: spear->player band unexpected LONG (got %s)" % d_depth_to_p
        )
    if d_p_to_depth == CombatConstants.DISTANCE_LONG:
        _fail(
            failures,
            (
                "depth_polearm_recip: player->spear should not be LONG when spear threatens (player=%s spear=%s)"
                % [d_p_to_depth, d_depth_to_p]
            )
        )
    var mgr2: Node = CombatManager.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
    var pl2: Dictionary = mgr2.combatants[0]
    var en_deep_sword: Dictionary = mgr2.combatants[2]
    var eid2: int = CombatantEntityAccess.id_int(en_deep_sword)
    if CombatDepthPolearm.depth_polearm_lane_open(mgr2, en_deep_sword):
        _fail(failures, "depth_polearm_recip: rank-1 sword must not have open polearm lane")
    var band_r0_to_r1: String = CombatantEntityAccess.distance_to_opponent_band(pl2, eid2, "")
    if band_r0_to_r1 != CombatConstants.DISTANCE_LONG:
        _fail(
            failures, "depth_polearm_recip: rank-1 non-polearm should stay LONG from rank-0 (got %s)" % band_r0_to_r1
        )
    HarnessFixtures._free_manager(mgr2)
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: depth polearm may threaten opposed file + immediate neighbor files (lateral max); not beyond.


## Tier 1.9: depth polearm may threaten opposed file + immediate neighbor files (lateral max); not beyond.
static func _run_depth_polearm_only_file_opposed_line(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
    var e_preset := {"files": 3, "ranks": 1, "density": "normal"}
    mgr.start(p_preset, e_preset)
    var depth: Dictionary = mgr.combatants[1]
    var en_f0: Dictionary = mgr.combatants[2]
    var en_f1: Dictionary = mgr.combatants[3]
    var en_f2: Dictionary = mgr.combatants[4]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "depth_polearm_file: expected open lane")
    if not CombatMeleeListing.can_melee_threaten(mgr, depth, en_f0):
        _fail(failures, "depth_polearm_file: should threaten file-opposed rank-0")
    if not CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en_f1):
        _fail(failures, "depth_polearm_file: neighbor file should be in lateral thrust window")
    if CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en_f2):
        _fail(
            failures,
            "depth_polearm_file: file+2 beyond DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES must not count as lane target"
        )
    if CombatMeleeListing.can_melee_threaten(mgr, depth, en_f2):
        _fail(failures, "depth_polearm_file: must not melee-threaten rank-0 two files over")
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: **`depth_polearm_threatens_line_target`** pure guards (no manager): empty ally/opp, rank!=0, same side,
## dead, **`abs(Deltafile)`** vs **`DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES`**.


## Tier 1.9: **`depth_polearm_threatens_line_target`** pure guards (no manager): empty ally/opp, rank!=0, same side,
## dead, **`abs(Deltafile)`** vs **`DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES`**.
static func _run_depth_polearm_threatens_line_target_pure_guards(failures: PackedStringArray) -> void:
    var front: Dictionary = {"rank": 0, "file": 1, "side": "player", "alive": true}
    var opp_line: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": true}
    if CombatDepthPolearm.depth_polearm_threatens_line_target({}, opp_line):
        _fail(failures, "threatens_pure: empty front ally -> false")
    if CombatDepthPolearm.depth_polearm_threatens_line_target(front, {}):
        _fail(failures, "threatens_pure: empty opp -> false")
    var ally_same: Dictionary = {"rank": 0, "file": 2, "side": "player", "alive": true}
    if CombatDepthPolearm.depth_polearm_threatens_line_target(front, ally_same):
        _fail(failures, "threatens_pure: same-side rank-0 -> false")
    var opp_deep: Dictionary = {"rank": 1, "file": 1, "side": "enemy", "alive": true}
    if CombatDepthPolearm.depth_polearm_threatens_line_target(front, opp_deep):
        _fail(failures, "threatens_pure: enemy rank!=0 -> false")
    var opp_dead: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": false}
    if CombatDepthPolearm.depth_polearm_threatens_line_target(front, opp_dead):
        _fail(failures, "threatens_pure: dead enemy -> false")
    if not CombatDepthPolearm.depth_polearm_threatens_line_target(front, opp_line):
        _fail(failures, "threatens_pure: file-opposed same file -> true")
    var opp_near: Dictionary = {"rank": 0, "file": 2, "side": "enemy", "alive": true}
    if not CombatDepthPolearm.depth_polearm_threatens_line_target(front, opp_near):
        _fail(failures, "threatens_pure: neighbor within lateral max -> true")
    var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
    var opp_beyond: Dictionary = {"rank": 0, "file": 1 + max_lat + 1, "side": "enemy", "alive": true}
    if CombatDepthPolearm.depth_polearm_threatens_line_target(front, opp_beyond):
        _fail(failures, "threatens_pure: beyond lateral max -> false")


## Tier 1.9: **`depth_polearm_valid_line_threat`** is **false** when **`depth_polearm_lane_open`** is **false**, even if
## **`depth_polearm_threatens_line_target`** (same-file rank-0 vs enemy rank-0) is **true**.


## Tier 1.9: **`depth_polearm_valid_line_threat`** is **false** when **`depth_polearm_lane_open`** is **false**, even if
## **`depth_polearm_threatens_line_target`** (same-file rank-0 vs enemy rank-0) is **true**.
static func _run_depth_polearm_valid_line_threat_false_when_lane_closed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var depth: Dictionary = mgr.combatants[1]
    var en: Dictionary = mgr.combatants[2]
    if CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "valid_lt_lane: rank-1 sword should not open depth polearm lane")
        HarnessFixtures._free_manager(mgr)
        return
    var front: Dictionary = CombatDepthPolearm.same_file_living_rank0_ally(mgr, depth)
    if front.is_empty():
        _fail(failures, "valid_lt_lane: missing same-file rank-0 ally")
        HarnessFixtures._free_manager(mgr)
        return
    if not CombatDepthPolearm.depth_polearm_threatens_line_target(front, en):
        _fail(
            failures, "valid_lt_lane: expected geometric line threat rank-0 vs rank-0 same column"
        )
        HarnessFixtures._free_manager(mgr)
        return
    if CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en):
        _fail(failures, "valid_lt_lane: closed lane must force valid_line_threat false")
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_valid_line_threat(manager, depth, opp)`**
## equals **`depth_polearm_threatens_line_target(same_file_living_rank0_ally, opp)`** (
## **`depth_polearm_valid_line_threat`** implementation path).


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_valid_line_threat(manager, depth, opp)`**
## equals **`depth_polearm_threatens_line_target(same_file_living_rank0_ally, opp)`** (
## **`depth_polearm_valid_line_threat`** implementation path).
static func _run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "valid_lt_agree: expected open depth polearm lane")
        HarnessFixtures._free_manager(mgr)
        return
    var front: Dictionary = CombatDepthPolearm.same_file_living_rank0_ally(mgr, depth)
    if front.is_empty():
        _fail(failures, "valid_lt_agree: missing same-file rank-0 ally")
        HarnessFixtures._free_manager(mgr)
        return
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        var vlt: bool = CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
        var thr: bool = CombatDepthPolearm.depth_polearm_threatens_line_target(front, c)
        if vlt != thr:
            _fail(
                failures,
                (
                    "valid_lt_agree: id=%d rank=%d valid=%s threatens=%s"
                    % [CombatantEntityAccess.id_int(c), CombatantEntityAccess.rank_int(c), str(vlt), str(thr)]
                )
            )
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: **`_opp_matches_melee_rank_target(..., 0)`** (depth polearm branch in **`build`**) matches
## **`depth_polearm_valid_line_threat`** vs every living enemy on a **3-wide** opposing front (listing gate aligned with
## **`valid_line_threat`**).


## Tier 1.9: **`_opp_matches_melee_rank_target(..., 0)`** (depth polearm branch in **`build`**) matches
## **`depth_polearm_valid_line_threat`** vs every living enemy on a **3-wide** opposing front (listing gate aligned with
## **`valid_line_threat`**).
static func _run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "opp_match_vlt: expected open depth polearm lane")
        HarnessFixtures._free_manager(mgr)
        return
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        var om: bool = CombatMeleeRankTargeting.opp_matches_melee_rank_target(mgr, depth, c, 0)
        var vlt: bool = CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
        if om != vlt:
            _fail(
                failures,
                (
                    "opp_match_vlt: id=%d rank=%d om=%s vlt=%s"
                    % [CombatantEntityAccess.id_int(c), CombatantEntityAccess.rank_int(c), str(om), str(vlt)]
                )
            )
    HarnessFixtures._free_manager(mgr)


## Tier 1.9: **`_melee_pair_rank_allowed`** home-depth vs enemy rank-0 uses **`depth_polearm_valid_line_threat`**  -
## open **3-wide** + closed-lane **SWORD** depth fixtures match **`valid_line_threat`** per living enemy.


## Tier 1.9: **`_melee_pair_rank_allowed`** home-depth vs enemy rank-0 uses **`depth_polearm_valid_line_threat`**  -
## open **3-wide** + closed-lane **SWORD** depth fixtures match **`valid_line_threat`** per living enemy.
static func _run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(
    failures: PackedStringArray
) -> void:
    var mgr_open: Node = CombatManager.new()
    mgr_open.register(_new_entity("SWORD"), "player")
    mgr_open.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr_open.register(_new_entity("SWORD"), "enemy")
    mgr_open.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr_open.recompute_zoc_and_distance()
    var depth_open: Dictionary = mgr_open.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr_open, depth_open):
        _fail(failures, "mpra_vlt: open fixture expected depth polearm lane")
        HarnessFixtures._free_manager(mgr_open)
        return
    for c in mgr_open.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        var pr: bool = CombatMeleeRankTargeting.melee_pair_rank_allowed(mgr_open, depth_open, c)
        var vlt: bool = CombatDepthPolearm.depth_polearm_valid_line_threat(mgr_open, depth_open, c)
        if pr != vlt:
            _fail(
                failures, "mpra_vlt open: id=%d pr=%s vlt=%s" % [CombatantEntityAccess.id_int(c), str(pr), str(vlt)]
            )
    HarnessFixtures._free_manager(mgr_open)
    var mgr_closed: Node = CombatManager.new()
    mgr_closed.register(_new_entity("SWORD"), "player")
    mgr_closed.register(_new_entity("SWORD"), "player")
    mgr_closed.register(_new_entity("SWORD"), "enemy")
    mgr_closed.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr_closed.recompute_zoc_and_distance()
    var depth_closed: Dictionary = mgr_closed.combatants[1]
    if CombatDepthPolearm.depth_polearm_lane_open(mgr_closed, depth_closed):
        _fail(failures, "mpra_vlt: closed fixture expected lane closed")
        HarnessFixtures._free_manager(mgr_closed)
        return
    for c in mgr_closed.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        var pr2: bool = CombatMeleeRankTargeting.melee_pair_rank_allowed(mgr_closed, depth_closed, c)
        var vlt2: bool = CombatDepthPolearm.depth_polearm_valid_line_threat(mgr_closed, depth_closed, c)
        if pr2 != vlt2:
            _fail(
                failures, "mpra_vlt closed: id=%d pr=%s vlt=%s" % [CombatantEntityAccess.id_int(c), str(pr2), str(vlt2)]
            )
    HarnessFixtures._free_manager(mgr_closed)


## Tier 1.9: **`can_melee_threaten`** never **true** vs a **home-line** enemy rank 0 unless
## **`depth_polearm_valid_line_threat`** (open **3-wide** + closed-lane control).


## Tier 1.9: **`can_melee_threaten`** never **true** vs a **home-line** enemy rank 0 unless
## **`depth_polearm_valid_line_threat`** (open **3-wide** + closed-lane control).
static func _run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(
    failures: PackedStringArray
) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var depth: Dictionary = mgr.combatants[1]
    if not CombatDepthPolearm.depth_polearm_lane_open(mgr, depth):
        _fail(failures, "cm_vlt: expected open depth polearm lane")
        HarnessFixtures._free_manager(mgr)
        return
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        if (
            CombatMeleeListing.can_melee_threaten(mgr, depth, c)
            and not CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
        ):
            _fail(
                failures, "cm_vlt: can_melee_threaten without valid_line id=%d" % CombatantEntityAccess.id_int(c)
            )
    HarnessFixtures._free_manager(mgr)
    var mgr2: Node = CombatManager.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr2.recompute_zoc_and_distance()
    var depth_sw: Dictionary = mgr2.combatants[1]
    var en: Dictionary = mgr2.combatants[2]
    if CombatDepthPolearm.depth_polearm_valid_line_threat(mgr2, depth_sw, en):
        _fail(failures, "cm_vlt: closed lane expected valid_line false")
        HarnessFixtures._free_manager(mgr2)
        return
    if CombatMeleeListing.can_melee_threaten(mgr2, depth_sw, en):
        _fail(
            failures, "cm_vlt: closed lane rank-1 sword must not can_melee_threaten rank-0 enemy"
        )
    HarnessFixtures._free_manager(mgr2)


## Tier 1.9 (P10) soak: random multi-file lines  -  `depth_polearm_valid_line_threat` tracks lateral window vs same-file
## rank-0 partner.


## Tier 1.9 (P10) soak: random multi-file lines  -  `depth_polearm_valid_line_threat` tracks lateral window vs same-file
## rank-0 partner.
static func _run_depth_polearm_layout_fuzz(failures: PackedStringArray) -> void:
    var rng := RandomNumberGenerator.new()
    var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
    for scenario_seed in 24:
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
            _fail(failures, "depth_polearm_fuzz seed=%d: bad depth idx" % scenario_seed)
            HarnessFixtures._free_manager(mgr)
            continue
        var depth: Dictionary = mgr.combatants[depth_idx]
        var lane_open: bool = CombatDepthPolearm.depth_polearm_lane_open(mgr, depth)
        if not lane_open:
            _fail(
                failures, "depth_polearm_fuzz seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs]
            )
            HarnessFixtures._free_manager(mgr)
            continue
        var front: Dictionary = CombatDepthPolearm.same_file_living_rank0_ally(mgr, depth)
        if front.is_empty():
            _fail(failures, "depth_polearm_fuzz seed=%d: missing front ally" % scenario_seed)
            HarnessFixtures._free_manager(mgr)
            continue
        var ff: int = CombatantEntityAccess.file_int(front, -9)
        for c in mgr.combatants:
            if not CombatantEntityAccess.is_alive_on_side(c, "enemy"):
                continue
            if CombatantEntityAccess.rank_int(c, -1) != 0:
                continue
            var lat: int = absi(CombatantEntityAccess.file_int(c) - ff)
            var geo_ok: bool = lat <= max_lat
            var vlt: bool = CombatDepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
            if vlt != geo_ok:
                _fail(
                    failures,
                    (
                        (
                            "depth_polearm_fuzz seed=%d: valid_line_threat=%s vs geo_ok=%s "
                            + "pf=%d ef=%d depth_file=%d opp_file=%d lat=%d"
                        )
                        % [
                            scenario_seed,
                            vlt,
                            geo_ok,
                            pf,
                            ef,
                            CombatantEntityAccess.file_int(depth, -1),
                            CombatantEntityAccess.file_int(c, -1),
                            lat
                        ]
                    )
                )
        HarnessFixtures._free_manager(mgr)


## Front-rank sword vs sword: CLOSE or MID must list real strikes (MID uses geometric reach, not only REACH_MID_MIN).


## Front-rank sword vs sword: CLOSE or MID must list real strikes (MID uses geometric reach, not only REACH_MID_MIN).
static func _run_front_rank_pair_melee_listed(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var p: Dictionary = mgr.combatants[0]
    var e: Dictionary = mgr.combatants[1]
    var dist: String = CombatantEntityAccess.distance_to_opponent_band(p, CombatantEntityAccess.id_int(e, -2), "")
    if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
        HarnessFixtures._free_manager(mgr)
        return
    p.gauge = 100.0
    var acts: Array = mgr.get_available_actions(CombatantEntityAccess.id_int(p))
    var w_p: Variant = CombatantEntityAccess.get_weapon(p)
    var atk_ids: Dictionary = {}
    if w_p != null and w_p is Weapon:
        atk_ids = (w_p as Weapon).attack_types
    if not CombatListedActions.actions_include_any_move_in_vs_target(acts, CombatantEntityAccess.id_int(e), atk_ids):
        _fail(
            failures, "front_rank_pair: expected weapon strike vs enemy at band %s (acts=%s)" % [dist, str(acts)]
        )
    HarnessFixtures._free_manager(mgr)


## IV-3: `snapshot_is_true_duel` classifier  -  doc-sync, helper parity, attrition 7v2 -> true 1v1 duel.


## IV-3: `snapshot_is_true_duel` classifier  -  doc-sync, helper parity, attrition 7v2 -> true 1v1 duel.
static func _run_iv3_true_duel_classifier_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatEngagementMode.iv3_doc_sync_line()
    for token in [
        "snapshot_is_true_duel",
        "mop_up_excludes_duel",
        "skirmish_mopup_7v2",
        "attrition_to_duel",
    ]:
        if token not in sync_line:
            _fail(failures, "iv3_duel: sync line missing %s in %s" % [token, sync_line])
    if not CombatEngagementMode.snapshot_is_true_duel({"player_active": 1, "enemy_active": 1}):
        _fail(failures, "iv3_duel: 1v1 snap must be true duel")
    for bad_snap in [
        {"player_active": 2, "enemy_active": 1},
        {"player_active": 2, "enemy_active": 2},
        {"player_active": 7, "enemy_active": 2},
    ]:
        if CombatEngagementMode.snapshot_is_true_duel(bad_snap):
            _fail(failures, "iv3_duel: snap %s must not be true duel" % str(bad_snap))
    var duel_mgr: Node = CombatManager.new()
    duel_mgr.register(_new_entity("SWORD"), "player")
    duel_mgr.register(_new_entity("SWORD"), "enemy")
    duel_mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var duel_snap: Dictionary = CombatEngagementMode.snapshot(duel_mgr)
    if not CombatEngagementMode.snapshot_is_true_duel(duel_snap):
        _fail(
            failures, "iv3_duel: live 1v1 snap must pass snapshot_is_true_duel got %s" % str(duel_snap)
        )
    if CombatEngagementMode.engagement_mode(duel_mgr) != CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(
            failures,
            "iv3_duel: live 1v1 resolved mode want duel got %s" % CombatEngagementMode.engagement_mode(duel_mgr)
        )
    if CombatDoctrine.envelop_mop_up_active(duel_mgr, "player"):
        _fail(failures, "iv3_duel: true 1v1 must not activate envelop mop-up")
    HarnessFixtures._free_manager(duel_mgr)
    # 2v2 front line -> attrition to rank-0 1v1 resolves duel (rear-only survivor would stay skirmish).
    var pair: Node = CombatManager.new()
    for _i in 2:
        pair.register(_new_entity("SWORD"), "player")
    for _j in 2:
        pair.register(_new_entity("SWORD"), "enemy")
    pair.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    if CombatEngagementMode.snapshot_is_true_duel(CombatEngagementMode.snapshot(pair)):
        _fail(failures, "iv3_duel: 2v2 must not be true duel before attrition")
    var keep_player_id: int = -1
    var keep_enemy_id: int = -1
    var kill_ids: Array = []
    for c in pair.combatants:
        if CombatantEntityAccess.is_living_on_side(c, "player"):
            if CombatantEntityAccess.rank_int(c) == 0 and keep_player_id < 0:
                keep_player_id = CombatantEntityAccess.id_int(c)
            else:
                kill_ids.append(CombatantEntityAccess.id_int(c))
        elif CombatantEntityAccess.is_living_on_side(c, "enemy"):
            if CombatantEntityAccess.rank_int(c) == 0 and keep_enemy_id < 0:
                keep_enemy_id = CombatantEntityAccess.id_int(c)
            else:
                kill_ids.append(CombatantEntityAccess.id_int(c))
    for kid in kill_ids:
        HarnessFixtures._soak_kill_combatant(pair, int(kid))
    var after_snap: Dictionary = CombatEngagementMode.snapshot(pair)
    if not CombatEngagementMode.snapshot_is_true_duel(after_snap):
        _fail(failures, "iv3_duel: 2v2 attrition want 1v1 snap got %s" % str(after_snap))
    if str(after_snap.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(
            failures, "iv3_duel: 2v2 attrition to rank-0 1v1 want raw duel got %s" % str(after_snap.get("raw_mode", ""))
        )
    if CombatEngagementMode.engagement_mode(pair) != CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(
            failures,
            "iv3_duel: 2v2 attrition to 1v1 want resolved duel got %s" % CombatEngagementMode.engagement_mode(pair)
        )
    if CombatDoctrine.envelop_mop_up_active(pair, "player"):
        _fail(failures, "iv3_duel: attrition 1v1 must not activate envelop mop-up")
    HarnessFixtures._free_manager(pair)


static func _run_engagement_scenarios(failures: PackedStringArray) -> void:
    # Tier 1.8 (P9): small / medium / large representative headcounts  -  raw classifier + tactical snapshot stay
    # aligned.
    # Small: 1v1 -> duel classifier
    var d: Node = CombatManager.new()
    d.register(_new_entity("SWORD"), "player")
    d.register(_new_entity("SWORD"), "enemy")
    d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var s1: Dictionary = CombatEngagementMode.snapshot(d)
    if str(s1.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(
            failures, "engagement: 1v1 expected raw duel, got %s" % str(s1.get("raw_mode", ""))
        )
    if CombatEngagementMode.can_enter_formation_from_snapshot(s1):
        _fail(failures, "engagement: 1v1 snap must not claim formation-eligible")
    Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(failures, d, "engagement small 1v1")
    HarnessFixtures._free_manager(d)
    # Asymmetric mop-up: 7v2 must stay skirmish (rotate when outnumbering), not global duel.
    var mop: Node = CombatManager.new()
    for _i in 7:
        mop.register(_new_entity("SWORD"), "player")
    for _j in 2:
        mop.register(_new_entity("SWORD"), "enemy")
    mop.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var s_mop: Dictionary = CombatEngagementMode.snapshot(mop)
    if str(s_mop.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _fail(
            failures,
            "engagement: 7v2 expected raw skirmish, got %s snap=%s" % [str(s_mop.get("raw_mode", "")), str(s_mop)]
        )
    if CombatEngagementMode.engagement_mode(mop) == CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(failures, "engagement: 7v2 resolved must not be duel")
    if not CombatEngagementMode.allow_rotate_file_for_formation(mop, "player"):
        _fail(
            failures, "engagement: 7v2 skirmish outnumber should allow player rotate_file (5 vs 3 files)"
        )
    HarnessFixtures._free_manager(mop)
    # Escort-shaped equal files: skirmish mop-up without rotate (III-4 3b needs file outnumber).
    var esc: Node = CombatManager.new()
    for _i in 7:
        esc.register(_new_entity("SWORD"), "player")
    for _j in 2:
        esc.register(_new_entity("SWORD"), "enemy")
    esc.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.snapshot(esc).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _fail(
            failures,
            (
                "engagement: escort 7v2 equal files want skirmish got %s"
                % str(CombatEngagementMode.snapshot(esc).get("raw_mode", ""))
            )
        )
    if CombatEngagementMode.allow_rotate_file_for_formation(esc, "player"):
        _fail(failures, "engagement: escort 7v2 equal 5v5 files must not allow rotate_file")
    HarnessFixtures._free_manager(esc)
    # 7v1 mop-up is skirmish, not duel (only true 1v1 is duel).
    var one: Node = CombatManager.new()
    for _i in 7:
        one.register(_new_entity("SWORD"), "player")
    one.register(_new_entity("SWORD"), "enemy")
    one.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.snapshot(one).get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(failures, "engagement: 7v1 must not classify as duel")
    HarnessFixtures._free_manager(one)
    # Formation hysteresis: 7v5 line -> 7v2 releases resolved formation (active floor + thin fill).
    var attr: Node = CombatManager.new()
    for _i in 7:
        attr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        attr.register(_new_entity("SWORD"), "enemy")
    attr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    if CombatEngagementMode.engagement_mode(attr) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
        _fail(
            failures, "engagement: 7v5 want formation-line mode got %s" % CombatEngagementMode.engagement_mode(attr)
        )
    var enemy_ids: Array = []
    for c in attr.combatants:
        if CombatantEntityAccess.side_str(c) == "enemy":
            enemy_ids.append(CombatantEntityAccess.id_int(c))
    for k in range(mini(3, enemy_ids.size())):
        HarnessFixtures._soak_kill_combatant(attr, int(enemy_ids[k]))
    var m_after: String = CombatEngagementMode.engagement_mode(attr)
    if m_after == CombatConstants.ENGAGEMENT_MODE_FORMATION:
        _fail(
            failures, "engagement: 7v2 after attrition should not stay formation (hysteresis)"
        )
    if m_after == CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(failures, "engagement: 7v2 after attrition must not be duel")
    HarnessFixtures._free_manager(attr)
    # Tutorial-scale 2v2: was misclassified as duel under old "either side <=2 actives" rule.
    var tut: Node = CombatManager.new()
    tut.register(_new_entity("SWORD"), "player")
    tut.register(_new_entity("SWORD"), "player")
    tut.register(_new_entity("SWORD"), "enemy")
    tut.register(_new_entity("SWORD"), "enemy")
    tut.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
    if str(CombatEngagementMode.snapshot(tut).get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_DUEL:
        _fail(failures, "engagement: 2v2 expected skirmish not duel")
    HarnessFixtures._free_manager(tut)
    # Medium: 3v3 wide front (active 3 < formation floor) -> skirmish, not duel (multi-file front)
    var m: Node = CombatManager.new()
    for _i in 3:
        m.register(_new_entity("SWORD"), "player")
    for _j in 3:
        m.register(_new_entity("SWORD"), "enemy")
    m.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var s3: Dictionary = CombatEngagementMode.snapshot(m)
    if str(s3.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        _fail(
            failures,
            "engagement: 3v3 three-wide expected raw skirmish, got %s snap=%s" % [str(s3.get("raw_mode", "")), str(s3)]
        )
    if CombatEngagementMode.can_enter_formation_from_snapshot(s3):
        _fail(
            failures, "engagement: 3v3 snap must not claim formation-eligible (below active floor)"
        )
    Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(failures, m, "engagement medium 3v3")
    HarnessFixtures._free_manager(m)
    # Large: 4v4 two-wide line -> formation-classifier band (Option 2 minimums)
    var f: Node = CombatManager.new()
    for _i in 4:
        f.register(_new_entity("SWORD"), "player")
    for _j in 4:
        f.register(_new_entity("SWORD"), "enemy")
    f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    var s4: Dictionary = CombatEngagementMode.snapshot(f)
    if str(s4.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
        _fail(
            failures,
            (
                "engagement: 4v4 two-file line expected raw formation, got %s snap=%s"
                % [str(s4.get("raw_mode", "")), str(s4)]
            )
        )
    if not CombatEngagementMode.can_enter_formation_from_snapshot(s4):
        _fail(
            failures, "engagement: 4v4 formation snap must satisfy can_enter_formation_from_snapshot"
        )
    var mode_f: String = CombatEngagementMode.engagement_mode(f)
    Tier1DepthPolearmEngagementTests._assert_tactical_snapshot_matches(failures, f, "engagement large 4v4")
    HarnessFixtures._free_manager(f)


## III-4 Track A PR2: opposition file offset seeded at **`CombatManager.start`** from formation widths.


## III-4 Track A PR2: opposition file offset seeded at **`CombatManager.start`** from formation widths.
static func _run_opposition_offset_seeded_at_start(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if not mgr.has_meta(EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
        _fail(failures, "opposition_offset: expected meta after start")
    var off_p: int = EngagementOpposition.opposition_file_offset(mgr, "player")
    var off_e: int = EngagementOpposition.opposition_file_offset(mgr, "enemy")
    if off_p != 1:
        _fail(failures, "opposition_offset: 5 vs 3 expected player offset 1 got %d" % off_p)
    if off_e != -1:
        _fail(failures, "opposition_offset: expected enemy offset -1 got %d" % off_e)
    var p_center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 2)
    var e_center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
    var p_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "player", 0, 0)
    if p_center.is_empty() or e_center.is_empty() or p_wing.is_empty():
        _fail(failures, "opposition_offset: missing rank-0 fixtures for mapped opposition")
    elif not EngagementOpposition.is_mapped_file_opposed(mgr, p_center, e_center):
        _fail(failures, "opposition_offset: expected mapped opposition center pair")
    elif EngagementOpposition.is_mapped_file_opposed(mgr, p_wing, e_center):
        _fail(failures, "opposition_offset: wing file 0 should not map to enemy file 1")
    var e_wing: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
    if e_wing.is_empty():
        _fail(failures, "opposition_offset: missing enemy file 0 fixture")
    elif not EngagementOpposition.is_mapped_file_opposed(mgr, p_wing, e_wing):
        _fail(failures, "opposition_offset: wing file 0 should nearest-map to enemy file 0")
    elif not CombatTargetScoring.is_file_opposed_rank0_pair(mgr, p_center, e_center):
        _fail(
            failures, "opposition_offset: TargetScoring delegate expected center file-opposed"
        )
    elif CombatTargetScoring.is_file_opposed_rank0_pair(mgr, p_wing, e_center):
        _fail(failures, "opposition_offset: wing should not be file-opposed via delegate")
    HarnessFixtures._free_manager(mgr)
    # 7v3 skirmish (Border / ii_envelop): outer files nearest-map to outer enemies, not only center offset.
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    if EngagementOpposition.opposition_file_offset(wide, "player") != 2:
        _fail(
            failures,
            (
                "opposition_nearest_wing: 7v3 expected player offset 2 got %d"
                % EngagementOpposition.opposition_file_offset(wide, "player")
            )
        )
    var p_left: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 0)
    var p_right: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_left: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 0)
    var e_right: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    if p_left.is_empty() or p_right.is_empty() or e_left.is_empty() or e_right.is_empty():
        _fail(failures, "opposition_nearest_wing: missing 7v3 rank-0 fixtures")
    elif not EngagementOpposition.is_mapped_file_opposed(wide, p_left, e_left):
        _fail(failures, "opposition_nearest_wing: player file 0 should oppose enemy file 0")
    elif not EngagementOpposition.is_mapped_file_opposed(wide, p_right, e_right):
        _fail(failures, "opposition_nearest_wing: player file 6 should oppose enemy file 2")
    elif EngagementOpposition.is_mapped_file_opposed(wide, p_left, e_right):
        _fail(
            failures, "opposition_nearest_wing: player file 0 should not map to far enemy file 2"
        )
    var p_inner: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 1)
    var e_mid: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 1)
    if p_inner.is_empty() or e_mid.is_empty():
        _fail(failures, "opposition_nearest_wing: missing inner-wing fixtures")
    elif not EngagementOpposition.is_mapped_file_opposed(wide, p_inner, e_left):
        _fail(
            failures, "opposition_nearest_wing: player file 1 should nearest-map to enemy file 0"
        )
    elif EngagementOpposition.wing_lacks_mapped_opposition(wide, p_left):
        _fail(failures, "opposition_nearest_wing: outer wing should not lack mapped opposition")
    var m_wing: float = CombatTargetScoring.file_opposed_mult(wide, p_left, e_left)
    if not is_equal_approx(m_wing, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
        _fail(
            failures,
            (
                "opposition_nearest_wing: outer wing want file_opposed_mult %.4f got %.4f"
                % [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_wing]
            )
        )
    for c in wide.combatants:
        c["gauge"] = 100.0
    wide.recompute_zoc_and_distance()
    var ordered: Array = CombatTargetScoring.ordered_melee_opponents(wide, p_left, wide.combatants, 0)
    if ordered.is_empty():
        _fail(failures, "opposition_nearest_wing: expected melee opponents for outer wing")
    elif CombatantEntityAccess.file_int(ordered[0]) != CombatantEntityAccess.file_int(e_left):
        _fail(
            failures,
            (
                "opposition_nearest_wing: ordered_melee should prefer enemy file 0 got file %d"
                % CombatantEntityAccess.file_int(ordered[0])
            )
        )
    HarnessFixtures._free_manager(wide)
    Tier1DepthPolearmEngagementTests._run_opposition_aware_pair_geometry_wing_reach(failures)
    Tier1SwapRankEngagementTests._run_engagement_reach_audit_close_bind_and_wing_gap(failures)
    Tier1SwapRankEngagementTests._run_listing_strikes_when_in_swing_at_long_band(failures)
    Tier1SwapRankEngagementTests._run_inner_wing_gap1_mid_strikes_after_recompute(failures)
    Tier1SwapRankEngagementTests._run_close_success_wing_lists_strikes_without_recompute(failures)
    Tier1SwapRankEngagementTests._run_mapped_wing_out_of_reach_hold_hint(failures)
    Tier1SwapRankEngagementTests._run_attempt_close_listed_for_pair_omit_in_swing_long(failures)
    Tier1SwapRankEngagementTests._run_resolve_close_blocked_in_swing_long(failures)
    Tier1SwapRankEngagementTests._run_hold_line_close_pick_mapped_wing_out_of_reach(failures)
    Tier1SwapRankEngagementTests._run_bind_close_rotate_suppressed_and_close_weight(failures)
    Tier1SwapRankEngagementTests._run_border_skirmish_encounter_enemy_pinch(failures)
    Tier1SwapRankEngagementTests._run_opposition_equal_width_same_index(failures)


## III-4 **3a:** mapped rank-0 opposition uses logical file gap for reach (7v3 wing vs assigned foe).


## III-4 **3a:** mapped rank-0 opposition uses logical file gap for reach (7v3 wing vs assigned foe).
static func _run_opposition_aware_pair_geometry_wing_reach(failures: PackedStringArray) -> void:
    var wide: Node = CombatManager.new()
    for _i in 7:
        wide.register(_new_entity("SWORD"), "player")
    for _j in 3:
        wide.register(_new_entity("SWORD"), "enemy")
    wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    var p_right: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 6)
    var e_right: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
    var p_center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "player", 0, 3)
    var e_center: Dictionary = HarnessFixtures._harness_find_living_at_rank_file(wide, "enemy", 0, 1)
    if p_right.is_empty() or e_right.is_empty() or p_center.is_empty() or e_center.is_empty():
        _fail(failures, "opposition_pair_geom: missing 7v3 rank-0 fixtures")
        HarnessFixtures._free_manager(wide)
        return
    if not EngagementOpposition.is_mapped_file_opposed(wide, p_right, e_right):
        _fail(failures, "opposition_pair_geom: player file 6 should map to enemy file 2")
        HarnessFixtures._free_manager(wide)
        return
    var wing_gap: int = EngagementOpposition.mapped_opposition_file_distance(wide, p_right, e_right)
    if wing_gap != 2:
        _fail(failures, "opposition_pair_geom: outer wing mapped gap want 2 got %d" % wing_gap)
        HarnessFixtures._free_manager(wide)
        return
    var eff_wing: float = CombatPairGeometry.effective_pair_eff_dist(wide, p_right, e_right)
    var raw_df: float = absf(float(CombatantEntityAccess.file_int(p_right) - CombatantEntityAccess.file_int(e_right)))
    var eff_raw_floor: float = raw_df * CombatConstants.SPACING_NORMAL * CombatConstants.REACH_SAFETY_FACTOR
    if eff_wing >= eff_raw_floor * 0.99:
        _fail(
            failures,
            (
                "opposition_pair_geom: wing want opposition-aware eff_dist < raw grid eff got mapped=%.3f raw~=%.3f"
                % [eff_wing, eff_raw_floor]
            )
        )
        HarnessFixtures._free_manager(wide)
        return
    var center_gap: int = EngagementOpposition.mapped_opposition_file_distance(wide, p_center, e_center)
    if center_gap != 0:
        _fail(failures, "opposition_pair_geom: center mapped gap want 0 got %d" % center_gap)
        HarnessFixtures._free_manager(wide)
        return
    if not CombatMeleeListing.can_melee_threaten(wide, p_center, e_center):
        _fail(failures, "opposition_pair_geom: want can_melee_threaten on mapped center pair")
    wide.recompute_zoc_and_distance()
    var center_band: String = CombatantEntityAccess.distance_to_opponent_band(
        p_center, CombatantEntityAccess.id_int(e_center), ""
    )
    if center_band == CombatConstants.DISTANCE_LONG:
        _fail(
            failures, "opposition_pair_geom: center mapped pair want MID/CLOSE band got %s" % center_band
        )
    HarnessFixtures._free_manager(wide)

## Reach audit: CLOSE band uses bind spacing (df=0); mapped wing gap 2 stays out of sword reach until close.
