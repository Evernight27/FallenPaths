class_name CombatRegressionHarnessTier1Tail
extends RefCounted

## Tier 1 depth / engagement / targeting / surround / doctrine tests (compile split).
## Footing: not WF/PA owner — may call strike/listing paths that read **`form_str`**. Spec: LIVE_PATHS **`#wf-footing-doc-map`**.

const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationVacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")

static func _assert_tactical_snapshot_matches(
	failures: PackedStringArray,
	mgr: Node,
	ctx: String
) -> void:
	if mgr == null:
		return
	if not mgr.has_meta("_tactical_mode_snapshot"):
		CombatRegressionHarness._fail(failures, "%s: missing _tactical_mode_snapshot (run _recompute_zoc_and_distance?)" % ctx)
		return
	var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
	var resolved: String = _EngagementMode.engagement_mode(mgr)
	if str(ts.get("mode", "")) != resolved:
		CombatRegressionHarness._fail(failures, "%s: tactical mode=%s vs engagement_mode=%s" % [ctx, ts.get("mode"), resolved])


static func _run_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	# Rank-0 sword, rank-1 spear (same file); one enemy front.
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_polearm: expected open lane (rank-1 spear + rank-0 ally)")
	if _MeleeListing.can_melee_threaten(mgr, depth, enemy) != true:
		CombatRegressionHarness._fail(failures, "depth_polearm: can_melee_threaten should be true vs file-opposed rank-0")
	var dist: String = _EntityAccess.distance_to_opponent_band(depth, _EntityAccess.id_int(enemy, -2), "")
	if dist == CombatConstants.DISTANCE_LONG:
		CombatRegressionHarness._fail(failures, "depth_polearm: distance_to should not be LONG when lane open (got %s)" % dist)
	depth.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
	var w_depth: Variant = _EntityAccess.get_weapon(depth)
	var atk_ids: Dictionary = {}
	if w_depth != null and w_depth is Weapon:
		atk_ids = (w_depth as Weapon).attack_types
	if not _ListedActions.actions_include_any_move_in_vs_target(
		acts, _EntityAccess.id_int(enemy), atk_ids
	):
		CombatRegressionHarness._fail(failures, "depth_polearm: expected weapon strike vs enemy in available actions (had %s)" % str(acts))
	# Non-polearm depth: no extra reach to line.
	var mgr2: Node = _MgrScript.new()
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en2: Dictionary = mgr2.combatants[2]
	if _MeleeListing.can_melee_threaten(mgr2, depth_sw, en2):
		CombatRegressionHarness._fail(failures, "depth_polearm: rank-1 sword must not melee-threaten file-opposed rank-0")
	CombatRegressionHarness._free_manager(mgr2)
	# Tight density: over-shoulder filter drops legs when lane open (pin strict — duel/open posture alone opens lows per Tier 1.9).
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt_tight: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_polearm: tight lane should filter leg targets (got %s)" % str(filt_tight))
	var df: int = _EntityAccess.file_int(depth, 0)
	mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
	var filt_wedge_gap: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_wedge_gap.has("left_leg") and not filt_wedge_gap.has("right_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_polearm: lane stress at file should open low targets in tight lane (got %s)" % str(filt_wedge_gap)
		)
	mgr.formations["player"]["density"] = "loose"
	var filt_loose: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_loose.has("left_leg"):
		CombatRegressionHarness._fail(failures, "depth_polearm: loose lane should keep leg targets available")
	# Optional `spear_lane_profile` on formation (Tier 1.9): open on tight; restricted on loose without lane stress.
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var filt_prof_open: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_prof_open.has("left_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_polearm: spear_lane_profile open + tight should allow leg targets (got %s)" % str(filt_prof_open)
		)
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["lane_stress_by_file"] = {}
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	var filt_prof_rest: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_prof_rest.has("left_leg") or filt_prof_rest.has("right_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_polearm: spear_lane_profile restricted + loose should filter legs without lane stress (got %s)"
			% str(filt_prof_rest)
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: reciprocal bands — rank-0 defender is not stuck at LONG vs an enemy depth spear when spear→defender is MID/CLOSE.
static func _run_depth_polearm_reciprocal_distance_bands(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var player: Dictionary = mgr.combatants[0]
	var en_depth: Dictionary = mgr.combatants[2]
	var pid: int = _EntityAccess.id_int(player)
	var did: int = _EntityAccess.id_int(en_depth)
	if not _DepthPolearm.depth_polearm_lane_open(mgr, en_depth):
		CombatRegressionHarness._fail(failures, "depth_polearm_recip: expected enemy depth spear lane open")
	if not _MeleeListing.can_melee_threaten(mgr, en_depth, player):
		CombatRegressionHarness._fail(failures, "depth_polearm_recip: enemy spear should melee-threaten player rank-0")
	var d_depth_to_p: String = _EntityAccess.distance_to_opponent_band(en_depth, pid, "")
	var d_p_to_depth: String = _EntityAccess.distance_to_opponent_band(player, did, "")
	if d_depth_to_p == CombatConstants.DISTANCE_LONG:
		CombatRegressionHarness._fail(failures, "depth_polearm_recip: spear→player band unexpected LONG (got %s)" % d_depth_to_p)
	if d_p_to_depth == CombatConstants.DISTANCE_LONG:
		CombatRegressionHarness._fail(
			failures,
			"depth_polearm_recip: player→spear should not be LONG when spear threatens (player=%s spear=%s)"
			% [d_p_to_depth, d_depth_to_p]
		)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var pl2: Dictionary = mgr2.combatants[0]
	var en_deep_sword: Dictionary = mgr2.combatants[2]
	var eid2: int = _EntityAccess.id_int(en_deep_sword)
	if _DepthPolearm.depth_polearm_lane_open(mgr2, en_deep_sword):
		CombatRegressionHarness._fail(failures, "depth_polearm_recip: rank-1 sword must not have open polearm lane")
	var band_r0_to_r1: String = _EntityAccess.distance_to_opponent_band(pl2, eid2, "")
	if band_r0_to_r1 != CombatConstants.DISTANCE_LONG:
		CombatRegressionHarness._fail(
			failures,
			"depth_polearm_recip: rank-1 non-polearm should stay LONG from rank-0 (got %s)" % band_r0_to_r1
		)
	CombatRegressionHarness._free_manager(mgr2)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: depth polearm may threaten opposed file + immediate neighbor files (lateral max); not beyond.
static func _run_depth_polearm_only_file_opposed_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 3, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var en_f0: Dictionary = mgr.combatants[2]
	var en_f1: Dictionary = mgr.combatants[3]
	var en_f2: Dictionary = mgr.combatants[4]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_polearm_file: expected open lane")
	if not _MeleeListing.can_melee_threaten(mgr, depth, en_f0):
		CombatRegressionHarness._fail(failures, "depth_polearm_file: should threaten file-opposed rank-0")
	if not _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en_f1):
		CombatRegressionHarness._fail(failures, "depth_polearm_file: neighbor file should be in lateral thrust window")
	if _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en_f2):
		CombatRegressionHarness._fail(failures, "depth_polearm_file: file+2 beyond DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES must not count as lane target")
	if _MeleeListing.can_melee_threaten(mgr, depth, en_f2):
		CombatRegressionHarness._fail(failures, "depth_polearm_file: must not melee-threaten rank-0 two files over")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_threatens_line_target`** pure guards (no manager): empty ally/opp, rank≠0, same side, dead, **`abs(Δfile)`** vs **`DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES`**.
static func _run_depth_polearm_threatens_line_target_pure_guards(failures: PackedStringArray) -> void:
	var front: Dictionary = {"rank": 0, "file": 1, "side": "player", "alive": true}
	var opp_line: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": true}
	if _DepthPolearm.depth_polearm_threatens_line_target({}, opp_line):
		CombatRegressionHarness._fail(failures, "threatens_pure: empty front ally → false")
	if _DepthPolearm.depth_polearm_threatens_line_target(front, {}):
		CombatRegressionHarness._fail(failures, "threatens_pure: empty opp → false")
	var ally_same: Dictionary = {"rank": 0, "file": 2, "side": "player", "alive": true}
	if _DepthPolearm.depth_polearm_threatens_line_target(front, ally_same):
		CombatRegressionHarness._fail(failures, "threatens_pure: same-side rank-0 → false")
	var opp_deep: Dictionary = {"rank": 1, "file": 1, "side": "enemy", "alive": true}
	if _DepthPolearm.depth_polearm_threatens_line_target(front, opp_deep):
		CombatRegressionHarness._fail(failures, "threatens_pure: enemy rank≠0 → false")
	var opp_dead: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": false}
	if _DepthPolearm.depth_polearm_threatens_line_target(front, opp_dead):
		CombatRegressionHarness._fail(failures, "threatens_pure: dead enemy → false")
	if not _DepthPolearm.depth_polearm_threatens_line_target(front, opp_line):
		CombatRegressionHarness._fail(failures, "threatens_pure: file-opposed same file → true")
	var opp_near: Dictionary = {"rank": 0, "file": 2, "side": "enemy", "alive": true}
	if not _DepthPolearm.depth_polearm_threatens_line_target(front, opp_near):
		CombatRegressionHarness._fail(failures, "threatens_pure: neighbor within lateral max → true")
	var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
	var opp_beyond: Dictionary = {
		"rank": 0,
		"file": 1 + max_lat + 1,
		"side": "enemy",
		"alive": true
	}
	if _DepthPolearm.depth_polearm_threatens_line_target(front, opp_beyond):
		CombatRegressionHarness._fail(failures, "threatens_pure: beyond lateral max → false")


## Tier 1.9: **`depth_polearm_valid_line_threat`** is **false** when **`depth_polearm_lane_open`** is **false**, even if **`depth_polearm_threatens_line_target`** (same-file rank-0 vs enemy rank-0) is **true**.
static func _run_depth_polearm_valid_line_threat_false_when_lane_closed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	var en: Dictionary = mgr.combatants[2]
	if _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "valid_lt_lane: rank-1 sword should not open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		CombatRegressionHarness._fail(failures, "valid_lt_lane: missing same-file rank-0 ally")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _DepthPolearm.depth_polearm_threatens_line_target(front, en):
		CombatRegressionHarness._fail(failures, "valid_lt_lane: expected geometric line threat rank-0 vs rank-0 same column")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, en):
		CombatRegressionHarness._fail(failures, "valid_lt_lane: closed lane must force valid_line_threat false")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_valid_line_threat(manager, depth, opp)`** equals **`depth_polearm_threatens_line_target(same_file_living_rank0_ally, opp)`** ( **`depth_polearm_valid_line_threat`** implementation path).
static func _run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "valid_lt_agree: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		CombatRegressionHarness._fail(failures, "valid_lt_agree: missing same-file rank-0 ally")
		CombatRegressionHarness._free_manager(mgr)
		return
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		var vlt: bool = _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
		var thr: bool = _DepthPolearm.depth_polearm_threatens_line_target(front, c)
		if vlt != thr:
			CombatRegressionHarness._fail(
				failures,
				"valid_lt_agree: id=%d rank=%d valid=%s threatens=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(vlt), str(thr)]
			)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`_opp_matches_melee_rank_target(..., 0)`** (depth polearm branch in **`build`**) matches **`depth_polearm_valid_line_threat`** vs every living enemy on a **3-wide** opposing front (listing gate aligned with **`valid_line_threat`**).
static func _run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "opp_match_vlt: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		var om: bool = _MeleeRank.opp_matches_melee_rank_target(mgr, depth, c, 0)
		var vlt: bool = _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
		if om != vlt:
			CombatRegressionHarness._fail(
				failures,
				"opp_match_vlt: id=%d rank=%d om=%s vlt=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(om), str(vlt)]
			)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`_melee_pair_rank_allowed`** home-depth vs enemy rank-0 uses **`depth_polearm_valid_line_threat`** — open **3-wide** + closed-lane **SWORD** depth fixtures match **`valid_line_threat`** per living enemy.
static func _run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr_open: Node = _MgrScript.new()
	mgr_open.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_open.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_open.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_open.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_open._recompute_zoc_and_distance()
	var depth_open: Dictionary = mgr_open.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr_open, depth_open):
		CombatRegressionHarness._fail(failures, "mpra_vlt: open fixture expected depth polearm lane")
		CombatRegressionHarness._free_manager(mgr_open)
		return
	for c in mgr_open.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		var pr: bool = _MeleeRank.melee_pair_rank_allowed(mgr_open, depth_open, c)
		var vlt: bool = _DepthPolearm.depth_polearm_valid_line_threat(mgr_open, depth_open, c)
		if pr != vlt:
			CombatRegressionHarness._fail(
				failures,
				"mpra_vlt open: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr), str(vlt)]
			)
	CombatRegressionHarness._free_manager(mgr_open)
	var mgr_closed: Node = _MgrScript.new()
	mgr_closed.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_closed.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_closed.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_closed.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr_closed._recompute_zoc_and_distance()
	var depth_closed: Dictionary = mgr_closed.combatants[1]
	if _DepthPolearm.depth_polearm_lane_open(mgr_closed, depth_closed):
		CombatRegressionHarness._fail(failures, "mpra_vlt: closed fixture expected lane closed")
		CombatRegressionHarness._free_manager(mgr_closed)
		return
	for c in mgr_closed.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		var pr2: bool = _MeleeRank.melee_pair_rank_allowed(mgr_closed, depth_closed, c)
		var vlt2: bool = _DepthPolearm.depth_polearm_valid_line_threat(mgr_closed, depth_closed, c)
		if pr2 != vlt2:
			CombatRegressionHarness._fail(
				failures,
				"mpra_vlt closed: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr2), str(vlt2)]
			)
	CombatRegressionHarness._free_manager(mgr_closed)


## Tier 1.9: **`can_melee_threaten`** never **true** vs a **home-line** enemy rank 0 unless **`depth_polearm_valid_line_threat`** (open **3-wide** + closed-lane control).
static func _run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "cm_vlt: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if (
			_MeleeListing.can_melee_threaten(mgr, depth, c)
			and not _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
		):
			CombatRegressionHarness._fail(failures, "cm_vlt: can_melee_threaten without valid_line id=%d" % _EntityAccess.id_int(c))
	CombatRegressionHarness._free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr2._recompute_zoc_and_distance()
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en: Dictionary = mgr2.combatants[2]
	if _DepthPolearm.depth_polearm_valid_line_threat(mgr2, depth_sw, en):
		CombatRegressionHarness._fail(failures, "cm_vlt: closed lane expected valid_line false")
		CombatRegressionHarness._free_manager(mgr2)
		return
	if _MeleeListing.can_melee_threaten(mgr2, depth_sw, en):
		CombatRegressionHarness._fail(failures, "cm_vlt: closed lane rank-1 sword must not can_melee_threaten rank-0 enemy")
	CombatRegressionHarness._free_manager(mgr2)


## Tier 1.9 (P10) soak: random multi-file lines — `depth_polearm_valid_line_threat` tracks lateral window vs same-file rank-0 partner.
static func _run_depth_polearm_layout_fuzz(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pf: int = rng.randi_range(1, 4)
		var ef: int = rng.randi_range(1, 4)
		var mgr: Node = _MgrScript.new()
		for _i in pf:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		for _j in pf:
			mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
		for _k in ef:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
		mgr.start(
			{"files": pf, "ranks": 2, "density": "normal"},
			{"files": ef, "ranks": 1, "density": "normal"}
		)
		var fs: int = rng.randi_range(0, pf - 1)
		var depth_idx: int = pf + fs
		if depth_idx >= mgr.combatants.size():
			CombatRegressionHarness._fail(failures, "depth_polearm_fuzz seed=%d: bad depth idx" % scenario_seed)
			CombatRegressionHarness._free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		var lane_open: bool = _DepthPolearm.depth_polearm_lane_open(mgr, depth)
		if not lane_open:
			CombatRegressionHarness._fail(failures, "depth_polearm_fuzz seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			CombatRegressionHarness._free_manager(mgr)
			continue
		var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(mgr, depth)
		if front.is_empty():
			CombatRegressionHarness._fail(failures, "depth_polearm_fuzz seed=%d: missing front ally" % scenario_seed)
			CombatRegressionHarness._free_manager(mgr)
			continue
		var ff: int = _EntityAccess.file_int(front, -9)
		for c in mgr.combatants:
			if not _EntityAccess.is_alive_on_side(c, "enemy"):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			var lat: int = absi(_EntityAccess.file_int(c) - ff)
			var geo_ok: bool = lat <= max_lat
			var vlt: bool = _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c)
			if vlt != geo_ok:
				CombatRegressionHarness._fail(
					failures,
					(
						"depth_polearm_fuzz seed=%d: valid_line_threat=%s vs geo_ok=%s "
						+ "pf=%d ef=%d depth_file=%d opp_file=%d lat=%d"
					)
					% [scenario_seed, vlt, geo_ok, pf, ef, _EntityAccess.file_int(depth, -1), _EntityAccess.file_int(c, -1), lat]
				)
		CombatRegressionHarness._free_manager(mgr)


## Front-rank sword vs sword: CLOSE or MID must list real strikes (MID uses geometric reach, not only REACH_MID_MIN).
static func _run_front_rank_pair_melee_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var dist: String = _EntityAccess.distance_to_opponent_band(p, _EntityAccess.id_int(e, -2), "")
	if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
		CombatRegressionHarness._free_manager(mgr)
		return
	p.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(p))
	var w_p: Variant = _EntityAccess.get_weapon(p)
	var atk_ids: Dictionary = {}
	if w_p != null and w_p is Weapon:
		atk_ids = (w_p as Weapon).attack_types
	if not _ListedActions.actions_include_any_move_in_vs_target(
		acts, _EntityAccess.id_int(e), atk_ids
	):
		CombatRegressionHarness._fail(
			failures,
			"front_rank_pair: expected weapon strike vs enemy at band %s (acts=%s)" % [dist, str(acts)]
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_engagement_scenarios(failures: PackedStringArray) -> void:
	# Tier 1.8 (P9): small / medium / large representative headcounts — raw classifier + tactical snapshot stay aligned.
	# Small: 1v1 → duel classifier
	var d: Node = _MgrScript.new()
	d.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	d.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var s1: Dictionary = _EngagementMode.snapshot(d)
	if str(s1.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(failures, "engagement: 1v1 expected raw duel, got %s" % str(s1.get("raw_mode", "")))
	if _EngagementMode.can_enter_formation_from_snapshot(s1):
		CombatRegressionHarness._fail(failures, "engagement: 1v1 snap must not claim formation-eligible")
	_assert_tactical_snapshot_matches(failures, d, "engagement small 1v1")
	CombatRegressionHarness._free_manager(d)
	# Asymmetric mop-up: 7v2 must stay skirmish (rotate when outnumbering), not global duel.
	var mop: Node = _MgrScript.new()
	for _i in 7:
		mop.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 2:
		mop.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mop.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var s_mop: Dictionary = _EngagementMode.snapshot(mop)
	if str(s_mop.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(
			failures,
			"engagement: 7v2 expected raw skirmish, got %s snap=%s" % [str(s_mop.get("raw_mode", "")), str(s_mop)]
		)
	if _EngagementMode.engagement_mode(mop) == CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(failures, "engagement: 7v2 resolved must not be duel")
	if not _EngagementMode.allow_rotate_file_for_formation(mop, "player"):
		CombatRegressionHarness._fail(
			failures,
			"engagement: 7v2 skirmish outnumber should allow player rotate_file (5 vs 3 files)"
		)
	CombatRegressionHarness._free_manager(mop)
	# Escort-shaped equal files: skirmish mop-up without rotate (III-4 3b needs file outnumber).
	var esc: Node = _MgrScript.new()
	for _i in 7:
		esc.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 2:
		esc.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	esc.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(esc).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(
			failures,
			"engagement: escort 7v2 equal files want skirmish got %s"
			% str(_EngagementMode.snapshot(esc).get("raw_mode", ""))
		)
	if _EngagementMode.allow_rotate_file_for_formation(esc, "player"):
		CombatRegressionHarness._fail(
			failures, "engagement: escort 7v2 equal 5v5 files must not allow rotate_file"
		)
	CombatRegressionHarness._free_manager(esc)
	# 7v1 mop-up is skirmish, not duel (only true 1v1 is duel).
	var one: Node = _MgrScript.new()
	for _i in 7:
		one.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	one.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	one.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(one).get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(failures, "engagement: 7v1 must not classify as duel")
	CombatRegressionHarness._free_manager(one)
	# Formation hysteresis: 7v5 line → 7v2 releases resolved formation (active floor + thin fill).
	var attr: Node = _MgrScript.new()
	for _i in 7:
		attr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		attr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	attr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	if _EngagementMode.engagement_mode(attr) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(
			failures,
			"engagement: 7v5 want formation-line mode got %s" % _EngagementMode.engagement_mode(attr)
		)
	var enemy_ids: Array = []
	for c in attr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(3, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(attr, int(enemy_ids[k]))
	var m_after: String = _EngagementMode.engagement_mode(attr)
	if m_after == CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(
			failures, "engagement: 7v2 after attrition should not stay formation (hysteresis)"
		)
	if m_after == CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(failures, "engagement: 7v2 after attrition must not be duel")
	CombatRegressionHarness._free_manager(attr)
	# Tutorial-scale 2v2: was misclassified as duel under old "either side ≤2 actives" rule.
	var tut: Node = _MgrScript.new()
	tut.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	tut.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	tut.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	tut.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	tut.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(tut).get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(failures, "engagement: 2v2 expected skirmish not duel")
	CombatRegressionHarness._free_manager(tut)
	# Medium: 3v3 wide front (active 3 < formation floor) → skirmish, not duel (multi-file front)
	var m: Node = _MgrScript.new()
	for _i in 3:
		m.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		m.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var s3: Dictionary = _EngagementMode.snapshot(m)
	if str(s3.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(
			failures,
			"engagement: 3v3 three-wide expected raw skirmish, got %s snap=%s"
			% [str(s3.get("raw_mode", "")), str(s3)]
		)
	if _EngagementMode.can_enter_formation_from_snapshot(s3):
		CombatRegressionHarness._fail(failures, "engagement: 3v3 snap must not claim formation-eligible (below active floor)")
	_assert_tactical_snapshot_matches(failures, m, "engagement medium 3v3")
	CombatRegressionHarness._free_manager(m)
	# Large: 4v4 two-wide line → formation-classifier band (Option 2 minimums)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		f.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var s4: Dictionary = _EngagementMode.snapshot(f)
	if str(s4.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(
			failures,
			"engagement: 4v4 two-file line expected raw formation, got %s snap=%s"
			% [str(s4.get("raw_mode", "")), str(s4)]
		)
	if not _EngagementMode.can_enter_formation_from_snapshot(s4):
		CombatRegressionHarness._fail(failures, "engagement: 4v4 formation snap must satisfy can_enter_formation_from_snapshot")
	var mode_f: String = _EngagementMode.engagement_mode(f)
	_assert_tactical_snapshot_matches(failures, f, "engagement large 4v4")
	CombatRegressionHarness._free_manager(f)


## III-4 Track A PR2: opposition file offset seeded at **`CombatManager.start`** from formation widths.
static func _run_opposition_offset_seeded_at_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if not mgr.has_meta(_EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		CombatRegressionHarness._fail(failures, "opposition_offset: expected meta after start")
	var off_p: int = _EngagementOpposition.opposition_file_offset(mgr, "player")
	var off_e: int = _EngagementOpposition.opposition_file_offset(mgr, "enemy")
	if off_p != 1:
		CombatRegressionHarness._fail(failures, "opposition_offset: 5 vs 3 expected player offset 1 got %d" % off_p)
	if off_e != -1:
		CombatRegressionHarness._fail(failures, "opposition_offset: expected enemy offset -1 got %d" % off_e)
	var p_center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "player", 0, 2
	)
	var e_center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "enemy", 0, 1
	)
	var p_wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr, "player", 0, 0
	)
	if p_center.is_empty() or e_center.is_empty() or p_wing.is_empty():
		CombatRegressionHarness._fail(failures, "opposition_offset: missing rank-0 fixtures for mapped opposition")
	elif not _EngagementOpposition.is_mapped_file_opposed(mgr, p_center, e_center):
		CombatRegressionHarness._fail(failures, "opposition_offset: expected mapped opposition center pair")
	elif _EngagementOpposition.is_mapped_file_opposed(mgr, p_wing, e_center):
		CombatRegressionHarness._fail(failures, "opposition_offset: wing file 0 should not map to enemy file 1")
	var e_wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
	if e_wing.is_empty():
		CombatRegressionHarness._fail(failures, "opposition_offset: missing enemy file 0 fixture")
	elif not _EngagementOpposition.is_mapped_file_opposed(mgr, p_wing, e_wing):
		CombatRegressionHarness._fail(
			failures, "opposition_offset: wing file 0 should nearest-map to enemy file 0"
		)
	elif not _TargetScoring.is_file_opposed_rank0_pair(mgr, p_center, e_center):
		CombatRegressionHarness._fail(failures, "opposition_offset: TargetScoring delegate expected center file-opposed")
	elif _TargetScoring.is_file_opposed_rank0_pair(mgr, p_wing, e_center):
		CombatRegressionHarness._fail(failures, "opposition_offset: wing should not be file-opposed via delegate")
	CombatRegressionHarness._free_manager(mgr)
	# 7v3 skirmish (Border / ii_envelop): outer files nearest-map to outer enemies, not only center offset.
	var wide: Node = _MgrScript.new()
	for _i in 7:
		wide.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		wide.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	wide.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if _EngagementOpposition.opposition_file_offset(wide, "player") != 2:
		CombatRegressionHarness._fail(
			failures, "opposition_nearest_wing: 7v3 expected player offset 2 got %d"
			% _EngagementOpposition.opposition_file_offset(wide, "player")
		)
	var p_left: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "player", 0, 0)
	var p_right: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "player", 0, 6)
	var e_left: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "enemy", 0, 0)
	var e_right: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "enemy", 0, 2)
	if p_left.is_empty() or p_right.is_empty() or e_left.is_empty() or e_right.is_empty():
		CombatRegressionHarness._fail(failures, "opposition_nearest_wing: missing 7v3 rank-0 fixtures")
	elif not _EngagementOpposition.is_mapped_file_opposed(wide, p_left, e_left):
		CombatRegressionHarness._fail(failures, "opposition_nearest_wing: player file 0 should oppose enemy file 0")
	elif not _EngagementOpposition.is_mapped_file_opposed(wide, p_right, e_right):
		CombatRegressionHarness._fail(failures, "opposition_nearest_wing: player file 6 should oppose enemy file 2")
	elif _EngagementOpposition.is_mapped_file_opposed(wide, p_left, e_right):
		CombatRegressionHarness._fail(
			failures, "opposition_nearest_wing: player file 0 should not map to far enemy file 2"
		)
	var p_inner: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "player", 0, 1)
	var e_mid: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(wide, "enemy", 0, 1)
	if p_inner.is_empty() or e_mid.is_empty():
		CombatRegressionHarness._fail(failures, "opposition_nearest_wing: missing inner-wing fixtures")
	elif not _EngagementOpposition.is_mapped_file_opposed(wide, p_inner, e_left):
		CombatRegressionHarness._fail(
			failures, "opposition_nearest_wing: player file 1 should nearest-map to enemy file 0"
		)
	elif _EngagementOpposition.wing_lacks_mapped_opposition(wide, p_left):
		CombatRegressionHarness._fail(
			failures, "opposition_nearest_wing: outer wing should not lack mapped opposition"
		)
	var m_wing: float = _TargetScoring.file_opposed_mult(wide, p_left, e_left)
	if not is_equal_approx(m_wing, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		CombatRegressionHarness._fail(
			failures,
			"opposition_nearest_wing: outer wing want file_opposed_mult %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_wing]
		)
	for c in wide.combatants:
		c["gauge"] = 100.0
	wide._recompute_zoc_and_distance()
	var ordered: Array = _TargetScoring.ordered_melee_opponents(
		wide, p_left, wide.combatants, 0
	)
	if ordered.is_empty():
		CombatRegressionHarness._fail(
			failures, "opposition_nearest_wing: expected melee opponents for outer wing"
		)
	elif _EntityAccess.file_int(ordered[0]) != _EntityAccess.file_int(e_left):
		CombatRegressionHarness._fail(
			failures,
			"opposition_nearest_wing: ordered_melee should prefer enemy file 0 got file %d"
			% _EntityAccess.file_int(ordered[0])
		)
	CombatRegressionHarness._free_manager(wide)
	_run_border_skirmish_encounter_enemy_pinch(failures)
	_run_opposition_equal_width_same_index(failures)


static func _run_border_skirmish_encounter_enemy_pinch(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter = {
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
		CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 7,
	}
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(
			failures,
			"border_skirmish_pinch: enemy doctrine want pinch_center got %s"
			% mgr.get_formation_doctrine("enemy")
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_opposition_equal_width_same_index(failures: PackedStringArray) -> void:
	var eq: Node = _MgrScript.new()
	for _i in 3:
		eq.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		eq.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	eq.start({"files": 3, "ranks": 1}, {"files": 3, "ranks": 1})
	if _EngagementOpposition.opposition_file_offset(eq, "player") != 0:
		CombatRegressionHarness._fail(failures, "opposition_offset: equal width expected offset 0")
	for fi in 3:
		var pp: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(eq, "player", 0, fi)
		var ee: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(eq, "enemy", 0, fi)
		if pp.is_empty() or ee.is_empty():
			CombatRegressionHarness._fail(failures, "opposition_offset: 3v3 missing file %d fixtures" % fi)
		elif not _EngagementOpposition.is_mapped_file_opposed(eq, pp, ee):
			CombatRegressionHarness._fail(
				failures, "opposition_offset: 3v3 file %d should oppose same-index enemy only" % fi
			)
		for fj in 3:
			if fi == fj:
				continue
			var ee_off: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
				eq, "enemy", 0, fj
			)
			if _EngagementOpposition.is_mapped_file_opposed(eq, pp, ee_off):
				CombatRegressionHarness._fail(
					failures,
					"opposition_offset: 3v3 file %d should not map to enemy file %d" % [fi, fj]
				)
	eq.start({"files": 2, "ranks": 2}, {"files": 4, "ranks": 1})
	if _EngagementOpposition.opposition_file_offset(eq, "player") != -1:
		CombatRegressionHarness._fail(
			failures,
			"opposition_offset: second start 2 vs 4 expected player offset -1 got %d"
			% _EngagementOpposition.opposition_file_offset(eq, "player")
		)
	eq.stop()
	if eq.has_meta(_EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		CombatRegressionHarness._fail(failures, "opposition_offset: stop() should clear opposition meta")
	CombatRegressionHarness._free_manager(eq)


## III-6: depth spear reserve skips with faster recheck when lane is open (same-file rank-0 ally).
static func _run_back_rank_depth_lane_skip_recheck(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rear: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c) and _EntityAccess.rank_int(c) == 1:
			rear = c
			break
	if rear.is_empty():
		CombatRegressionHarness._fail(failures, "back_rank_depth_skip: missing rank-1 spear reserve")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _DepthPolearm.depth_polearm_lane_open(mgr, rear):
		CombatRegressionHarness._fail(failures, "back_rank_depth_skip: expected depth lane open")
		CombatRegressionHarness._free_manager(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	mgr.skip_turn(rear_id)
	var delay: float = (
		_EventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
	)
	var want: float = CombatConstants.READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S
	if absf(delay - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"back_rank_depth_skip: want delay %.2f got %.2f" % [want, delay]
		)
	CombatRegressionHarness._free_manager(mgr)


## III-6 maintain: rear relief swap gets line-plug weight when another file has rank-0 hole.
static func _run_swap_rank_line_plug_weight_when_front_hole(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "swap_rank_line_plug: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if _FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(0, 4)):
		CombatRegressionHarness._fail(failures, "swap_rank_line_plug: want empty rank-0 file 4 after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(failures, "swap_rank_line_plug: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "swap_rank_line_plug: want relief swap blocked for weight test")
		CombatRegressionHarness._free_manager(mgr)
		return
	var swap_act: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_SWAP_RANK,
		"target_id": _EntityAccess.id_int(front),
	}
	var w: float = _AIPicker._get_action_weight(
		swap_act, _EntityAccess.id_int(rear), mgr, true, {}, {}
	)
	if w < CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"swap_rank_line_plug: want >= %.2f got %.3f"
			% [CombatConstants.SWAP_RANK_AI_LINE_PLUG_WEIGHT, w]
		)
	CombatRegressionHarness._free_manager(mgr)


## III-6: rank-0 turn resolves → same-file reserves get formation recheck delay.
static func _run_same_file_depth_recheck_after_front_turn(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var front: Dictionary = {}
	var rear: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.rank_int(c) == 0:
			front = c
		elif _EntityAccess.rank_int(c) == 1:
			rear = c
	if front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "depth_recheck_front_turn: missing front/rear pair")
		CombatRegressionHarness._free_manager(mgr)
		return
	var front_id: int = _EntityAccess.id_int(front)
	var rear_id: int = _EntityAccess.id_int(rear)
	mgr.skip_turn(front_id)
	var delay: float = (
		_EventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
	)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	if absf(delay - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"depth_recheck_front_turn: want delay %.2f got %.2f" % [want, delay]
		)
	CombatRegressionHarness._free_manager(mgr)


## III-6: rank-0 wind-up abort → same-file reserves get formation recheck delay.
static func _run_windup_abort_same_file_depth_recheck(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var front: Dictionary = {}
	var rear: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.rank_int(c) == 0:
			front = c
		elif _EntityAccess.rank_int(c) == 1:
			rear = c
	if front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "windup_depth_recheck: missing front/rear pair")
		CombatRegressionHarness._free_manager(mgr)
		return
	var front_id: int = _EntityAccess.id_int(front)
	var rear_id: int = _EntityAccess.id_int(rear)
	var enemy_id: int = _EntityAccess.id_int(mgr.combatants[2])
	_WindUpStarter.start(mgr, front_id, enemy_id, "thrust")
	var ent: CoreEntity = _EntityAccess.scene_node(front) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	_StateHandlers.process_wind_up(mgr, front, 0.05)
	var delay: float = (
		_EventScheduler.get_next_action_ready_at(mgr, rear_id) - mgr.combat_clock
	)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	if absf(delay - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"windup_depth_recheck: want delay %.2f got %.2f" % [want, delay]
		)
	CombatRegressionHarness._free_manager(mgr)


## III-6: **`rotate_file`** resolve rechecks depth reserves in both swapped file columns.
static func _run_rotate_file_depth_recheck_both_columns(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rot0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rot1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	var rear0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var rear1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 1)
	if rot0.is_empty() or rot1.is_empty() or rear0.is_empty() or rear1.is_empty():
		CombatRegressionHarness._fail(failures, "rotate_depth_recheck: missing 2x2 fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.combat_clock = 1.0
	var id0: int = _EntityAccess.id_int(rot0)
	var id1: int = _EntityAccess.id_int(rot1)
	var rear0_id: int = _EntityAccess.id_int(rear0)
	var rear1_id: int = _EntityAccess.id_int(rear1)
	_FormationFlow.start_rotate_file(mgr, id0, id1)
	_FormationFlow.handle_rotate_file_resolve(
		mgr,
		{"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}}
	)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	var delay0: float = _EventScheduler.get_next_action_ready_at(mgr, rear0_id) - mgr.combat_clock
	var delay1: float = _EventScheduler.get_next_action_ready_at(mgr, rear1_id) - mgr.combat_clock
	CombatRegressionHarness._free_manager(mgr)
	if absf(delay0 - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"rotate_depth_recheck: file-0 reserve want delay %.2f got %.2f" % [want, delay0]
		)
	if absf(delay1 - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"rotate_depth_recheck: file-1 reserve want delay %.2f got %.2f" % [want, delay1]
		)


## III-6: Skirmish rotate gauge suffix when rank-0 gap and **`rotate_file`** listed.
static func _run_skirmish_rotate_gauge_suffix_when_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "skirmish_rotate_gauge: expected skirmish mode")
		CombatRegressionHarness._free_manager(mgr)
		return
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rot_src.is_empty():
		CombatRegressionHarness._fail(failures, "skirmish_rotate_gauge: missing hole/rotate fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	rot_src["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rot_src))
	_PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rot_src, acts)
	var stamp: String = str(
		rot_src.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
	).strip_edges()
	CombatRegressionHarness._free_manager(mgr)
	if "Line gap" not in stamp:
		CombatRegressionHarness._fail(
			failures, "skirmish_rotate_gauge: want rotate gap suffix on gauge stamp got %s" % stamp
		)


## III-6: **`swap_rank`** resolve rechecks rank-2+ reserves in the swapped column.
static func _run_swap_rank_depth_recheck_rank2_after_resolve(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rank0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rank1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var rank2: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 2, 0)
	if rank0.is_empty() or rank1.is_empty() or rank2.is_empty():
		CombatRegressionHarness._fail(failures, "swap_depth_recheck: missing 1x3 column fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.combat_clock = 1.0
	var id0: int = _EntityAccess.id_int(rank0)
	var id1: int = _EntityAccess.id_int(rank1)
	var rank2_id: int = _EntityAccess.id_int(rank2)
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	_FormationFlow.handle_swap_rank_resolve(
		mgr,
		{"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
	)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	var delay2: float = _EventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
	var delay1: float = _EventScheduler.get_next_action_ready_at(mgr, id1) - mgr.combat_clock
	var prom: float = CombatConstants.READY_DELAY_AFTER_PROMOTION_S
	CombatRegressionHarness._free_manager(mgr)
	if absf(delay2 - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"swap_depth_recheck: rank-2 want delay %.2f got %.2f" % [want, delay2]
		)
	if absf(delay1 - prom) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"swap_depth_recheck: demoted rank-1 want promotion %.2f got %.2f" % [prom, delay1]
		)


## III-6: **`reschedule_same_file_depth_rank2_plus`** wakes rank-2+ in a column (wired from swap / fall_back resolve).
static func _run_same_file_depth_rank2_plus_scheduler(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rank1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var rank2: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 2, 0)
	if rank1.is_empty() or rank2.is_empty():
		CombatRegressionHarness._fail(failures, "rank2_plus_scheduler: missing rank-1/rank-2 fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	rank1["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	mgr.combat_clock = 1.0
	var rank2_id: int = _EntityAccess.id_int(rank2)
	_EventScheduler.reschedule_same_file_depth_rank2_plus(mgr, "player", 0)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	var delay2: float = _EventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
	CombatRegressionHarness._free_manager(mgr)
	if absf(delay2 - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"rank2_plus_scheduler: rank-2 want delay %.2f got %.2f" % [want, delay2]
		)


## III-6: lone rank-0 **`fall_back_solo`** demotes when the rear slot in-column is empty (ii5-style).
static func _run_fall_back_solo_demotes_when_rear_slot_empty(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{
			"files": 1,
			"ranks": 2,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 1, "ranks": 1, "density": "normal"}
	)
	var rank0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if rank0.is_empty():
		CombatRegressionHarness._fail(failures, "fall_back_solo_demote: missing rank-0 fixture")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.combat_clock = 1.0
	var rank0_id: int = _EntityAccess.id_int(rank0)
	rank0["state"] = CombatConstants.STATE_FALLING_BACK
	rank0["state_timer"] = float(rank0.get("state_duration", CombatConstants.BASE_FALL_BACK_S))
	_FormationFlow.handle_fall_back_solo_resolve(
		mgr,
		{"combatant_id": rank0_id, "resolve_at": 0.0, "data": {}}
	)
	var after: Dictionary = _EntityAccess.manager_get_combatant(mgr, rank0_id)
	var rank_after: int = _EntityAccess.rank_int(after)
	CombatRegressionHarness._free_manager(mgr)
	if rank_after != 1:
		CombatRegressionHarness._fail(
			failures, "fall_back_solo_demote: want rank1 got rank=%d" % rank_after
		)


## III-6: sparse column (rank-0 + rank-2, empty rank-1) — solo fall_back demotes without vacancy undo; rank-2 recheck delay.
static func _run_fall_back_solo_depth_recheck_rank2_after_resolve(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rank0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rank1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var rank2: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 2, 0)
	if rank0.is_empty() or rank1.is_empty() or rank2.is_empty():
		CombatRegressionHarness._fail(failures, "fall_back_depth_recheck: missing 1x3 column fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	rank1["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	mgr.combat_clock = 1.0
	var rank0_id: int = _EntityAccess.id_int(rank0)
	var rank2_id: int = _EntityAccess.id_int(rank2)
	rank0["state"] = CombatConstants.STATE_FALLING_BACK
	rank0["state_timer"] = float(rank0.get("state_duration", CombatConstants.BASE_FALL_BACK_S))
	_FormationFlow.handle_fall_back_solo_resolve(
		mgr,
		{"combatant_id": rank0_id, "resolve_at": 0.0, "data": {}}
	)
	var after: Dictionary = _EntityAccess.manager_get_combatant(mgr, rank0_id)
	var rank_after: int = _EntityAccess.rank_int(after)
	var delay2: float = _EventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	CombatRegressionHarness._free_manager(mgr)
	if rank_after != 1:
		CombatRegressionHarness._fail(
			failures,
			"fall_back_depth_recheck: want rank1 got rank=%d delay2=%.2f" % [rank_after, delay2]
		)
	if absf(delay2 - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"fall_back_depth_recheck: rank-2 want delay %.2f got %.2f" % [want, delay2]
		)


## III-6: incap plug-forward copy surfaces on formation gauge suffix when **`swap_rank`** listed.
static func _harness_plug_forward_incap_fixtures(mgr: Node) -> Dictionary:
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	return {"front": front, "rear": rear}


static func _run_plug_forward_gauge_suffix_when_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var fx: Dictionary = _harness_plug_forward_incap_fixtures(mgr)
	var front: Dictionary = fx["front"]
	var rear: Dictionary = fx["rear"]
	if front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "plug_forward_gauge: missing front/rear")
		CombatRegressionHarness._free_manager(mgr)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front.state = CombatConstants.STATE_COWERING
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rear))
	if not _EntityAccess.is_incapacitated(front):
		CombatRegressionHarness._fail(failures, "plug_forward_gauge: want incapacitated front partner")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
		CombatRegressionHarness._fail(failures, "plug_forward_gauge: want swap_rank listed over incap front")
		CombatRegressionHarness._free_manager(mgr)
		return
	_PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rear, acts)
	var stamp: String = str(
		rear.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
	).strip_edges()
	CombatRegressionHarness._free_manager(mgr)
	if "Partner down" not in stamp:
		CombatRegressionHarness._fail(
			failures, "plug_forward_gauge: want partner-down suffix on gauge stamp got %s" % stamp
		)


## III-6 maintain: rear lists swap_rank to plug rank-0 hole when relief fitness gate blocks.
static func _run_swap_rank_listed_line_plug_when_relief_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want relief swap blocked for listing test")
		CombatRegressionHarness._free_manager(mgr)
		return
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rear))
	if not _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
		CombatRegressionHarness._fail(failures, "swap_rank_listed_plug: want swap_rank listed when line has hole")
	CombatRegressionHarness._free_manager(mgr)


## III-6 maintain: resolve accepts line-plug **`swap_rank`** when relief fitness gate blocks listing-only path.
static func _run_swap_rank_resolve_line_plug_when_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	var front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	if hole_front.is_empty() or rear.is_empty() or front.is_empty():
		CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: missing hole/rear/front fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_line_has_rank0_gap(mgr, "player"):
		CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want rank-0 gap on line after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _AIPicker.is_relief_swap_tactically_allowed(rear, front):
		CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want relief swap blocked for resolve test")
		CombatRegressionHarness._free_manager(mgr)
		return
	var rear_id: int = _EntityAccess.id_int(rear)
	var front_id: int = _EntityAccess.id_int(front)
	rear["gauge"] = 100.0
	front["gauge"] = 100.0
	rear["state"] = CombatConstants.STATE_WAITING
	var acts: Array = _ActionsBuilder.build(mgr, rear_id)
	if not _ListedActions.actions_include_move_vs_target(
		acts, front_id, CombatConstants.MOVE_ID_SWAP_RANK
	):
		CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: want swap_rank listed vs front partner")
		CombatRegressionHarness._free_manager(mgr)
		return
	var ok: bool = _ResolveAction.resolve(mgr, rear_id, front_id, CombatConstants.MOVE_ID_SWAP_RANK, {})
	CombatRegressionHarness._free_manager(mgr)
	if not ok:
		CombatRegressionHarness._fail(failures, "swap_rank_resolve_plug: resolve should accept line-plug swap_rank")


## III-6: line-plug copy surfaces on formation gauge suffix when **`swap_rank`** listed.
static func _run_line_plug_gauge_suffix_when_swap_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	if hole_front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "line_plug_gauge: missing hole/rear fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rear))
	_PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, rear, acts)
	var stamp: String = str(
		rear.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
	).strip_edges()
	CombatRegressionHarness._free_manager(mgr)
	if "Front gap" not in stamp:
		CombatRegressionHarness._fail(failures, "line_plug_gauge: want plug suffix on gauge stamp got %s" % stamp)


## III-6: rank-1 turn resolves → rank-2+ same-file reserves get formation recheck delay.
static func _run_same_file_depth_recheck_after_rank1_turn(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 3, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var rank1: Dictionary = {}
	var rank2: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.rank_int(c) == 1:
			rank1 = c
		elif _EntityAccess.rank_int(c) == 2:
			rank2 = c
	if rank1.is_empty() or rank2.is_empty():
		CombatRegressionHarness._fail(failures, "depth_recheck_rank1: missing rank-1/rank-2 column")
		CombatRegressionHarness._free_manager(mgr)
		return
	var rank1_id: int = _EntityAccess.id_int(rank1)
	var rank2_id: int = _EntityAccess.id_int(rank2)
	mgr.skip_turn(rank1_id)
	var delay: float = (
		_EventScheduler.get_next_action_ready_at(mgr, rank2_id) - mgr.combat_clock
	)
	var want: float = CombatConstants.READY_DELAY_FORMATION_RECHECK_S
	if absf(delay - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"depth_recheck_rank1: want delay %.2f got %.2f" % [want, delay]
		)
	CombatRegressionHarness._free_manager(mgr)


## p4f UX: front-gap swap hint when line-plug **`swap_rank`** is listed.
static func _run_front_gap_line_plug_hint_when_swap_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rear: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 1, 0)
	if hole_front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "front_gap_hint: missing hole/rear fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rear))
	var hint: String = _PlayerTurnHints.front_gap_line_plug_hint(mgr, rear, acts)
	if "Front gap" not in hint:
		CombatRegressionHarness._fail(failures, "front_gap_hint: want plug copy got %s" % hint)
	CombatRegressionHarness._free_manager(mgr)


## p4f UX: Skirmish rotate hint when rank-0 gap and **`rotate_file`** listed.
static func _run_skirmish_line_gap_rotate_hint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: expected skirmish mode")
		CombatRegressionHarness._free_manager(mgr)
		return
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rot_tgt: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
		CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: missing hole/rotate fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_rank0_hole(mgr, "player"):
		CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	rot_src["gauge"] = 100.0
	rot_tgt["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rot_src))
	var hint: String = _PlayerTurnHints.skirmish_line_gap_rotate_hint(mgr, rot_src, acts)
	if "Line gap" not in hint:
		CombatRegressionHarness._fail(failures, "skirmish_rotate_hint: want rotate gap copy got %s" % hint)
	CombatRegressionHarness._free_manager(mgr)


## III-6: Skirmish rank-0 hole boosts **`rotate_file`** weight even without depth ranks.
static func _run_rotate_line_plug_weight_skirmish_rank0_hole(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: expected skirmish mode")
		CombatRegressionHarness._free_manager(mgr)
		return
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rot_tgt: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
		CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: missing hole/rotate fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if not _FormationFlow.formation_has_rank0_hole(mgr, "player"):
		CombatRegressionHarness._fail(failures, "rotate_skirmish_hole: want rank-0 hole after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(
			failures, "rotate_skirmish_hole: skirmish 1-rank should not expose depth plug opportunity"
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var rot_act: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_ROTATE_FILE,
		"target_id": _EntityAccess.id_int(rot_tgt),
	}
	var w: float = _AIPicker._get_action_weight(
		rot_act, _EntityAccess.id_int(rot_src), mgr, true, {}, {}
	)
	if w < CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"rotate_skirmish_hole: want >= %.2f got %.3f"
			% [CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT, w]
		)
	CombatRegressionHarness._free_manager(mgr)


## p4f UX: plug-forward hint when **`swap_rank`** lists over incapacitated rank-0 partner.
static func _run_plug_forward_incap_partner_hint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var fx: Dictionary = _harness_plug_forward_incap_fixtures(mgr)
	var front: Dictionary = fx["front"]
	var rear: Dictionary = fx["rear"]
	if front.is_empty() or rear.is_empty():
		CombatRegressionHarness._fail(failures, "plug_forward_hint: missing front/rear")
		CombatRegressionHarness._free_manager(mgr)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	front.state = CombatConstants.STATE_COWERING
	_MobilityRetreat.sync_cowering_state_if_no_functional_arm(front)
	rear["gauge"] = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(rear))
	if not _EntityAccess.is_incapacitated(front):
		CombatRegressionHarness._fail(failures, "plug_forward_hint: want incapacitated front partner")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_SWAP_RANK):
		CombatRegressionHarness._fail(failures, "plug_forward_hint: want swap_rank listed over incap front")
		CombatRegressionHarness._free_manager(mgr)
		return
	var hint: String = _PlayerTurnHints.plug_forward_incap_partner_hint(mgr, rear, acts)
	if "Partner down" not in hint:
		CombatRegressionHarness._fail(failures, "plug_forward_hint: want partner-down copy got %s" % hint)
	CombatRegressionHarness._free_manager(mgr)


## III-6 maintain: rotate_file gets line-plug floor when rank-0 hole exists (weight path).
static func _run_rotate_file_line_plug_weight_when_front_hole(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 10:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var hole_front: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	var rot_src: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var rot_tgt: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if hole_front.is_empty() or rot_src.is_empty() or rot_tgt.is_empty():
		CombatRegressionHarness._fail(failures, "rotate_line_plug: missing hole/rotate fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	hole_front["alive"] = false
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	_FormationSlots.prune_dead_ids_from_formation_slots(mgr, slots)
	if _FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(0, 4)):
		CombatRegressionHarness._fail(failures, "rotate_line_plug: want empty rank-0 file 4 after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _FormationFlow.formation_has_frontline_fill_opportunity(mgr, "player"):
		CombatRegressionHarness._fail(failures, "rotate_line_plug: want rank-0 hole on line after kill")
		CombatRegressionHarness._free_manager(mgr)
		return
	var rot_act: Dictionary = {
		"move_id": CombatConstants.MOVE_ID_ROTATE_FILE,
		"target_id": _EntityAccess.id_int(rot_tgt),
	}
	var w: float = _AIPicker._get_action_weight(
		rot_act, _EntityAccess.id_int(rot_src), mgr, true, {}, {}
	)
	if w < CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"rotate_line_plug: want >= %.2f got %.3f"
			% [CombatConstants.AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT, w]
		)
	CombatRegressionHarness._free_manager(mgr)


## III-4 Track A PR3 (**2b**): Skirmish wide side skips native line compaction when outnumbering on files.
static func _run_geometry_skirmish_wide_line_no_compact(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1}, {"files": 3, "ranks": 1})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: expected skirmish mode")
	var players_r0: Array = []
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "player"):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		players_r0.append(c)
	if players_r0.size() != 3:
		CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: expected 3 player rank-0")
	players_r0.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return _EntityAccess.id_int(a) < _EntityAccess.id_int(b)
	)
	var want_files: Array[int] = [2, 3, 4]
	var form_player: Dictionary = mgr.formations["player"]
	var slots: Dictionary = _FormationSlots.formation_slots_dict(form_player)
	for i in range(3):
		var c: Dictionary = players_r0[i]
		var nid: int = _EntityAccess.id_int(c)
		_FormationSlots.remove_combatant_from_slots(slots, nid)
		var wf: int = want_files[i]
		c["file"] = wf
		_FormationSlots.slot_set_single(slots, Vector2i(0, wf), nid)
	if _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "player"):
		CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: wide player should skip skirmish compaction")
	for i in range(3):
		if _EntityAccess.file_int(players_r0[i]) != want_files[i]:
			CombatRegressionHarness._fail(
				failures,
				"geometry_skirmish_wide: player rank-0 file shifted want %s got %d"
				% [str(want_files), _EntityAccess.file_int(players_r0[i])]
			)
	# Narrower enemy side may still compact when rank-0 has gaps.
	var enemies_r0: Array = []
	for c in mgr.combatants:
		if not _EntityAccess.is_alive_on_side(c, "enemy"):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		enemies_r0.append(c)
	enemies_r0.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return _EntityAccess.id_int(a) < _EntityAccess.id_int(b)
	)
	var form_enemy: Dictionary = mgr.formations["enemy"]
	var eslots: Dictionary = _FormationSlots.formation_slots_dict(form_enemy)
	for c in enemies_r0:
		_FormationSlots.remove_combatant_from_slots(eslots, _EntityAccess.id_int(c))
	for i in range(enemies_r0.size()):
		var ec: Dictionary = enemies_r0[i]
		var eid: int = _EntityAccess.id_int(ec)
		var ef: int = i + 1
		ec["file"] = ef
		_FormationSlots.slot_set_single(eslots, Vector2i(0, ef), eid)
	if not _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
		CombatRegressionHarness._fail(failures, "geometry_skirmish_wide: narrow enemy with gaps should compact")
	for i in range(enemies_r0.size()):
		if _EntityAccess.file_int(enemies_r0[i]) != i:
			CombatRegressionHarness._fail(
				failures,
				"geometry_skirmish_wide: enemy compact want file %d got %d" % [i, _EntityAccess.file_int(enemies_r0[i])]
			)
	CombatRegressionHarness._free_manager(mgr)


## III-4 Track A PR5 (**3b**): Skirmish outnumber allows **`rotate_file`** on wider side only.
static func _run_skirmish_outnumber_allows_rotate_file(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.engagement_mode(mgr)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(failures, "skirmish_rotate: expected skirmish mode")
	if not _EngagementMode.allow_rotate_file_for_formation(mgr, "player"):
		CombatRegressionHarness._fail(failures, "skirmish_rotate: wide player should allow rotate_file")
	if _EngagementMode.allow_rotate_file_for_formation(mgr, "enemy"):
		CombatRegressionHarness._fail(failures, "skirmish_rotate: narrow enemy should not allow rotate_file")
	var p0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var p1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if p0.is_empty() or p1.is_empty():
		CombatRegressionHarness._fail(failures, "skirmish_rotate: need adjacent player rank-0 allies")
	else:
		p0["gauge"] = 100.0
		p1["gauge"] = 100.0
		var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(p0))
		var saw_rotate: bool = not _ListedActions.first_action_move_vs_target(
			acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(p1)
		).is_empty()
		if not saw_rotate:
			CombatRegressionHarness._fail(
				failures, "skirmish_rotate: player file-0 should list rotate_file vs file-1 in skirmish outnumber"
			)
	var e0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
	var e1: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 1)
	if e0.is_empty() or e1.is_empty():
		CombatRegressionHarness._fail(failures, "skirmish_rotate: need adjacent enemy rank-0 allies")
	else:
		e0["gauge"] = 100.0
		e1["gauge"] = 100.0
		var e_acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(e0))
		if _ListedActions.first_action_move_vs_target(
			e_acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(e1)
		).is_empty() == false:
			CombatRegressionHarness._fail(failures, "skirmish_rotate: narrow enemy should not list rotate_file")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: post-attrition mop-up (4v1 tail) — `envelop_mop_up_active`, MID close listing, rotate suppress.
static func _harness_7v3_mop_up_mgr() -> Node:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var enemy_ids: Array = []
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			enemy_ids.append(_EntityAccess.id_int(c))
	for k in range(mini(2, enemy_ids.size())):
		CombatRegressionHarness._soak_kill_combatant(mgr, int(enemy_ids[k]))
	return mgr


static func _run_envelop_mop_up_active_after_attrition(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "envelop_mop_up: expected active after 7v1 attrition")
	if _CombatDoctrine.envelop_mop_up_active(mgr, "enemy"):
		CombatRegressionHarness._fail(failures, "envelop_mop_up: narrow enemy should not have mop-up advantage")
	CombatRegressionHarness._free_manager(mgr)


static func _run_envelop_close_listed_mid_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_close_mid: missing player/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(player, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_MID
	if not _MeleeListing.attempt_close_listed_for_pair(
		mgr, player, enemy_id, CombatConstants.DISTANCE_MID
	):
		CombatRegressionHarness._fail(failures, "envelop_close_mid: want attempt_close listed at MID during mop-up")
	dist[enemy_id] = CombatConstants.DISTANCE_LONG
	if not _MeleeListing.attempt_close_listed_for_pair(
		mgr, player, enemy_id, CombatConstants.DISTANCE_LONG
	):
		CombatRegressionHarness._fail(failures, "envelop_close_mid: want attempt_close listed at LONG during mop-up")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `resolve_close_attempt` accepts MID band during mop-up (not `not_long` telemetry).
static func _run_envelop_close_resolve_mid_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_close_resolve: missing player/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
		player["distance_to"] = {}
	if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
		enemy["distance_to"] = {}
	(player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
	(enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
	if mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		mgr.remove_meta(_TacticalCombat.META_COMBAT_TELEMETRY)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_close_resolve_blocked", 0)) >= 1:
			CombatRegressionHarness._fail(
				failures,
				"envelop_close_resolve: MID mop-up must not increment invalid_close_resolve_blocked"
			)
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `resolve_close_attempt` accepts CLOSE band during mop-up (listing/resolve parity).
static func _run_envelop_close_resolve_close_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_close_resolve_close: missing player/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	if typeof(player.get("distance_to", null)) != TYPE_DICTIONARY:
		player["distance_to"] = {}
	if typeof(enemy.get("distance_to", null)) != TYPE_DICTIONARY:
		enemy["distance_to"] = {}
	(player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_CLOSE
	(enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_CLOSE
	if mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		mgr.remove_meta(_TacticalCombat.META_COMBAT_TELEMETRY)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_close_resolve_blocked", 0)) >= 1:
			CombatRegressionHarness._fail(
				failures,
				"envelop_close_resolve_close: CLOSE mop-up must not increment invalid_close_resolve_blocked"
			)
	CombatRegressionHarness._free_manager(mgr)


static func _run_envelop_mop_up_rotate_suppressed(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var partner: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 1)
	if wing.is_empty() or partner.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_rotate: need adjacent rank-0 wing pair")
		CombatRegressionHarness._free_manager(mgr)
		return
	wing["gauge"] = 100.0
	partner["gauge"] = 100.0
	var wing_id: int = _EntityAccess.id_int(wing)
	var acts: Array = _ActionsBuilder.build(mgr, wing_id)
	var reserve_only: Array = []
	for raw in acts:
		var a: Dictionary = _ListedActions._entry(raw)
		if a.is_empty():
			continue
		var mid: String = _ListedActions.entry_move_id(a)
		if mid == CombatConstants.MOVE_ID_WAIT or CombatConstants.is_focus_line_move(mid):
			reserve_only.append(a)
		elif mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			reserve_only.append(a)
	if not _CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, wing, reserve_only):
		CombatRegressionHarness._fail(
			failures, "envelop_rotate: should_suppress when mop-up and no melee strikes in menu"
		)
	if _ListedActions.actions_include_move_id(acts, CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
		if not _ListedActions.first_action_move_vs_target(
			acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(partner)
		).is_empty():
			CombatRegressionHarness._fail(
				failures, "envelop_rotate: must not list rotate_file when close is listed during mop-up"
			)
	elif not _ListedActions.action_list_has_hostile_melee_strike(acts, wing_id):
		if not _ListedActions.first_action_move_vs_target(
			acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(partner)
		).is_empty():
			CombatRegressionHarness._fail(
				failures, "envelop_rotate: must not list rotate_file without melee during mop-up"
			)
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: fled allies do not count toward mop-up standing advantage.
static func _run_envelop_mop_up_excludes_fled_allies(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var fled_count: int = 0
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c) or not _EntityAccess.is_standing_combatant(c):
			continue
		if fled_count >= 3:
			break
		c["combat_absent"] = true
		c["state"] = CombatConstants.STATE_FLED
		fled_count += 1
	if not _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(
			failures,
			"envelop_mop_up_fled: want active with 4 standing vs 1 enemy got inactive"
		)
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: fled enemies are not living hostiles (listing / opposition / close slots).
static func _run_living_hostile_excludes_fled_enemy(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	enemy["combat_absent"] = true
	enemy["state"] = CombatConstants.STATE_FLED
	if _EntityAccess.is_living_hostile_to(player, enemy):
		CombatRegressionHarness._fail(failures, "living_hostile_fled: fled enemy must not be hostile target")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: flee purges stale **`distance_to`** / melee ordering (no ghost `e9:close` after rout).
static func _run_fled_enemy_distance_to_purged_after_recompute(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var fled: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy") and _EntityAccess.file_int(c) == 2:
			fled = c
			break
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 4)
	if fled.is_empty() or player.is_empty():
		CombatRegressionHarness._fail(failures, "fled_distance_to: missing fled enemy or player fixture")
		CombatRegressionHarness._free_manager(mgr)
		return
	var fled_id: int = _EntityAccess.id_int(fled)
	_EntityAccess.nested_dictionary_for_mutation(player, "distance_to")[fled_id] = CombatConstants.DISTANCE_CLOSE
	fled["combat_absent"] = true
	fled["state"] = CombatConstants.STATE_FLED
	mgr._recompute_zoc_and_distance()
	var d_to: Dictionary = _EntityAccess.nested_dictionary_read(player, "distance_to")
	if d_to.has(fled_id):
		CombatRegressionHarness._fail(
			failures,
			"fled_distance_to: want fled id purged from distance_to after recompute"
		)
	var ordered: Array = _TargetScoring.ordered_melee_opponents(mgr, player, mgr.combatants, 0)
	for opp in ordered:
		if _EntityAccess.id_int(opp) == fled_id:
			CombatRegressionHarness._fail(
				failures,
				"fled_distance_to: ordered_melee_opponents must exclude fled enemy"
			)
	if ordered.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"fled_distance_to: want living enemy targets after one flee"
		)
	_DistanceBands.purge_stale_distance_to_entries(mgr)
	if _EntityAccess.nested_dictionary_read(player, "distance_to").has(fled_id):
		CombatRegressionHarness._fail(
			failures,
			"fled_distance_to: purge_stale_distance_to_entries should be idempotent safe"
		)
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `CombatResolveAction` rejects `rotate_file` during mop-up when listing would suppress.
static func _run_envelop_resolve_rotate_rejected_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var wing: Dictionary = {}
	var partner: Dictionary = {}
	for file_i in range(7):
		var cand: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
			mgr, "player", 0, file_i
		)
		if cand.is_empty():
			continue
		cand["gauge"] = 100.0
		var cand_id: int = _EntityAccess.id_int(cand)
		var cand_acts: Array = _ActionsBuilder.build(mgr, cand_id)
		if not _CombatDoctrine.should_suppress_skirmish_rotate_file(mgr, cand, cand_acts):
			continue
		for delta in [-1, 1]:
			var adj: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
				mgr, "player", 0, file_i + delta
			)
			if adj.is_empty():
				continue
			adj["gauge"] = 100.0
			wing = cand
			partner = adj
			break
		if not wing.is_empty():
			break
	if wing.is_empty() or partner.is_empty():
		CombatRegressionHarness._fail(
			failures, "envelop_resolve_rotate: need rank-0 pair with mop-up rotate suppress on live menu"
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var wing_id: int = _EntityAccess.id_int(wing)
	var partner_id: int = _EntityAccess.id_int(partner)
	var committed: bool = _ResolveAction.resolve(
		mgr, wing_id, partner_id, CombatConstants.MOVE_ID_ROTATE_FILE, {}
	)
	if committed:
		CombatRegressionHarness._fail(failures, "envelop_resolve_rotate: must reject rotate_file during mop-up")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: true 1v1 standing duel is not envelop mop-up (min standing advantage).
static func _run_envelop_mop_up_inactive_true_duel(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if _CombatDoctrine.envelop_mop_up_active(mgr, "player"):
		CombatRegressionHarness._fail(failures, "envelop_mop_up_duel: 1v1 should not activate mop-up")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: `attempt_close` listed at CLOSE band during mop-up (band/reach gap).
static func _run_envelop_close_listed_close_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_close_close: missing player/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var dist: Dictionary = _EntityAccess.nested_dictionary_for_mutation(player, "distance_to")
	dist[enemy_id] = CombatConstants.DISTANCE_CLOSE
	if not _MeleeListing.attempt_close_listed_for_pair(
		mgr, player, enemy_id, CombatConstants.DISTANCE_CLOSE
	):
		CombatRegressionHarness._fail(failures, "envelop_close_close: want attempt_close listed at CLOSE during mop-up")
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: mop-up lists melee at CLOSE when band/reach gap would otherwise close-only stall.
static func _run_envelop_melee_strike_listed_close_mop_up_reach_gap(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if center.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "envelop_strike_close: missing center/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	center["gauge"] = 100.0
	var c_id: int = _EntityAccess.id_int(center)
	var e_id: int = _EntityAccess.id_int(enemy)
	var dist_c: Dictionary = _EntityAccess.nested_dictionary_for_mutation(center, "distance_to")
	dist_c[e_id] = CombatConstants.DISTANCE_CLOSE
	var dist_e: Dictionary = _EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")
	dist_e[c_id] = CombatConstants.DISTANCE_CLOSE
	var melee_range: float = _MeleeListing.melee_weapon_reach(center)
	var eff_dist: float = _PairGeometry.effective_pair_eff_dist(mgr, center, enemy)
	var reach_gap: bool = not _PairGeometry.melee_reach_covers_eff_dist(melee_range, eff_dist)
	if not _MeleeListing.can_melee_threaten(mgr, center, enemy):
		CombatRegressionHarness._fail(
			failures,
			"envelop_strike_close: can_melee_threaten want true at CLOSE during mop-up (reach_gap=%s)"
			% str(reach_gap).to_lower()
		)
	var acts: Array = _ActionsBuilder.build(mgr, c_id)
	if not _ListedActions.action_list_has_hostile_melee_strike(acts, c_id):
		CombatRegressionHarness._fail(
			failures,
			"envelop_strike_close: want listed melee strike at CLOSE during mop-up (reach_gap=%s)"
			% str(reach_gap).to_lower()
		)
	if _ListedActions.action_list_is_reserve_posture_only(acts):
		CombatRegressionHarness._fail(
			failures, "envelop_strike_close: reserve_only menu must not hold when strikes listed"
		)
	var mgr_duel: Node = _MgrScript.new()
	for _i in 2:
		mgr_duel.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		mgr_duel.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_duel.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	var p0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr_duel, "player", 0, 0)
	var e0: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr_duel, "enemy", 0, 0)
	if not p0.is_empty() and not e0.is_empty():
		var p_id: int = _EntityAccess.id_int(p0)
		var e0_id: int = _EntityAccess.id_int(e0)
		_EntityAccess.nested_dictionary_for_mutation(p0, "distance_to")[e0_id] = CombatConstants.DISTANCE_CLOSE
		_EntityAccess.nested_dictionary_for_mutation(e0, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
		var eff_duel: float = _PairGeometry.effective_pair_eff_dist(mgr_duel, p0, e0)
		if not _PairGeometry.melee_reach_covers_eff_dist(_MeleeListing.melee_weapon_reach(p0), eff_duel):
			if _MeleeListing.can_melee_threaten(mgr_duel, p0, e0):
				CombatRegressionHarness._fail(
					failures,
					"envelop_strike_close: 1v1 must not bypass reach without mop-up"
				)
	CombatRegressionHarness._free_manager(mgr_duel)
	CombatRegressionHarness._free_manager(mgr)


static func _run_pincer_wing_commitment_propagates_from_center(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var center: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
	if center.is_empty() or wing.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "pincer_propagate: missing center/wing/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _CombatDoctrine.pincer_role_for_combatant(mgr, center) != _CombatDoctrine.PINCER_ROLE_CENTER:
		CombatRegressionHarness._fail(failures, "pincer_propagate: file-3 player want center role")
	if _CombatDoctrine.pincer_role_for_combatant(mgr, wing) != _CombatDoctrine.PINCER_ROLE_FLANK_WING:
		CombatRegressionHarness._fail(failures, "pincer_propagate: file-0 player want flank_wing role")
	var center_id: int = _EntityAccess.id_int(center)
	var enemy_id: int = _EntityAccess.id_int(enemy)
	var want_wing_tgt: int = _CombatDoctrine.preferred_pincer_flank_enemy_id(mgr, wing)
	if want_wing_tgt < 0:
		CombatRegressionHarness._fail(failures, "pincer_propagate: wing should have preferred flank enemy")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, center_id, enemy_id)
	var got_tgt: int = int(wing.get("doctrine_target_commit_id", -1))
	if got_tgt != want_wing_tgt:
		CombatRegressionHarness._fail(
			failures,
			"pincer_propagate: wing commit want %d got %d" % [want_wing_tgt, got_tgt]
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_pincer_preferred_flank_target_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 7:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var wing: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 0)
	var pref_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 0)
	var off_enemy: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "enemy", 0, 2)
	if wing.is_empty() or pref_enemy.is_empty() or off_enemy.is_empty():
		CombatRegressionHarness._fail(failures, "pincer_target_mult: missing wing/enemy fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var m_pref: float = _TargetScoring.pincer_preferred_flank_target_mult(mgr, wing, pref_enemy)
	var m_off: float = _TargetScoring.pincer_preferred_flank_target_mult(mgr, wing, off_enemy)
	if not is_equal_approx(m_pref, CombatConstants.DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT):
		CombatRegressionHarness._fail(
			failures,
			"pincer_target_mult: preferred enemy want %.4f got %.4f"
			% [CombatConstants.DOCTRINE_PINCER_PREFERRED_FLANK_TARGET_MULT, m_pref]
		)
	if not is_equal_approx(m_off, 1.0):
		CombatRegressionHarness._fail(failures, "pincer_target_mult: off-preference enemy want 1.0 got %.4f" % m_off)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.4: mirrored line → same cohesion → same `engagement_posture` (two-pass recompute + coupling neutral when equal).
static func _run_posture_mirror_symmetric(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var fp: String = str(mgr.formations["player"].get("engagement_posture", ""))
	var fe: String = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp.is_empty() or fe.is_empty():
		CombatRegressionHarness._fail(failures, "posture_mirror: missing posture player=%s enemy=%s" % [fp, fe])
	elif fp != fe:
		CombatRegressionHarness._fail(failures, "posture_mirror: symmetric presets expected same posture got %s vs %s" % [fp, fe])
	_FormationEngagement.recompute_all(mgr)
	fp = str(mgr.formations["player"].get("engagement_posture", ""))
	fe = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp != fe:
		CombatRegressionHarness._fail(failures, "posture_mirror: after recompute_all expected same posture got %s vs %s" % [fp, fe])
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.5: encounter `morale_cohesion_*` lowers `line_cohesion` vs default factor 1.0.
static func _run_morale_cohesion_affects_line_cohesion(failures: PackedStringArray) -> void:
	var m_base: Node = _MgrScript.new()
	m_base.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m_base.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m_base.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_base: float = float(m_base.formations["player"].get("line_cohesion", 1.0))
	var m_low: Node = _MgrScript.new()
	m_low.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m_low.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m_low.encounter[CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER] = 0.35
	m_low.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_low: float = float(m_low.formations["player"].get("line_cohesion", 1.0))
	if coh_low >= coh_base - 0.001:
		CombatRegressionHarness._fail(
			failures,
			"morale_cohesion: expected lower player line_cohesion with low morale (base=%.4f low=%.4f)"
			% [coh_base, coh_low]
		)
	var m_agg: Node = _MgrScript.new()
	m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m_agg.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m_agg.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var coh_agg_hi: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	m_agg.combatants[0]["morale_cohesion"] = 0.2
	m_agg.combatants[1]["morale_cohesion"] = 0.2
	_FormationEngagement.recompute_all(m_agg)
	var coh_agg_lo: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	if coh_agg_lo >= coh_agg_hi - 0.001:
		CombatRegressionHarness._fail(
			failures,
			"morale_cohesion: combatant mean should drop cohesion (hi=%.4f lo=%.4f)" % [coh_agg_hi, coh_agg_lo]
		)
	CombatRegressionHarness._free_manager(m_base)
	CombatRegressionHarness._free_manager(m_low)
	CombatRegressionHarness._free_manager(m_agg)


static func _run_engagement_classifier_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 64:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var snap: Dictionary = _EngagementMode.snapshot(mgr)
		var raw: String = str(snap.get("raw_mode", ""))
		if raw == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				CombatRegressionHarness._fail(
					failures,
					"classifier_fuzz seed=%d: raw formation but can_enter false snap=%s" % [scenario_seed, str(snap)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "classifier_fuzz seed=%d" % scenario_seed)
		var resolved: String = _EngagementMode.engagement_mode(mgr)
		var resolved_again: String = _EngagementMode.engagement_mode(mgr)
		if resolved_again != resolved:
			CombatRegressionHarness._fail(
				failures,
				"classifier_fuzz seed=%d: engagement_mode not idempotent %s vs %s"
				% [scenario_seed, resolved, resolved_again]
			)
		if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				CombatRegressionHarness._fail(
					failures,
					"classifier_fuzz seed=%d: cold resolved formation but can_enter false snap=%s"
					% [scenario_seed, str(snap)]
				)
		CombatRegressionHarness._free_manager(mgr)


## Tier 1.7 (P8): Option 2 active-count floor — if either side has fewer actives than formation minimum, raw mode is never `formation`.
static func _run_engagement_active_count_gate_exhaustive(failures: PackedStringArray) -> void:
	var min_act: int = int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
	for pn in range(1, 8):
		for en in range(1, 8):
			if pn >= min_act and en >= min_act:
				continue
			var mgr: Node = _MgrScript.new()
			for _i in pn:
				mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
			for _j in en:
				mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
			mgr.start({}, {})
			var snap: Dictionary = _EngagementMode.snapshot(mgr)
			if str(snap.get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				CombatRegressionHarness._fail(
					failures,
					"active_gate: raw formation with active below min pn=%d en=%d snap=%s" % [pn, en, str(snap)]
				)
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				CombatRegressionHarness._fail(
					failures,
					"active_gate: resolved formation with active below min pn=%d en=%d snap=%s"
					% [pn, en, str(snap)]
				)
			CombatRegressionHarness._free_manager(mgr)


## Tier 1.7 (P8): second `start()` on same manager must not keep prior `formation` hysteresis (regression guard for `clear_resolved_mode_cache`).
static func _run_engagement_mode_cache_reset_on_second_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var m0: String = _EngagementMode.engagement_mode(mgr)
	if m0 != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(failures, "mode_cache_reset: expected first start formation-line mode got %s" % m0)
	# Rebuild as tiny duel on the **same** manager node.
	for c in mgr.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.free()
	mgr.combatants.clear()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var m1: String = _EngagementMode.engagement_mode(mgr)
	if m1 != CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(
			failures,
			"mode_cache_reset: after 1v1 restart expected duel got %s (stale formation cache?)" % m1
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.8 soak: deaths-only path must not return to resolved formation after leaving it (hysteresis / classifier stability).
static func _run_engagement_attrition_monotone(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 32:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(4, 8)
		var en: int = rng.randi_range(4, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var order: Array = []
		for c in mgr.combatants:
			order.append(_EntityAccess.id_int(c))
		CombatRegressionHarness._shuffle_int_array_in_place(order, rng)
		var left_formation: bool = false
		for cid in order:
			var cur: Variant = mgr._get_by_id(int(cid))
			if cur == null or not _EntityAccess.alive_bool(cur):
				continue
			CombatRegressionHarness._soak_kill_combatant(mgr, int(cid))
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved != CombatConstants.ENGAGEMENT_MODE_FORMATION:
				left_formation = true
			elif left_formation:
				CombatRegressionHarness._fail(
					failures,
					"attrition_monotone seed=%d: re-entered formation after leaving (last_kill_id=%d)" % [scenario_seed, cid]
				)
				break
			_assert_tactical_snapshot_matches(
				failures,
				mgr,
				"attrition_monotone seed=%d after_kill=%d" % [scenario_seed, cid]
			)
			var pa: int = _EngagementMode.count_active_for_side(mgr, "player")
			var ea: int = _EngagementMode.count_active_for_side(mgr, "enemy")
			if pa <= 0 or ea <= 0:
				break
		CombatRegressionHarness._free_manager(mgr)


## Tier 1.8 (P9): telemetry meta + embedded snapshot agree with resolved mode; no spurious transitions on cold start.
static func _run_telemetry_lock_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
			CombatRegressionHarness._fail(failures, "telemetry_lock seed=%d: missing combat telemetry meta" % scenario_seed)
		else:
			var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
			var mode: String = _EngagementMode.engagement_mode(mgr)
			if str(tel.get("last_resolved_mode", "")) != mode:
				CombatRegressionHarness._fail(
					failures,
					"telemetry_lock seed=%d: tel.last_resolved_mode=%s vs engagement_mode=%s"
					% [scenario_seed, tel.get("last_resolved_mode"), mode]
				)
			if int(tel.get("engagement_mode_transitions", -1)) != 0:
				CombatRegressionHarness._fail(
					failures,
					"telemetry_lock seed=%d: expected 0 mode transitions on cold start got %s"
					% [scenario_seed, str(tel.get("engagement_mode_transitions"))]
				)
			if (
				not tel.has("invalid_melee_resolve_blocked")
								or not tel.has("invalid_close_resolve_blocked")
			):
				CombatRegressionHarness._fail(
					failures,
					"telemetry_lock seed=%d: tel missing invalid_* keys (got keys=%s)"
					% [scenario_seed, str(tel.keys())]
				)
			if (
				int(tel.get("invalid_melee_resolve_blocked", -1)) != 0
								or int(tel.get("invalid_close_resolve_blocked", -1)) != 0
			):
				CombatRegressionHarness._fail(
					failures,
					"telemetry_lock seed=%d: expected 0 invalid melee/close on cold start tel=%s"
					% [scenario_seed, str(tel)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "telemetry_lock seed=%d" % scenario_seed)
		if mgr.has_meta("_tactical_mode_snapshot"):
			var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
			if not ts.has("telemetry"):
				CombatRegressionHarness._fail(failures, "telemetry_lock seed=%d: _tactical_mode_snapshot missing telemetry" % scenario_seed)
			else:
				var emb: Dictionary = ts["telemetry"] as Dictionary
				var mode2: String = _EngagementMode.engagement_mode(mgr)
				if str(emb.get("last_resolved_mode", "")) != mode2:
					CombatRegressionHarness._fail(
						failures,
						"telemetry_lock seed=%d: snapshot.telemetry last_resolved_mode mismatch" % scenario_seed
					)
				if (
					not emb.has("invalid_melee_resolve_blocked")
										or not emb.has("invalid_close_resolve_blocked")
				):
					CombatRegressionHarness._fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry missing invalid_* keys" % scenario_seed
					)
				if (
					int(emb.get("invalid_melee_resolve_blocked", -1)) != 0
										or int(emb.get("invalid_close_resolve_blocked", -1)) != 0
				):
					CombatRegressionHarness._fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry expected 0 invalid counters got %s"
						% [scenario_seed, str(emb)]
					)
		CombatRegressionHarness._free_manager(mgr)


## Tier 1.9 (P10) multi-seed: `can_melee_threaten` implies MID/CLOSE band and a listed weapon strike vs that rank-0 enemy.
static func _run_depth_polearm_band_vs_actions_fuzz(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pf: int = rng.randi_range(1, 4)
		var ef: int = rng.randi_range(1, 4)
		var mgr: Node = _MgrScript.new()
		for _i in pf:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
		for _j in pf:
			mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
		for _k in ef:
			mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
		mgr.start(
			{"files": pf, "ranks": 2, "density": "normal"},
			{"files": ef, "ranks": 1, "density": "normal"}
		)
		var fs: int = rng.randi_range(0, pf - 1)
		var depth_idx: int = pf + fs
		if depth_idx >= mgr.combatants.size():
			CombatRegressionHarness._fail(failures, "depth_polearm_band_acts seed=%d: bad depth idx" % scenario_seed)
			CombatRegressionHarness._free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
			CombatRegressionHarness._fail(failures, "depth_polearm_band_acts seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			CombatRegressionHarness._free_manager(mgr)
			continue
		depth["gauge"] = 100.0
		var w_depth: Variant = _EntityAccess.get_weapon(depth)
		var atk_ids: Dictionary = {}
		if w_depth != null and w_depth is Weapon:
			atk_ids = (w_depth as Weapon).attack_types
		for c in mgr.combatants:
			if not _EntityAccess.is_alive_on_side(c, "enemy"):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			if not _DepthPolearm.depth_polearm_valid_line_threat(mgr, depth, c):
				continue
			if not _MeleeListing.can_melee_threaten(mgr, depth, c):
				continue
			var dist: String = _EntityAccess.distance_to_opponent_band(
				depth, _EntityAccess.id_int(c, -2), ""
			)
			if dist == CombatConstants.DISTANCE_LONG:
				CombatRegressionHarness._fail(
					failures,
					"depth_polearm_band_acts seed=%d: threaten true but distance LONG vs id=%s"
					% [scenario_seed, str(_EntityAccess.id_int(c))]
				)
				continue
			if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
				CombatRegressionHarness._fail(
					failures,
					"depth_polearm_band_acts seed=%d: expected CLOSE/MID vs id=%s got %s"
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist]
				)
				continue
			var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
			if not _ListedActions.actions_include_any_move_in_vs_target(
				acts, _EntityAccess.id_int(c), atk_ids
			):
				CombatRegressionHarness._fail(
					failures,
					(
						"depth_polearm_band_acts seed=%d: threaten true but no weapon strike vs id=%s dist=%s acts=%s"
					)
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist, str(acts)]
				)
		CombatRegressionHarness._free_manager(mgr)


static func _run_surround_production_path_dampens_defense_vs_compressed_flanks(failures: PackedStringArray) -> void:
	if not CombatConstants.is_feature_sector_surround_load():
		return
	var def: Dictionary = {"stats": {"perception": 100.0}, "stance": "balanced"}
	var pa: Dictionary = {
		"surround_threat_count": 2,
		"surround_threat_weight_sum": 1.15,
		"tactical_ambush_mult": 1.0,
	}
	var m_prod: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	if m_prod <= m_int + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"surround_prod_defense: sector mult %.6f should exceed integer %.6f (milder) wsum=%.4f"
			% [m_prod, m_int, float(pa["surround_threat_weight_sum"])]
		)
	if not is_equal_approx(m_prod, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, 1.15)):
		CombatRegressionHarness._fail(
			failures,
			"surround_prod_defense: production mult %.6f vs harness ref"
			% m_prod
		)


## Tier 1.9 auto profile: `line_discipline` / `engagement_posture` steer over-shoulder vs open when `spear_lane_profile` is auto (**OPEN** and **DUEL** open lows under tight when not strict-only).
static func _run_telemetry_invalid_melee_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_WindUpStarter.start(mgr, p_id, e_id, "thrust")
	var p: Dictionary = mgr.combatants[0]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	var res: Dictionary = _AttackResolver.resolve_attack(mgr, p_id)
	if str(res.get("action", "")) != "skip":
		CombatRegressionHarness._fail(failures, "telemetry_melee_geom: expected skip when LONG+threaten false got %s" % str(res))
	if float(res.get("recovery_duration", 0.0)) <= 0.0:
		CombatRegressionHarness._fail(failures, "telemetry_melee_geom: expected positive recovery on abort")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		CombatRegressionHarness._fail(failures, "telemetry_melee_geom: missing telemetry meta")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_melee_resolve_blocked", 0)) < 1:
			CombatRegressionHarness._fail(failures, "telemetry_melee_geom: expected invalid_melee_resolve_blocked >= 1 got %s" % str(tel))
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.8: `attempt_close` is not listed when pair band is MID/CLOSE (matches `resolve_close_attempt` LONG-only).
static func _run_telemetry_invalid_close_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		CombatRegressionHarness._fail(failures, "telemetry_close: missing telemetry meta after blocked close")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_close_resolve_blocked", 0)) < 1:
			CombatRegressionHarness._fail(failures, "telemetry_close: expected invalid_close_resolve_blocked >= 1 got %s" % str(tel))
	CombatRegressionHarness._free_manager(mgr)


## Failed pressure-vs-evasion close emits `reason: contest_failed` for UI / tooling (not only generic `close_failed`).
static func _run_attempt_close_listed_only_at_long(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
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
	var acts_mid: Array = _ActionsBuilder.build(mgr, p_id)
	if _ListedActions.actions_include_move_vs_target(
		acts_mid, e_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
	):
		CombatRegressionHarness._fail(
			failures,
			"attempt_close_list: must not list close vs MID opponent (target %d)" % e_id
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var acts_long: Array = _ActionsBuilder.build(mgr, p_id)
	if not _ListedActions.actions_include_move_vs_target(
		acts_long, e_id, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
	):
		CombatRegressionHarness._fail(failures, "attempt_close_list: expected attempt_close vs LONG opponent")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.8: `CombatAIActionPicker` must not weight stale `attempt_close` at MID/CLOSE (defense in depth vs listing).
static func _run_attempt_close_ai_weight_zero_when_not_long(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
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
	if _AIPicker._get_action_weight(a_close, p_id, mgr, true) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"attempt_close_weight: MID band should zero weight got %.6f"
			% _AIPicker._get_action_weight(a_close, p_id, mgr, true)
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var w_long: float = _AIPicker._get_action_weight(a_close, p_id, mgr, true)
	if w_long <= 0.001:
		CombatRegressionHarness._fail(failures, "attempt_close_weight: LONG band should allow positive weight got %.6f" % w_long)
	CombatRegressionHarness._free_manager(mgr)


## III-4 **3e**: utility pick dampens focus-line weight during mop-up.
static func _run_envelop_focus_ai_weight_damp_mop_up(failures: PackedStringArray) -> void:
	var mgr_mop: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr_mop, "player", 0, 3)
	if player.is_empty():
		CombatRegressionHarness._fail(failures, "focus_weight_mop_up: missing player fixture")
		CombatRegressionHarness._free_manager(mgr_mop)
		return
	player["guard_line"] = "low"
	player.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	var p_id: int = _EntityAccess.id_int(player)
	var a_focus: Dictionary = {
		"target_id": p_id,
		"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH,
	}
	var w_mop: float = _AIPicker._get_action_weight(a_focus, p_id, mgr_mop, true)
	var mgr_open: Node = _MgrScript.new()
	for _i in 7:
		mgr_open.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr_open.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_open.start({"files": 7, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var open_player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(
		mgr_open, "player", 0, 3
	)
	open_player["guard_line"] = "low"
	open_player.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	var open_id: int = _EntityAccess.id_int(open_player)
	var w_open: float = _AIPicker._get_action_weight(a_focus, open_id, mgr_open, true)
	if w_mop >= w_open * 0.99:
		CombatRegressionHarness._fail(
			failures,
			"focus_weight_mop_up: want damped weight got mop=%.6f open=%.6f" % [w_mop, w_open]
		)
	CombatRegressionHarness._free_manager(mgr_mop)
	CombatRegressionHarness._free_manager(mgr_open)


## III-4 **3e**: utility pick — mop-up boosts **`attempt_close`** at LONG only; MID/CLOSE finish with strikes.
static func _run_attempt_close_ai_weight_mid_mop_up(failures: PackedStringArray) -> void:
	var mgr: Node = _harness_7v3_mop_up_mgr()
	var player: Dictionary = CombatRegressionHarness._harness_find_living_at_rank_file(mgr, "player", 0, 3)
	var enemy: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_living_on_side(c, "enemy"):
			enemy = c
			break
	if player.is_empty() or enemy.is_empty():
		CombatRegressionHarness._fail(failures, "attempt_close_weight_mop_up: missing fixtures")
		CombatRegressionHarness._free_manager(mgr)
		return
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
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
	var w_mid: float = _AIPicker._get_action_weight(a_close, p_id, mgr, true)
	if w_mid > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"attempt_close_weight_mop_up: MID during mop-up want zero weight (strike finish) got %.6f"
			% w_mid
		)
	(player["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(enemy["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var w_long: float = _AIPicker._get_action_weight(a_close, p_id, mgr, true)
	if w_long <= 0.001:
		CombatRegressionHarness._fail(
			failures,
			"attempt_close_weight_mop_up: LONG during mop-up want positive weight got %.6f" % w_long
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.8: `resolve_close_attempt` when pair band is not LONG (stale vs `attempt_close` listing) increments telemetry.
static func _run_close_contest_failed_emits_reason(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var sd: Dictionary = _EntityAccess.stats_dict_for_mutation(p)
	sd["strength"] = 0.0
	var cap: Array = []
	mgr.action_resolved.connect(
		func(_aid: int, _tid: int, result: Dictionary) -> void:
			cap.clear()
			cap.append(result)
	)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if cap.is_empty():
		CombatRegressionHarness._fail(failures, "close_contest: expected action_resolved payload")
		CombatRegressionHarness._free_manager(mgr)
		return
	var r: Dictionary = cap[0] as Dictionary
	if str(r.get("outcome", "")) != "close_failed":
		CombatRegressionHarness._fail(failures, "close_contest: expected close_failed got %s" % str(r))
	elif str(r.get("reason", "")) != "contest_failed":
		CombatRegressionHarness._fail(failures, "close_contest: expected reason contest_failed got %s" % str(r.get("reason", "")))
	var line: String = _CombatLogFormatter.format_action_line(
		"P", "player", "E", "enemy", r
	)
	if not line.contains("measure"):
		CombatRegressionHarness._fail(failures, "close_contest: formatter should mention defender measure got %s" % line)
	CombatRegressionHarness._free_manager(mgr)


## `resolve_close_attempt` must not run the contest vs an incapacitated defender (stale UI / AI only).
static func _run_resolve_close_no_emit_when_target_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ent_enemy := CombatRegressionHarness._new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(en):
		CombatRegressionHarness._fail(failures, "close_skip_incap: enemy should be incap for test")
		CombatRegressionHarness._free_manager(mgr)
		return
	var p: Dictionary = mgr.combatants[0]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(failures, "close_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0]))
	CombatRegressionHarness._free_manager(mgr)


static func _run_parry_deflect_formatter_clash_context_branches(failures: PackedStringArray) -> void:
	var base_r: Dictionary = {
		"outcome": "parry_deflect",
		"dmg": 0,
		"died": false,
		"part": "",
		"health_before": -1,
		"health_after": -1
	}
	var line0: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_r)
	if line0.contains("meas=") or line0.contains("[size=10]"):
		CombatRegressionHarness._fail(failures, "parry_fmt: baseline should not include clash suffix got %s" % line0)
	var with_ctx: Dictionary = base_r.duplicate(true)
	with_ctx["parry_clash_context"] = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.2,
		"parry_control": 0.75
	}
	var line_ctx: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_ctx)
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		if not line_ctx.contains("thrust") or not line_ctx.contains("meas=") or not line_ctx.contains("bind="):
			CombatRegressionHarness._fail(
				failures,
				"parry_fmt: calibration on expected thrust/meas/bind in %s" % line_ctx
			)
	else:
		if line_ctx != line0:
			CombatRegressionHarness._fail(
				failures,
				"parry_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_ctx, line0]
			)
	var empty_ctx: Dictionary = base_r.duplicate(true)
	empty_ctx["parry_clash_context"] = {}
	var line_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_ctx)
	if line_empty != line0:
		CombatRegressionHarness._fail(
			failures,
			"parry_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_empty, line0]
		)


## `CombatLogFormatter` — **`parry_partial`**: non-empty **`parry_clash_context`** unchanged unless **`COMBAT_DEBUG_CALIBRATION`**; suffix includes **`rem=`** (**`remaining_ratio`**).
static func _run_parry_partial_formatter_clash_context_branches(failures: PackedStringArray) -> void:
	var base_pp: Dictionary = {
		"outcome": "parry_partial",
		"dmg": 0,
		"died": false,
		"part": "",
		"health_before": -1,
		"health_after": -1
	}
	var line_pp0: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_pp)
	if line_pp0.contains("meas=") or line_pp0.contains("[size=10]"):
		CombatRegressionHarness._fail(failures, "parry_partial_fmt: baseline should not include clash suffix got %s" % line_pp0)
	if not line_pp0.contains("partially parried"):
		CombatRegressionHarness._fail(failures, "parry_partial_fmt: baseline should say partially parried got %s" % line_pp0)
	var with_pp: Dictionary = base_pp.duplicate(true)
	with_pp["parry_clash_context"] = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.2,
		"parry_control": 0.75,
		"remaining_ratio": 0.11
	}
	var line_pp_ctx: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_pp)
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		if (
			not line_pp_ctx.contains("thrust")
			or not line_pp_ctx.contains("meas=")
			or not line_pp_ctx.contains("bind=")
			or not line_pp_ctx.contains("rem=")
		):
			CombatRegressionHarness._fail(
				failures,
				"parry_partial_fmt: calibration on expected thrust/meas/bind/rem in %s" % line_pp_ctx
			)
	else:
		if line_pp_ctx != line_pp0:
			CombatRegressionHarness._fail(
				failures,
				"parry_partial_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_pp_ctx, line_pp0]
			)
	var empty_pp: Dictionary = base_pp.duplicate(true)
	empty_pp["parry_clash_context"] = {}
	var line_pp_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_pp)
	if line_pp_empty != line_pp0:
		CombatRegressionHarness._fail(
			failures,
			"parry_partial_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_pp_empty, line_pp0]
		)


static func _run_telemetry_automatic_doctrine_pinch_record(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	_TacticalCombat.record_automatic_doctrine_pinch(mgr, "enemy")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		CombatRegressionHarness._fail(failures, "telemetry_auto_doc: missing meta after record")
		CombatRegressionHarness._free_manager(mgr)
		return
	var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
	if int(tel.get("automatic_doctrine_pinch_count", 0)) != 1:
		CombatRegressionHarness._fail(
			failures,
			"telemetry_auto_doc: expected automatic_doctrine_pinch_count 1 got %s" % str(tel.get("automatic_doctrine_pinch_count", -1))
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
	if typeof(lap) != TYPE_DICTIONARY:
		CombatRegressionHarness._fail(failures, "telemetry_auto_doc: last_automatic_doctrine_pinch should be a dict")
		CombatRegressionHarness._free_manager(mgr)
		return
	if str((lap as Dictionary).get("formation_id", "")) != "enemy":
		CombatRegressionHarness._fail(failures, "telemetry_auto_doc: last pinch formation_id mismatch")
	CombatRegressionHarness._free_manager(mgr)


## Snapshot rows carry `formation_doctrine` aligned with `CombatManager.get_formation_doctrine`.
static func _run_combatants_snapshot_formation_doctrine_field(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
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
			CombatRegressionHarness._fail(
				failures,
				"snapshot_doctrine: player row got %s want hold_lane" % str(rd.get("formation_doctrine", ""))
			)
		if str(rd.get("zone_geometry_fid", "")) != "player":
			CombatRegressionHarness._fail(
				failures,
				"snapshot zone_geometry_fid: player row got %s want player"
				% str(rd.get("zone_geometry_fid", ""))
			)
		break
	if not ok_player:
		CombatRegressionHarness._fail(failures, "snapshot_doctrine: no player row in get_combatants")
	CombatRegressionHarness._free_manager(mgr)


static func _run_parry_pack_flank_effective_spacing(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE] = true
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[0]["file"] = 0
	mgr.combatants[1]["file"] = 1
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var e_adj: Dictionary = mgr.combatants[1]
	var eff_adj: float = _PairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e_adj)
	if eff_adj + 1e-4 >= float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		CombatRegressionHarness._fail(
			failures,
			"parry_pack_flank: adjacent files expected eff spacing < PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_adj
		)
	var m_adj: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if is_equal_approx(m_adj, CombatConstants.FLANK_PARRY_MOD):
		CombatRegressionHarness._fail(failures, "parry_pack_flank: adjacent files should not apply flank mod (got %.4f)" % m_adj)
	mgr.combatants[1]["file"] = 2
	mgr._recompute_zoc_and_distance()
	var e_far: Dictionary = mgr.combatants[1]
	var eff_far: float = _PairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e_far)
	if eff_far + 1e-4 < float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		CombatRegressionHarness._fail(
			failures,
			"parry_pack_flank: |Δfile|==2 expected eff spacing >= PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_far
		)
	var m_far: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if not is_equal_approx(m_far, CombatConstants.FLANK_PARRY_MOD):
		CombatRegressionHarness._fail(
			failures,
			"parry_pack_flank: |Δfile|==2 with protection circle should apply flank mod (got %.4f want %.4f)"
			% [m_far, CombatConstants.FLANK_PARRY_MOD]
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_surround_sector_load_formula(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var m_int_two_threats: float = _TacticalCombat.surround_defense_multiplier(d, 2)
	var m_sector: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)
	if not is_equal_approx(m_int_two_threats, m_sector):
		CombatRegressionHarness._fail(
			failures,
			"surround_sector: int n=2 %.4f vs sector wsum=2 %.4f" % [m_int_two_threats, m_sector]
		)
	var m_mild: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 1.15)
	if m_mild <= m_int_two_threats + 0.01:
		CombatRegressionHarness._fail(
			failures,
			"surround_sector: compressed wsum=1.15 should be milder than int n=2 (%.4f vs %.4f)" % [m_mild, m_int_two_threats]
		)


## Tier 3.1: two adjacent-file enemies vs center defender — summed sector weight stays below two full flank weights.
static func _run_surround_threat_weight_sum_three_file_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def_id: int = _EntityAccess.id_int(mgr.combatants[0])
	if _TacticalCombat.count_engaging_threats(mgr, def_id) != 2:
		CombatRegressionHarness._fail(failures, "surround_weight_sum: expected two engaging threats")
		CombatRegressionHarness._free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02:
		CombatRegressionHarness._fail(failures, "surround_weight_sum: adjacent pair should sum < 2 full weights, got %.4f" % wsum)
	if wsum < 0.9:
		CombatRegressionHarness._fail(failures, "surround_weight_sum: expected meaningful stacked weight, got %.4f" % wsum)
	CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: **`surround_defense_multiplier_from_pa_with_sector`** — integer **`surround_threat_count`** vs sector **`surround_threat_weight_sum`** (explicit flag; production uses **`is_feature_sector_surround_load`**).
static func _run_surround_defense_multiplier_from_pa_both_paths(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var pa_two: Dictionary = {"surround_threat_count": 2}
	var m_int_path: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, false)
	var m_sector_equiv: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, true)
	if not is_equal_approx(m_int_path, _TacticalCombat.surround_defense_multiplier(d, 2)):
		CombatRegressionHarness._fail(failures, "surround_from_pa: int path should match surround_defense_multiplier(n=2)")
	if not is_equal_approx(m_sector_equiv, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)):
		CombatRegressionHarness._fail(failures, "surround_from_pa: sector path with count-only pa should match wsum=2")
	if not is_equal_approx(m_int_path, m_sector_equiv):
		CombatRegressionHarness._fail(
			failures,
			"surround_from_pa: n=2 int vs sector(count fallback) %.6f vs %.6f" % [m_int_path, m_sector_equiv]
		)
	var pa_mixed: Dictionary = {"surround_threat_count": 2, "surround_threat_weight_sum": 1.15}
	var m_split_two: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, false)
	var m_sector_mild: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, true)
	if not is_equal_approx(m_split_two, m_int_path):
		CombatRegressionHarness._fail(failures, "surround_from_pa: mixed pa int path should still use count=2")
	if m_sector_mild <= m_split_two + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"surround_from_pa: sector wsum=1.15 should beat int n=2 split (%.6f vs %.6f)" % [m_sector_mild, m_split_two]
		)


## Tier 3.1: live **`compute_surround_threat_weight_sum`** matches **`surround_defense_multiplier_from_pa_with_sector(..., true)`** with **`pa`** shaped like **`AttackResolver`** (count + weight sum).
static func _run_surround_live_weight_sum_matches_from_pa_sector_path(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	if n_threats != 2:
		CombatRegressionHarness._fail(failures, "surround_live_pa: expected two engaging threats got %d" % n_threats)
		CombatRegressionHarness._free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02 or wsum < 0.9:
		CombatRegressionHarness._fail(failures, "surround_live_pa: unexpected wsum=%.4f (want compressed flank pair)" % wsum)
		CombatRegressionHarness._free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_sector: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	var m_ref: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)
	if not is_equal_approx(m_sector, m_ref):
		CombatRegressionHarness._fail(
			failures,
			"surround_live_pa: sector from_pa %.6f vs harness wsum ref %.6f" % [m_sector, m_ref]
		)
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_int_ref: float = _TacticalCombat.surround_defense_multiplier(def, n_threats)
	if not is_equal_approx(m_int, m_int_ref):
		CombatRegressionHarness._fail(
			failures,
			"surround_live_pa: int from_pa %.6f vs surround_defense_multiplier %.6f" % [m_int, m_int_ref]
		)
	if m_sector <= m_int + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"surround_live_pa: sector path should be milder than int n=2 (%.6f vs %.6f) wsum=%.4f"
			% [m_sector, m_int, wsum]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: one engaging threat — integer **n≤1** and sector **`wsum`≤`SURROUND_SECTOR_LOAD_FREE`** both stay neutral (**1.0**).
static func _run_surround_single_threat_int_and_sector_neutral(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	if n_threats != 1:
		CombatRegressionHarness._fail(failures, "surround_single: expected one engaging threat got %d" % n_threats)
		CombatRegressionHarness._free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + 0.02:
		CombatRegressionHarness._fail(
			failures,
			"surround_single: wsum=%.4f should sit in free tier (≤%.3f)" % [wsum, CombatConstants.SURROUND_SECTOR_LOAD_FREE]
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	if not is_equal_approx(m_int, 1.0):
		CombatRegressionHarness._fail(failures, "surround_single: int path want 1.0 got %.6f" % m_int)
	if not is_equal_approx(m_sec, 1.0):
		CombatRegressionHarness._fail(failures, "surround_single: sector path want 1.0 got %.6f (wsum=%.4f)" % [m_sec, wsum])
	if not is_equal_approx(m_sec, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)):
		CombatRegressionHarness._fail(failures, "surround_single: sector from_pa vs harness ref mismatch")
	CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: **`is_feature_sector_surround_load`** — `surround_defense_multiplier_from_pa` follows runtime toggle (int path off, sector path on).
static func _run_sector_surround_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
	var prev_flag: bool = CombatConstants.is_feature_sector_surround_load()
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	if n_threats != 2 or wsum >= 2.0 - 0.02 or wsum < 0.9:
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		CombatRegressionHarness._free_manager(mgr)
		CombatRegressionHarness._fail(failures, "sector_flag_toggle: need compressed two-threat layout (n=%d wsum=%.4f)" % [n_threats, wsum])
		return
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	CombatConstants.set_feature_sector_surround_load(false)
	var from_pa_off: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_off, m_int):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		CombatRegressionHarness._free_manager(mgr)
		CombatRegressionHarness._fail(
			failures,
			"sector_flag_toggle: flag off from_pa %.6f vs int ref %.6f" % [from_pa_off, m_int]
		)
		return
	CombatConstants.set_feature_sector_surround_load(true)
	var from_pa_on: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_on, m_sec):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		CombatRegressionHarness._free_manager(mgr)
		CombatRegressionHarness._fail(
			failures,
			"sector_flag_toggle: flag on from_pa %.6f vs sector ref %.6f" % [from_pa_on, m_sec]
		)
		return
	if from_pa_on <= from_pa_off + 0.001:
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		CombatRegressionHarness._free_manager(mgr)
		CombatRegressionHarness._fail(
			failures,
			"sector_flag_toggle: sector-on %.6f should exceed int-off %.6f (milder surround)" % [from_pa_on, from_pa_off]
		)
		return
	CombatConstants.set_feature_sector_surround_load(prev_flag)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `posture_cohesion_targeting_mult` rises with line cohesion in LINE posture; OPEN uses inverse (looser line → higher mult).
static func _run_ai_targeting_posture_cohesion_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var fd: Dictionary = _FormationSlots.formation_record_for_manager(mgr, pfid)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	fd["line_cohesion"] = 0.0
	var m_line_lo: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 1.0
	var m_line_hi: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_line_hi < m_line_lo + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_posture: LINE mult should increase with cohesion (lo=%.4f hi=%.4f)" % [m_line_lo, m_line_hi]
		)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	fd["line_cohesion"] = 1.0
	var m_open_tight: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 0.0
	var m_open_loose: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_open_loose < m_open_tight + 0.001:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_posture: OPEN mult should increase when cohesion drops (tight=%.4f loose=%.4f)"
			% [m_open_tight, m_open_loose]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`distributed_pressure_mult`** — ally doctrine commit to the same defender lowers **`hostile_pair_targeting_weight_mult`** for a second attacker (cached engagement-mode mult so snapshot stays stable).
static func _run_hostile_pair_distributed_pressure_ally_commit(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr.combat_clock = 10.0
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var e0: Dictionary = mgr.combatants[2]
	if not _EntityAccess.is_player_side(p0) or not _EntityAccess.is_player_side(p1):
		CombatRegressionHarness._fail(failures, "dist_pressure: expected first two combatants on player side")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _EntityAccess.is_enemy_side(e0):
		CombatRegressionHarness._fail(failures, "dist_pressure: expected third combatant enemy")
		CombatRegressionHarness._free_manager(mgr)
		return
	p0["doctrine_target_commit_id"] = -1
	p1["doctrine_target_commit_id"] = -1
	var p0id: int = _EntityAccess.id_int(p0)
	var p1id: int = _EntityAccess.id_int(p1)
	var e0id: int = _EntityAccess.id_int(e0)
	var m_mode: float = _TargetScoring.engagement_mode_targeting_mult(mgr)
	var dp_none: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	var w_before: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
	_TargetScoring.on_combat_commitment(mgr, p1id, e0id)
	var dp_ally: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	var w_after: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
	if dp_ally >= dp_none - 1e-6:
		CombatRegressionHarness._fail(
			failures,
			"dist_pressure: distributed mult should drop when ally commits none=%.6f ally=%.6f" % [dp_none, dp_ally]
		)
	if w_after >= w_before - 1e-6:
		CombatRegressionHarness._fail(
			failures,
			"dist_pressure: hostile weight should drop before=%.6f after=%.6f" % [w_before, w_after]
		)
	var cnt: int = _TargetScoring.ally_pressure_count(mgr, e0id, "player", p0id)
	if cnt != 1:
		CombatRegressionHarness._fail(failures, "dist_pressure: expected ally_pressure_count=1 got %d" % cnt)
	p1["doctrine_target_commit_id"] = -1
	p1.erase("doctrine_commit_until")
	var dp_restored: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	if not is_equal_approx(dp_restored, dp_none):
		CombatRegressionHarness._fail(
			failures,
			"dist_pressure: clearing commit should restore pressure mult restored=%.6f none=%.6f"
			% [dp_restored, dp_none]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / 1.9: **`CombatTargetScoring.ally_pressure_count`** — committed rank>0 allies count only when **`CombatMeleeRankTargeting.melee_pair_rank_allowed`** to the committed defender (**`depth_polearm_valid_line_threat`** for home depth vs rank-0).
static func _run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures: PackedStringArray) -> void:
	var mgr_near: Node = _MgrScript.new()
	mgr_near.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_near.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr_near.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_near.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr_near.combatants:
		c["gauge"] = 100.0
	mgr_near.combat_clock = 10.0
	mgr_near._recompute_zoc_and_distance()
	var p0n: Dictionary = mgr_near.combatants[0]
	var p1n: Dictionary = mgr_near.combatants[1]
	var e0n: Dictionary = mgr_near.combatants[2]
	var p0nid: int = _EntityAccess.id_int(p0n)
	var p1nid: int = _EntityAccess.id_int(p1n)
	var e0nid: int = _EntityAccess.id_int(e0n)
	if not _MeleeRank.melee_pair_rank_allowed(mgr_near, p1n, e0n):
		CombatRegressionHarness._fail(failures, "ally_press_dep: near layout expected _melee_pair_rank_allowed depth→e0")
		CombatRegressionHarness._free_manager(mgr_near)
		return
	_TargetScoring.on_combat_commitment(mgr_near, p1nid, e0nid)
	var cnt_near: int = _TargetScoring.ally_pressure_count(mgr_near, e0nid, "player", p0nid)
	if cnt_near != 1:
		CombatRegressionHarness._fail(failures, "ally_press_dep: near expected ally_pressure_count=1 got %d" % cnt_near)
	p1n["doctrine_target_commit_id"] = -1
	CombatRegressionHarness._free_manager(mgr_near)

	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_far.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c2 in mgr_far.combatants:
		c2["gauge"] = 100.0
	mgr_far.combat_clock = 10.0
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr_far, depth_far):
		CombatRegressionHarness._fail(failures, "ally_press_dep: far layout expected open depth lane")
		CombatRegressionHarness._free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	var e0_far: Dictionary = mgr_far.combatants[2]
	if _MeleeRank.melee_pair_rank_allowed(mgr_far, depth_far, e0_far):
		CombatRegressionHarness._fail(failures, "ally_press_dep: far enemies expected no _melee_pair_rank_allowed depth→e0")
		CombatRegressionHarness._free_manager(mgr_far)
		return
	var p0f: Dictionary = mgr_far.combatants[0]
	var p0fid: int = _EntityAccess.id_int(p0f)
	var e0fid: int = _EntityAccess.id_int(e0_far)
	var p1fid: int = _EntityAccess.id_int(depth_far)
	_TargetScoring.on_combat_commitment(mgr_far, p1fid, e0fid)
	var cnt_far: int = _TargetScoring.ally_pressure_count(mgr_far, e0fid, "player", p0fid)
	if cnt_far != 0:
		CombatRegressionHarness._fail(
			failures,
			"ally_press_dep: far-line committed depth should not count pressure got %d" % cnt_far
		)
	CombatRegressionHarness._free_manager(mgr_far)


## Tier 1.6: **`CombatTargetScoring.hold_lane_mult`** — **`hold_lane`** doctrine hedges listed weights vs **non**-file-opposed rank-0 pairs; file-opposed front returns **1.0**.
static func _run_targeting_hold_lane_off_file_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_off: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_off, CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT):
		CombatRegressionHarness._fail(
			failures,
			"hold_lane_mult: off-file expected %.4f got %.4f" % [CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT, m_off]
		)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_same: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_same, 1.0):
		CombatRegressionHarness._fail(failures, "hold_lane_mult: file-opposed front should be neutral got %.4f" % m_same)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var m_pinch: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, 1.0):
		CombatRegressionHarness._fail(failures, "hold_lane_mult: pinch doctrine should not apply hold hedge got %.4f" % m_pinch)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.hold_lane_mult(mgr, p, e), 1.0):
		CombatRegressionHarness._fail(failures, "hold_lane_mult: default doctrine should be neutral")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.file_opposed_mult`** — same-file rank-0 pair (or depth polearm using same-file rank-0 ally) applies **`DOCTRINE_FILE_OPPOSED_WEIGHT_MULT`**; off-file → **1.0**.
static func _run_targeting_file_opposed_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	mgr._recompute_zoc_and_distance()
	var m_off: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_off, 1.0):
		CombatRegressionHarness._fail(failures, "file_opposed_mult: off-file rank-0 expected 1.0 got %.4f" % m_off)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_front: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_front, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		CombatRegressionHarness._fail(
			failures,
			"file_opposed_mult: same-file rank-0 expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_front]
		)
	CombatRegressionHarness._free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
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
	mgr2._recompute_zoc_and_distance()
	if not _DepthPolearm.depth_polearm_lane_open(mgr2, depth):
		CombatRegressionHarness._fail(failures, "file_opposed_mult_depth: expected depth spear lane open")
		CombatRegressionHarness._free_manager(mgr2)
		return
	var m_depth_same: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_same)
	if not is_equal_approx(m_depth_same, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		CombatRegressionHarness._fail(
			failures,
			"file_opposed_mult_depth: front ally file-opposed expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_depth_same]
		)
	var m_depth_off: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_off)
	if not is_equal_approx(m_depth_off, 1.0):
		CombatRegressionHarness._fail(failures, "file_opposed_mult_depth: off-file enemy expected 1.0 got %.4f" % m_depth_off)
	CombatRegressionHarness._free_manager(mgr2)


## Tier 1.6: **`CombatTargetScoring.pinch_score_mult`** — **`pinch_center`** + **`wing_lacks_file_opposed`** nudges weight toward enemies nearer the hostile line center ( **`DOCTRINE_PINCH_INWARD_BIAS_PER_FILE`** ).
static func _run_targeting_pinch_center_inward_bonus(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	if not _TargetScoring.wing_lacks_file_opposed(mgr, p):
		CombatRegressionHarness._fail(
			failures,
			"pinch_bonus: expected wing_lacks (no rank-0 mapped opposition; depth-only hostile)"
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var ec: float = 0.0
	for c in mgr.combatants:
		if not _EntityAccess.is_living_on_side(c, "enemy"):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		ec = float(_EntityAccess.file_int(c))
		break
	var inward: float = absf(float(_EntityAccess.file_int(e)) - ec)
	var want: float = 1.0 + CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
	var m_pinch: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, want):
		CombatRegressionHarness._fail(failures, "pinch_bonus: expected %.6f got %.6f (inward=%.4f)" % [want, m_pinch, inward])
	e["rank"] = 0
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_opposed: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_opposed, 1.0):
		CombatRegressionHarness._fail(failures, "pinch_bonus: file-opposed front should suppress pinch got %.4f" % m_opposed)
	e["file"] = 1
	e["rank"] = 1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_hold_doc: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_hold_doc, 1.0):
		CombatRegressionHarness._fail(failures, "pinch_bonus: hold_lane doctrine should not apply pinch inward got %.4f" % m_hold_doc)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.pinch_score_mult(mgr, p, e), 1.0):
		CombatRegressionHarness._fail(failures, "pinch_bonus: default doctrine should be neutral")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.commitment_match_mult`** after **`on_combat_commitment`** ( **`DOCTRINE_COMMIT_MATCH_WEIGHT_MULT`** ).
static func _run_targeting_commitment_match_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	p["doctrine_target_commit_id"] = -1
	var m_neutral: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_neutral, 1.0):
		CombatRegressionHarness._fail(failures, "commit_match: no commit should be 1.0 got %.4f" % m_neutral)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	var m_match: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_match, CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		CombatRegressionHarness._fail(
			failures,
			"commit_match: expected %.4f got %.4f" % [CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT, m_match]
		)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid + 9999), 1.0):
		CombatRegressionHarness._fail(failures, "commit_match: wrong target id should be neutral")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.soft_geometry_score`** = **`1/(1 + effective_pair_eff_dist × DOCTRINE_SOFT_DISTANCE_SCALE)`**; larger eff → lower score (monotone).
static func _run_targeting_soft_geometry_eff_dist_formula(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	if not _EntityAccess.is_player_side(p):
		CombatRegressionHarness._fail(failures, "soft_geom: expected combatants[0] player")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _EntityAccess.is_enemy_side(e0) or not _EntityAccess.is_enemy_side(e1):
		CombatRegressionHarness._fail(failures, "soft_geom: expected combatants[1–2] enemy")
		CombatRegressionHarness._free_manager(mgr)
		return
	p["file"] = 1
	p["rank"] = 0
	e0["file"] = 0
	e0["rank"] = 0
	e1["file"] = 2
	e1["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var eff0: float = _PairGeometry.effective_pair_eff_dist(mgr, p, e0)
	var eff1: float = _PairGeometry.effective_pair_eff_dist(mgr, p, e1)
	var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
	var s0: float = _TargetScoring.soft_geometry_score(mgr, p, e0)
	var s1: float = _TargetScoring.soft_geometry_score(mgr, p, e1)
	var want0: float = 1.0 / (1.0 + eff0 * k)
	var want1: float = 1.0 / (1.0 + eff1 * k)
	if not is_equal_approx(s0, want0):
		CombatRegressionHarness._fail(failures, "soft_geom: pair0 formula want %.6f got %.6f eff=%.4f" % [want0, s0, eff0])
	if not is_equal_approx(s1, want1):
		CombatRegressionHarness._fail(failures, "soft_geom: pair1 formula want %.6f got %.6f eff=%.4f" % [want1, s1, eff1])
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


## Tier 1.6: **`prune_expired_commitments`** clears stale **`doctrine_target_commit_id`** after **`doctrine_commit_until`** vs **`combat_clock`**.
static func _run_targeting_prune_expired_doctrine_commitment(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		CombatRegressionHarness._fail(failures, "prune_commit: expected match mult after on_combat_commitment")
	mgr.combat_clock = float(p.get("doctrine_commit_until", 0.0)) + 0.25
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		CombatRegressionHarness._fail(failures, "prune_commit: expected doctrine_target_commit_id cleared after expiry")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		CombatRegressionHarness._fail(failures, "prune_commit: commitment_match_mult should be neutral after prune")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears doctrine commit when the **committed target** is no longer alive (before clock expiry).
static func _run_targeting_prune_commitment_when_target_dies(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if int(p.get("doctrine_target_commit_id", -2)) != eid:
		CombatRegressionHarness._fail(failures, "prune_dead_tgt: expected live commit before kill")
	e["alive"] = false
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		CombatRegressionHarness._fail(failures, "prune_dead_tgt: expected commit cleared when target dies")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		CombatRegressionHarness._fail(failures, "prune_dead_tgt: commitment_match_mult should be neutral after dead-target prune")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`clear_all_targeting_state_for_dead_defender`** (death hook) clears **all** allies’ doctrine commits and **close_block** rows keyed to the dead defender.
static func _run_targeting_clear_all_state_for_dead_defender(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var e0: Dictionary = mgr.combatants[2]
	var pid0: int = _EntityAccess.id_int(p0)
	var pid1: int = _EntityAccess.id_int(p1)
	var eid: int = _EntityAccess.id_int(e0)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid0, eid)
	_TargetScoring.on_combat_commitment(mgr, pid1, eid)
	if int(p0.get("doctrine_target_commit_id", -2)) != eid or int(p1.get("doctrine_target_commit_id", -2)) != eid:
		CombatRegressionHarness._fail(failures, "clear_dead_def: expected both allies committed to dead target id")
	var blk0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	blk0[eid] = 999.0
	p0["close_block_until_by_target_id"] = blk0
	var blk1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	blk1[eid] = 888.0
	p1["close_block_until_by_target_id"] = blk1
	_TargetScoring.clear_all_targeting_state_for_dead_defender(mgr, eid)
	if int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1:
		CombatRegressionHarness._fail(failures, "clear_dead_def: expected doctrine_target_commit_id cleared for both allies")
	var b0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	var b1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	if b0.has(eid) or b1.has(eid):
		CombatRegressionHarness._fail(failures, "clear_dead_def: expected close_block_until_by_target_id entries for dead id erased")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 breadth: `opponent_formation_targeting_mult` — solid enemy LINE hedges listed weights; ragged LINE presses; OPEN uses fixed nudge.
static func _run_ai_targeting_opponent_formation_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var opp: Dictionary = mgr.combatants[1]
	var efid: String = _EntityAccess.formation_id_str(opp)
	var efd: Dictionary = _FormationSlots.formation_record_for_manager(mgr, efid)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	efd["line_cohesion"] = 1.0
	var m_solid: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	efd["line_cohesion"] = 0.0
	var m_ragged: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if m_solid >= m_ragged - 0.001:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_opp_form: LINE solid should hedge vs ragged (solid=%.4f ragged=%.4f)" % [m_solid, m_ragged]
		)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var m_open: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if not is_equal_approx(m_open, CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT):
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_opp_form: OPEN expected %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT, m_open]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: **`formation_dict_cache`** on **`opponent_formation_targeting_mult`**, **`posture_cohesion_targeting_mult`** matches live **`ZoneOfControl.formation_for_combatant_cached`**.
static func _run_targeting_formation_dict_cache_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var opp: Dictionary = mgr.combatants[1]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var pfd: Dictionary = _FormationSlots.formation_record_for_manager(mgr, pfid)
	pfd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	pfd["line_cohesion"] = 0.42
	var ofid: String = _EntityAccess.formation_id_str(opp)
	var ofd: Dictionary = _FormationSlots.formation_record_for_manager(mgr, ofid)
	ofd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	ofd["line_cohesion"] = 0.61
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var zg_po: Dictionary = _ZoneOfControl.zone_geometry_for_pair(mgr, p, opp)
	var fd_p: Dictionary = _ZoneOfControl.zone_geometry_formation_a_from_pair_pack(zg_po)
	var fd_o: Dictionary = _ZoneOfControl.zone_geometry_formation_b_from_pair_pack(zg_po)
	var m_pc_l: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	var m_pc_c: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p, fd_p)
	if not is_equal_approx(m_pc_l, m_pc_c):
		CombatRegressionHarness._fail(
			failures,
			"tgt_fd_cache: posture_cohesion live %.6f vs cache %.6f" % [m_pc_l, m_pc_c]
		)
	var m_of_l: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	var m_of_c: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp, fd_o)
	if not is_equal_approx(m_of_l, m_of_c):
		CombatRegressionHarness._fail(
			failures,
			"tgt_fd_cache: opponent_formation live %.6f vs cache %.6f" % [m_of_l, m_of_c]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / 1.7: `engagement_mode_targeting_mult` tracks resolved duel / skirmish / formation.
static func _run_ai_targeting_engagement_mode_mult(failures: PackedStringArray) -> void:
	var d: Node = _MgrScript.new()
	d.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	d.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if _EngagementMode.engagement_mode(d) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: expected duel for 1v1 got %s" % _EngagementMode.engagement_mode(d)
		)
	var m_duel: float = _TargetScoring.engagement_mode_targeting_mult(d)
	if not is_equal_approx(m_duel, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT):
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: duel mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT, m_duel]
		)
	CombatRegressionHarness._free_manager(d)
	var s: Node = _MgrScript.new()
	for _i in 3:
		s.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		s.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	s.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(s).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: 3v3 expected raw skirmish got %s"
			% str(_EngagementMode.snapshot(s).get("raw_mode", ""))
		)
	var m_sk: float = _TargetScoring.engagement_mode_targeting_mult(s)
	if not is_equal_approx(m_sk, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT):
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: skirmish mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT, m_sk]
		)
	CombatRegressionHarness._free_manager(s)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 4:
		f.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	if _EngagementMode.engagement_mode(f) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: expected formation for 4v4 line got %s"
			% _EngagementMode.engagement_mode(f)
		)
	var m_form: float = _TargetScoring.engagement_mode_targeting_mult(f)
	if not is_equal_approx(m_form, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT):
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_eng_mode: formation mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT, m_form]
		)
	CombatRegressionHarness._free_manager(f)


## Tier 1.6: **`hostile_pair_targeting_weight_mult`** — passing **`engagement_mode_targeting_mult(manager)`** as **`cached_engagement_mode_targeting_mult`** matches the **null** overload (same snapshot).
static func _run_hostile_pair_cached_engagement_mode_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var w_live: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e)
	var em: float = _TargetScoring.engagement_mode_targeting_mult(mgr)
	var w_cached: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em)
	if not is_equal_approx(w_live, w_cached):
		CombatRegressionHarness._fail(
			failures,
			"hostile_pair_em_cache: live %.8f vs cached-arg %.8f (em=%.8f)" % [w_live, w_cached, em]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 3.1: depth spear lane parry mults in `DefenseChoiceResolver` (tight → `parry_c_d`; open + stab → `parry_p_a`).
static func _run_ai_targeting_stance_mult_ordering(failures: PackedStringArray) -> void:
	var m_def: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_DEFENSIVE})
	var m_bal: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_BALANCED})
	var m_agg: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_AGGRESSIVE})
	if not (m_def < m_bal + 0.001 and m_bal < m_agg + 0.001):
		CombatRegressionHarness._fail(
			failures,
			"ai_targeting_stance: expected def<bal<agg got %.4f %.4f %.4f" % [m_def, m_bal, m_agg]
		)


## Tier 1.6: `hostile_pair_targeting_weight_mult` × **`AI_TARGETING_INCAP_HOSTILE_MULT`** vs incapacitated opponent (`CoreEntity` consciousness below threshold; dirty flag off so value sticks).
## Rank-0 pair must **not** be file-opposed (equal-width off-file slots; mapped offset 0) — incap mult is isolated from file-opposed hedge.
static func _run_ai_targeting_incap_hostile_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	mgr._recompute_zoc_and_distance()
	if _TargetScoring.is_file_opposed_rank0_pair(mgr, p, opp):
		CombatRegressionHarness._fail(failures, "ai_incap: setup want off-file pair (not mapped-opposed)")
	var w_up: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
	if w_up <= 0.0:
		CombatRegressionHarness._fail(failures, "ai_incap: baseline hostile weight should be > 0")
		CombatRegressionHarness._free_manager(mgr)
		return
	ent_enemy.consciousness = 5.0
	var w_down: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
	var raw_down: float = w_up * CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT
	var expected_w: float = clampf(
		raw_down,
		CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN,
		CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX
	)
	if not is_equal_approx(w_down, expected_w):
		CombatRegressionHarness._fail(
			failures,
			"ai_incap: expected down=%.6f ≈ clamp(up*mult)=%.6f (up=%.6f raw=%.6f mult=%.4f)"
			% [w_down, expected_w, w_up, raw_down, CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT]
		)
	if not _EntityAccess.is_incapacitated(opp):
		CombatRegressionHarness._fail(failures, "ai_incap: test setup failed — opponent should read as incapacitated")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `AvailableActionsBuilder` does not list melee / `attempt_close` vs incapacitated enemies.
static func _run_no_hostile_actions_listed_vs_incap_enemy(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ent_enemy = CombatRegressionHarness._new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(e):
		CombatRegressionHarness._fail(failures, "incap_acts: enemy should be incapacitated for test")
		CombatRegressionHarness._free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	var acts: Array = mgr.get_available_actions(pid)
	if _ListedActions.actions_any_vs_target(acts, eid):
		var bad: Dictionary = _ListedActions.first_action_vs_target(acts, eid)
		CombatRegressionHarness._fail(
			failures,
			"incap_acts: unexpected action vs incap enemy move_id=%s full=%s"
			% [_ListedActions.entry_move_id(bad), str(bad)]
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6 / stalemate: all rank-0 enemies incap → `any_enemy_rank0` false → rank-1 pass may list vs deeper hostiles (no soft-lock).
static func _run_stalemate_melee_rank1_when_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ent_e0 = CombatRegressionHarness._new_entity("SWORD")
	ent_e0.consciousness = 5.0
	mgr.register(ent_e0, "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
			p = c
			break
	if p.is_empty():
		CombatRegressionHarness._fail(failures, "stalemate_incap: no player combatant after start")
		CombatRegressionHarness._free_manager(mgr)
		return
	var e0: Dictionary = {}
	var e1: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_enemy_side(c):
			continue
		var rr: int = _EntityAccess.rank_int(c)
		if rr == 0:
			e0 = c
		elif rr == 1:
			e1 = c
	if e0.is_empty() or e1.is_empty():
		CombatRegressionHarness._fail(failures, "stalemate_incap: missing enemy rank0 or rank1 after start")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _EntityAccess.is_incapacitated(e0) or _EntityAccess.is_incapacitated(e1):
		CombatRegressionHarness._fail(failures, "stalemate_incap: e0 should be incap, e1 upright")
		CombatRegressionHarness._free_manager(mgr)
		return
	var any_r0: bool = false
	for oc in mgr.combatants:
		if _EntityAccess.is_player_side(oc):
			continue
		if _EntityAccess.rank_int(oc) != 0:
			continue
		if _MeleeRank.opp_matches_melee_rank_target(mgr, p, oc, 0):
			any_r0 = true
			break
	if any_r0:
		CombatRegressionHarness._fail(failures, "stalemate_incap: expected no _opp_matches rank0 after incap")
		CombatRegressionHarness._free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var e0id: int = _EntityAccess.id_int(e0)
	var e1id: int = _EntityAccess.id_int(e1)
	var acts: Array = mgr.get_available_actions(pid)
	if _ListedActions.actions_any_vs_target(acts, e0id):
		CombatRegressionHarness._fail(
			failures,
			"stalemate_incap: should not list actions vs incap rank0 got %s"
			% str(_ListedActions.first_action_vs_target(acts, e0id))
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _ListedActions.actions_any_vs_target(acts, e1id):
		CombatRegressionHarness._fail(failures, "stalemate_incap: expected at least one action vs rank1 enemy acts=%s" % str(acts))
	CombatRegressionHarness._free_manager(mgr)


## Tier 3.2: weapon part mass fractions must cover the whole weapon; parry contact uses the intended part.
static func _run_ordered_melee_opponents_file_opposed_sort(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e_same: Dictionary = {}
	var e_off: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
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
	mgr._recompute_zoc_and_distance()
	var ordered: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
	if ordered.size() < 2:
		CombatRegressionHarness._fail(failures, "melee_order_fo: need >=2 rank0 opponents got %d" % ordered.size())
		CombatRegressionHarness._free_manager(mgr)
		return
	var want_id: int = _EntityAccess.id_int(e_same, -998)
	if _EntityAccess.id_int(ordered[0], -999) != want_id:
		var w_same: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_same)
		var w_off: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_off)
		var id_list: Array = []
		for x in ordered:
			id_list.append(_EntityAccess.id_int(x, -1))
		CombatRegressionHarness._fail(
			failures,
			"melee_order_fo: file-opposed enemy id=%d should sort first got order=%s w_same=%.4f w_off=%.4f"
			% [want_id, str(id_list), w_same, w_off]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: `ordered_melee_opponents` tiebreak uses full hostile weight (committed doctrine target first when file-opposed ties).
static func _run_ordered_melee_opponents_commitment_tiebreak(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e1: Dictionary = {}
	var e2: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
			p = c
		elif e1.is_empty():
			e1 = c
		else:
			e2 = c
	p["file"] = 1
	e1["file"] = 0
	e2["file"] = 2
	mgr._recompute_zoc_and_distance()
	var pid: int = _EntityAccess.id_int(p)
	var e1id: int = _EntityAccess.id_int(e1)
	_TargetScoring.on_combat_commitment(mgr, pid, e1id)
	var ordered: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
	if ordered.is_empty():
		CombatRegressionHarness._fail(failures, "melee_order_commit: ordered list empty")
	else:
		var first_id: int = _EntityAccess.id_int(ordered[0], -999)
		if first_id != e1id:
			var id_list: Array = []
			for x in ordered:
				id_list.append(_EntityAccess.id_int(x, -1))
			CombatRegressionHarness._fail(
				failures,
				"melee_order_commit: expected committed opponent first got first_id=%d want e1=%d order=%s"
				% [first_id, e1id, str(id_list)]
			)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: cached **`zone_geometry_line_context`** on **`ordered_melee_opponents`** matches a fresh resolve (listing sort stability).
static func _run_ordered_melee_opponents_actor_zone_cache_parity(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e0: Dictionary = {}
	var e1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
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
	mgr._recompute_zoc_and_distance()
	var fresh: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
	var ctx: Dictionary = _ZoneOfControl.zone_geometry_line_context(mgr, p)
	var cached: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0, ctx)
	var ids_fresh: Array = []
	var ids_cached: Array = []
	for x in fresh:
		ids_fresh.append(_EntityAccess.id_int(x))
	for x in cached:
		ids_cached.append(_EntityAccess.id_int(x))
	CombatRegressionHarness._free_manager(mgr)
	if ids_fresh != ids_cached:
		CombatRegressionHarness._fail(
			failures,
			"melee_order_ctx: fresh %s != cached %s" % [str(ids_fresh), str(ids_cached)]
		)


## **`AvailableActionsBuilder.build`** is deterministic across back-to-back calls on the same combat state.
static func _run_available_actions_build_double_invoke_parity(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 2, "density": "tight"})
	var p: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
			p = c
			break
	p["file"] = 1
	p["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var pid: int = _EntityAccess.id_int(p)
	var sig_a: String = _ListedActions.compact_signature(_ActionsBuilder.build(mgr, pid))
	var sig_b: String = _ListedActions.compact_signature(_ActionsBuilder.build(mgr, pid))
	CombatRegressionHarness._free_manager(mgr)
	if sig_a != sig_b:
		CombatRegressionHarness._fail(
			failures,
			"actions_build_parity: first=%s second=%s" % [sig_a, sig_b]
		)


## Tier 1.6: cached opponent **`zone_geometry_line_context`** matches pair-resolve weight on **`hostile_pair_targeting_weight_mult`**.
static func _run_hostile_pair_opp_zone_cache_parity(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "tight"})
	var p: Dictionary = {}
	var e: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c):
			p = c
		else:
			e = c
	p["file"] = 1
	p["rank"] = 0
	e["file"] = 1
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var em: float = _TargetScoring.engagement_mode_targeting_mult(mgr)
	var ctx_p: Dictionary = _ZoneOfControl.zone_geometry_line_context(mgr, p)
	var zone_by_id: Dictionary = _ZoneOfControl.zone_geometry_line_context_by_combatant_id(mgr)
	var eid: int = _EntityAccess.id_int(e)
	var ctx_e: Dictionary = zone_by_id.get(eid, {}) as Dictionary
	var w_pair: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em, ctx_p)
	var w_cached: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em, ctx_p, ctx_e)
	CombatRegressionHarness._free_manager(mgr)
	if not is_equal_approx(w_pair, w_cached):
		CombatRegressionHarness._fail(
			failures,
			"hostile_pair_opp_ctx: pair=%.6f cached=%.6f" % [w_pair, w_cached]
		)


## Tier 4.2: **`AttackWindUpStarter.start`** with **`feint_part`** / **`target_part`** options stamps **`pending_attack`** (incl. **`feint_target_reveal_at_progress`** when the move defines it), sets defender **`guard_zone`** to the telegraph (**`feint_part`** when present). Uses **`CombatRegressionHarness.CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED`** for stable upstream wind-up rolls; restores **`CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED`** before teardown.
static func _run_depth_spear_tight_lane_parry_mult_invariant(failures: PackedStringArray) -> void:
	var m0: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult({})
	var m_open: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{
			"depth_polearm_attack": true,
			"depth_polearm_allows_low_targets": true,
			"depth_polearm_lane_type": "open",
		}
	)
	var m_tight: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{
			"depth_polearm_attack": true,
			"depth_polearm_allows_low_targets": false,
			"depth_polearm_lane_type": "over_shoulder",
		}
	)
	var m_empty_allows: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{"depth_polearm_attack": true, "depth_polearm_allows_low_targets": true, "depth_polearm_lane_type": ""}
	)
	var m_empty_tight: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
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
			"depth_spear_parry_mult: tight lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_tight]
		)
	if not is_equal_approx(m_empty_allows, 1.0):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_mult: empty lane_type + allows_low should follow open got %.4f" % m_empty_allows
		)
	if not is_equal_approx(m_empty_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_mult: empty lane_type + tight allows_low want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_empty_tight]
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
	var a_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "thrust")
	var pa_legacy_lane: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": true,
		"depth_polearm_lane_type": "",
	}
	var a_legacy_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_legacy_lane, "thrust")
	var a_tight_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_tight, "thrust")
	var a_slash: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "slash")
	var a0: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult({}, "thrust")
	if not is_equal_approx(a_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_p_a: open+stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_stab]
		)
	if not is_equal_approx(a_legacy_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_p_a: empty lane_type + allows_low stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_legacy_stab]
		)
	var pa_open_tight_bool: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": false,
		"depth_polearm_lane_type": "open",
	}
	var a_open_id_over_allows: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(
		pa_open_tight_bool, "thrust"
	)
	if not is_equal_approx(a_open_id_over_allows, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_p_a: explicit open lane id should win over allows_low=false got %.4f"
			% a_open_id_over_allows
		)
	if not is_equal_approx(a_tight_stab, 1.0) or not is_equal_approx(a_slash, 1.0) or not is_equal_approx(a0, 1.0):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_parry_p_a: expected 1.0 for tight stab / open slash / non-depth got tight=%.4f slash=%.4f a0=%.4f"
			% [a_tight_stab, a_slash, a0]
		)


## Tier 3.1: **`CombatConstants.STRIKE_MEASURE_*`** drive **`strike_measure_ratio_for_weapon_eff_dist`** (formula lock).
static func _run_depth_spear_thrust_closing_factor_invariant(failures: PackedStringArray) -> void:
	var f0: float = _StrikePhysics.depth_polearm_thrust_closing_factor({})
	var f_cut: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{"depth_polearm_attack": true, "attack_type": "spear_slash"}
	)
	var f_stab: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{"depth_polearm_attack": true, "attack_type": "spear_thrust"}
	)
	var f_stab_open: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "open",
		}
	)
	var f_stab_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "over_shoulder",
		}
	)
	var f_stab_shoulder_overrides_allows: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "over_shoulder",
			"depth_polearm_allows_low_targets": true,
		}
	)
	var f_stab_empty_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "",
			"depth_polearm_allows_low_targets": false,
		}
	)
	var f_stab_garbage_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "bogus",
			"depth_polearm_allows_low_targets": false,
		}
	)
	var f_stab_open_ignores_allows: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "open",
			"depth_polearm_allows_low_targets": false,
		}
	)
	if not is_equal_approx(f0, 1.0) or not is_equal_approx(f_cut, 1.0):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_closing: expected 1.0 for empty / non-stab got f0=%.4f f_cut=%.4f" % [f0, f_cut]
		)
	if not is_equal_approx(f_stab, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_closing: stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab]
		)
	if not is_equal_approx(f_stab_open, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_closing: stab+open lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open]
		)
	if not is_equal_approx(f_stab_tight, 1.0):
		CombatRegressionHarness._fail(failures, "depth_spear_closing: stab+tight lane want 1.0 got %.4f" % f_stab_tight)
	if not is_equal_approx(f_stab_shoulder_overrides_allows, 1.0):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_closing: over_shoulder lane id must override allows_low=true got %.4f"
			% f_stab_shoulder_overrides_allows
		)
	if not is_equal_approx(f_stab_empty_tight, 1.0):
		CombatRegressionHarness._fail(failures, "depth_spear_closing: empty lane + allows_low false want 1.0 got %.4f" % f_stab_empty_tight)
	if not is_equal_approx(f_stab_garbage_tight, 1.0):
		CombatRegressionHarness._fail(failures, "depth_spear_closing: unknown lane + allows_low false want 1.0 got %.4f" % f_stab_garbage_tight)
	if not is_equal_approx(f_stab_open_ignores_allows, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		CombatRegressionHarness._fail(
			failures,
			"depth_spear_closing: explicit open lane should ignore allows_low want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open_ignores_allows]
		)


## Tier 1.6: **`ordered_melee_opponents`** — **`is_melee_file_opposed_priority`** sorts **before** **`hostile_pair_targeting_weight_mult`** (same-file rank-0 line pair ahead of lateral rank-0).
static func _run_spear_lane_profile_preset_normalized(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
		CombatRegressionHarness._fail(failures, "spear_lane_preset: enemy default profile should be auto/empty got %s" % se)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`Weapon.depth_melee_eligible`** from **`WeaponConstants`** definitions — **SPEAR** **true**; **SWORD** default **false** ( **`CombatDepthPolearm.depth_polearm_lane_open`** gate).
static func _run_weapon_depth_melee_eligible_fixture(failures: PackedStringArray) -> void:
	var w_spear: Weapon = _Weapon.create_from_definition("SPEAR")
	var w_sword: Weapon = _Weapon.create_from_definition("SWORD")
	if w_spear == null or w_sword == null:
		CombatRegressionHarness._fail(failures, "depth_melee_elig: missing weapon fixtures")
		return
	if not w_spear.depth_melee_eligible:
		CombatRegressionHarness._fail(failures, "depth_melee_elig: SPEAR should be depth_melee_eligible")
	if w_sword.depth_melee_eligible:
		CombatRegressionHarness._fail(failures, "depth_melee_elig: SWORD should not be depth_melee_eligible by default")


## Tier 1.9: rank>1 without **`depth_melee_eligible`** weapon → **`depth_polearm_lane_open`** **false** even with same-file living rank-0 ally (lane predicate, not only **`can_melee_threaten`**).
static func _run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr.combatants[1]
	if _DepthPolearm.depth_polearm_lane_open(mgr, depth_sw):
		CombatRegressionHarness._fail(
			failures,
			"depth_lane_non_eligible: rank-1 sword must not open depth polearm lane (rank-0 ally present)"
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** at **`rank` ≤ 0** (lane is for **home** depth ranks only).
static func _run_depth_polearm_lane_open_false_at_rank_zero(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var front: Dictionary = mgr.combatants[0]
	if _EntityAccess.rank_int(front) != 0:
		CombatRegressionHarness._fail(failures, "depth_lane_r0: expected player spear at rank 0 got rank %s" % str(_EntityAccess.rank_int(front)))
	if _DepthPolearm.depth_polearm_lane_open(mgr, front):
		CombatRegressionHarness._fail(failures, "depth_lane_r0: rank-0 spear must not open depth polearm lane")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: no **living** same-file rank-0 partner → **`depth_polearm_lane_open`** **false** (even with **`depth_melee_eligible`** weapon).
static func _run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth_f1: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.file_int(c) != 1:
			continue
		if _EntityAccess.rank_int(c) == 1:
			depth_f1 = c
		elif _EntityAccess.rank_int(c) == 0:
			front_f1 = c
	if depth_f1.is_empty() or front_f1.is_empty():
		CombatRegressionHarness._fail(failures, "depth_lane_no_r0: expected player rank-0 + rank-1 at file 1")
		CombatRegressionHarness._free_manager(mgr)
		return
	front_f1["alive"] = false
	mgr._recompute_zoc_and_distance()
	if _DepthPolearm.depth_polearm_lane_open(mgr, depth_f1):
		CombatRegressionHarness._fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 1 must not open lane when same-file rank-0 is dead"
		)
	var depth_f0: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.file_int(c) == 0 and _EntityAccess.rank_int(c) == 1:
			depth_f0 = c
			break
	if depth_f0.is_empty():
		CombatRegressionHarness._fail(failures, "depth_lane_no_r0: expected player rank-1 at file 0")
	elif not _DepthPolearm.depth_polearm_lane_open(mgr, depth_f0):
		CombatRegressionHarness._fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 0 should still open lane (living same-file rank-0 at file 0)"
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`CombatDistanceBands.depth_polearm_lane_open_by_combatant_id`** matches **`CombatDepthPolearm.depth_polearm_lane_open`** ( **`zone_geometry_fid_str`** `fid` ).
static func _run_depth_polearm_lane_cache_matches_builder(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	mgr._recompute_zoc_and_distance()
	CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:1file")
	CombatRegressionHarness._free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start({"files": 2, "ranks": 2, "density": "normal"}, e_preset)
	var front_f1: Dictionary = {}
	for c in mgr2.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.file_int(c) != 1 or _EntityAccess.rank_int(c) != 0:
			continue
		front_f1 = c
		break
	if front_f1.is_empty():
		CombatRegressionHarness._fail(failures, "depth_lane_cache:2wide expected rank-0 file 1")
		CombatRegressionHarness._free_manager(mgr2)
		return
	front_f1["alive"] = false
	mgr2._recompute_zoc_and_distance()
	CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(mgr2, failures, "depth_lane_cache:2wide_dead_r0f1")
	CombatRegressionHarness._free_manager(mgr2)


## Tier 1.9: same-file rank-0 partner **incapacitated** → **`depth_polearm_lane_open`** **false** (**`same_file_living_rank0_ally`** skips incap).
static func _run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	mgr._recompute_zoc_and_distance()
	if not _EntityAccess.is_incapacitated(front):
		CombatRegressionHarness._fail(failures, "depth_lane_r0_incap: rank-0 ally should read incapacitated")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(
			failures,
			"depth_lane_r0_incap: rank-1 spear must not open lane when same-file rank-0 is incapacitated"
		)
	CombatRegressionHarness._assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:r0_incap")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open(manager, c, "")`** matches **`depth_polearm_lane_open(manager, c, fid)`** when **`fid == zone_geometry_fid_str(manager, c)`** (explicit **`zone_geometry_fid`** contract).
static func _run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, c)
		var o_default: bool = _DepthPolearm.depth_polearm_lane_open(mgr, c, "")
		var o_explicit: bool = _DepthPolearm.depth_polearm_lane_open(mgr, c, fid)
		if o_default != o_explicit:
			CombatRegressionHarness._fail(
				failures,
				"depth_lane_fid_rt: id=%d default=%s explicit_fid=%s fid=%s"
				% [_EntityAccess.id_int(c), str(o_default), str(o_explicit), fid]
			)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — open depth lane + **strict** + **tight** + no lane stress → **false** (over-shoulder); **`spear_lane_profile` open** on same geometry → **true**.
static func _run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_allows_low: expected open depth polearm lane for setup")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	if _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_allows_low: strict+tight+lane open+no wedge should not allow low targets")
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	if not _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_allows_low: spear_lane_profile open should allow low targets on tight formation")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** **`pa`** depth keys match **`depth_polearm_lane_allows_low_targets`** ( **`assume_depth_lane_open` true** ) and **`DEPTH_POLEARM_LANE_TYPE_*`**.
static func _run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "stamp_depth_geom: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	var live_tight: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa: Dictionary = {}
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
	if bool(pa.get("depth_polearm_attack", false)) != true:
		CombatRegressionHarness._fail(failures, "stamp_depth_geom: expected depth_polearm_attack true")
	var stamped_allow: bool = bool(pa.get("depth_polearm_allows_low_targets", true))
	if stamped_allow != live_tight:
		CombatRegressionHarness._fail(
			failures,
			"stamp_depth_geom: allows_low stamped=%s live=%s (strict tight)" % [str(stamped_allow), str(live_tight)]
		)
	var lt: String = str(pa.get("depth_polearm_lane_type", ""))
	var expect_lt: String = (
		CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
		if live_tight
		else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
	)
	if lt != expect_lt:
		CombatRegressionHarness._fail(failures, "stamp_depth_geom: lane_type=%s expected %s (strict tight)" % [lt, expect_lt])
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	var live_open: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa2: Dictionary = {}
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa2)
	if bool(pa2.get("depth_polearm_allows_low_targets", false)) != live_open:
		CombatRegressionHarness._fail(
			failures,
			"stamp_depth_geom: allows_low stamped=%s live=%s (profile open)" % [str(pa2.get("depth_polearm_allows_low_targets")), str(live_open)]
		)
	var lt2: String = str(pa2.get("depth_polearm_lane_type", ""))
	var expect_lt2: String = (
		CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
		if live_open
		else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
	)
	if lt2 != expect_lt2:
		CombatRegressionHarness._fail(failures, "stamp_depth_geom: lane_type=%s expected %s (profile open)" % [lt2, expect_lt2])
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** leaves **`depth_polearm_*`** at non-depth defaults when attacker is rank **0** or rank **>0** with **`depth_polearm_lane_open`** **false**.
static func _run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	m0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	var en0: Dictionary = m0.combatants[1]
	if _EntityAccess.rank_int(atk0) != 0:
		CombatRegressionHarness._fail(failures, "stamp_depth_def: expected rank-0 spear")
		CombatRegressionHarness._free_manager(m0)
		return
	var pa0: Dictionary = {}
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(m0, atk0, en0, pa0)
	CombatRegressionHarness._assert_stamp_depth_pa_defaults(pa0, failures, "stamp_depth_def:rank0")
	CombatRegressionHarness._free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p1: Dictionary = {"files": 1, "ranks": 2, "density": "normal"}
	var e1: Dictionary = {"files": 1, "ranks": 1, "density": "normal"}
	m1.start(p1, e1)
	var atk1: Dictionary = m1.combatants[1]
	var en1: Dictionary = m1.combatants[2]
	if _EntityAccess.rank_int(atk1) <= 0:
		CombatRegressionHarness._fail(failures, "stamp_depth_def: expected rank-1 sword")
		CombatRegressionHarness._free_manager(m1)
		return
	if _DepthPolearm.depth_polearm_lane_open(m1, atk1):
		CombatRegressionHarness._fail(failures, "stamp_depth_def: rank-1 sword should not open depth lane")
		CombatRegressionHarness._free_manager(m1)
		return
	var pa1: Dictionary = {}
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(m1, atk1, en1, pa1)
	CombatRegressionHarness._assert_stamp_depth_pa_defaults(pa1, failures, "stamp_depth_def:rank1_no_lane")
	CombatRegressionHarness._free_manager(m1)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** drops legs iff **`depth_polearm_lane_allows_low_targets`** (**`assume_depth_lane_open` true**) is **false** (same strict/tight vs **`spear_lane_profile` open** flip as other depth harnesses).
static func _run_depth_polearm_parts_filter_tracks_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_parts_al: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	if _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		CombatRegressionHarness._fail(failures, "depth_parts_al: strict+tight should not allow low targets before filter assert")
	var filt_tight: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_parts_al: filter should drop legs when allows_low false (got %s)" % str(filt_tight))
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	if not _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		CombatRegressionHarness._fail(failures, "depth_parts_al: open profile should allow low targets before filter assert")
	var filt_open: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_open.has("left_leg") or not filt_open.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_parts_al: filter should keep legs when allows_low true (got %s)" % str(filt_open))
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`lane_stress_by_file`** at depth file opens lows under **strict**/**tight** (no **`spear_lane_profile` open**) — **`depth_polearm_lane_allows_low_targets`** + **`depth_polearm_targetable_parts_filter`**.
static func _run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_parts_wedge: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var df: int = _EntityAccess.file_int(depth, 0)
	mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	if not _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		CombatRegressionHarness._fail(failures, "depth_parts_wedge: lane stress should open low targets under strict+tight")
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt.has("left_leg") or not filt.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_parts_wedge: filter should keep legs when wedge opens lane (got %s)" % str(filt))
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`spear_lane_profile` restricted** — **`depth_polearm_lane_allows_low_targets`** is **false** without lane stress, **true** when **`lane_stress_by_file`** exceeds threshold ( **`depth_polearm_targetable_parts_filter`** follows).
static func _run_depth_polearm_restricted_profile_requires_lane_stress_for_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_prof_rest: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = (
		CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	if _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		CombatRegressionHarness._fail(failures, "depth_prof_rest: restricted + loose should not allow lows without wedge")
	var parts_in: Array = ["head", "left_leg", "right_leg"]
	var filt_no_w: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_no_w.has("left_leg") or filt_no_w.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_prof_rest: filter should drop legs without wedge (got %s)" % str(filt_no_w))
	var df: int = _EntityAccess.file_int(depth, 0)
	mgr.formations["player"]["lane_stress_by_file"] = {df: 0.85}
	fd = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	if not _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		CombatRegressionHarness._fail(failures, "depth_prof_rest: lane stress should allow lows under restricted profile")
	var filt_w: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_w.has("left_leg") or not filt_w.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_prof_rest: filter should keep legs after wedge (got %s)" % str(filt_w))
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** with explicit **`formation_dict_cache`** (deep copy of live dict) matches **`null`** cache (same **`fid`**, **`assume_depth_lane_open` true**).
static func _run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_al_fd_cache: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	var fd_dup: Dictionary = fd.duplicate(true)
	var a_tight: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_tight: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_tight != b_tight:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch strict+tight (null=%s cache=%s)" % [str(a_tight), str(b_tight)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_for_combatant_cached(mgr, depth, null, fid)
	fd_dup = fd.duplicate(true)
	var a_open: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_open: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_open != b_open:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch profile open (null=%s cache=%s)" % [str(a_open), str(b_open)]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** is a **pass-through** when **`depth_polearm_lane_open`** is **false** (rank-1 non-polearm) or attacker **`rank` ≤ 0** (no depth lane use).
static func _run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	m0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	if _EntityAccess.rank_int(atk0) != 0:
		CombatRegressionHarness._fail(failures, "depth_parts_pass: expected rank-0 attacker")
		CombatRegressionHarness._free_manager(m0)
		return
	var parts0: Array = ["head", "left_leg", "right_leg"]
	var out0: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(m0, atk0, parts0)
	if out0 != parts0:
		CombatRegressionHarness._fail(failures, "depth_parts_pass: rank-0 should not filter parts (got %s)" % str(out0))
	CombatRegressionHarness._free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	m1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	m1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk1: Dictionary = m1.combatants[1]
	if _EntityAccess.rank_int(atk1) <= 0:
		CombatRegressionHarness._fail(failures, "depth_parts_pass: expected rank-1 sword")
		CombatRegressionHarness._free_manager(m1)
		return
	if _DepthPolearm.depth_polearm_lane_open(m1, atk1):
		CombatRegressionHarness._fail(failures, "depth_parts_pass: rank-1 sword should not open depth lane")
		CombatRegressionHarness._free_manager(m1)
		return
	var parts1: Array = ["head", "left_leg"]
	var out1: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(m1, atk1, parts1)
	if out1 != parts1:
		CombatRegressionHarness._fail(failures, "depth_parts_pass: lane closed should not filter parts (got %s)" % str(out1))
	CombatRegressionHarness._free_manager(m1)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — **`assume_depth_lane_open` false** returns **true** when **`depth_polearm_lane_open`** is **false** (depth lane N/A); **`assume_depth_lane_open` true** skips that guard and runs wedge / **`spear_lane_profile`** / discipline (strict+tight → **false** without open profile).
static func _run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if _EntityAccess.rank_int(depth) <= 0:
		CombatRegressionHarness._fail(failures, "depth_al_assume: expected rank-1 depth combatant")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_al_assume: rank-1 sword must not open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var without_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var with_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if not without_assume:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_assume: lane closed + assume false should return true (depth lane N/A)"
		)
	if with_assume:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_assume: strict+tight + assume true should evaluate lane rules → false (no open profile)"
		)
	if without_assume == with_assume:
		CombatRegressionHarness._fail(failures, "depth_al_assume: assume flag must change result when lane closed vs strict+tight body")
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_lane_allows_low_targets`** returns the same value whether **`assume_depth_lane_open`** is **false** or **true** (closed-lane early exit skipped in both cases once the lane is open).
static func _run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_al_agree: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.zone_geometry_fid_str(mgr, depth)
	var tight_no_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var tight_with_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if tight_no_assume != tight_with_assume:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_agree: strict+tight assume false vs true mismatch (%s vs %s)"
			% [str(tight_no_assume), str(tight_with_assume)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var open_no_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var open_with_assume: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if open_no_assume != open_with_assume:
		CombatRegressionHarness._fail(
			failures,
			"depth_al_agree: profile open assume false vs true mismatch (%s vs %s)"
			% [str(open_no_assume), str(open_with_assume)]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets(manager, c, "", …)`** matches **`…(manager, c, fid, …)`** when **`fid == zone_geometry_fid_str(manager, c)`** — same **`zone_geometry_fid`** contract as **`depth_polearm_lane_open`** / **`formation_for_combatant_cached`**. Covers **`assume_depth_lane_open` false + true** on **home** line.
static func _run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	CombatRegressionHarness._assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, "depth_al_fid_rt:home")
	CombatRegressionHarness._free_manager(mgr)


static func _run_depth_polearm_auto_lane_discipline_posture(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "tight"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_strict: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_strict.has("left_leg") or f_strict.has("right_leg"):
		CombatRegressionHarness._fail(failures, "depth_auto_lane: strict discipline + tight should filter legs (got %s)" % str(f_strict))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	var f_loose_disc: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_loose_disc.has("left_leg"):
		CombatRegressionHarness._fail(failures, "depth_auto_lane: loose discipline + tight should allow legs (got %s)" % str(f_loose_disc))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_loose_dens_strict: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_loose_dens_strict.has("left_leg") or f_loose_dens_strict.has("right_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_auto_lane: strict should override loose density for legs (got %s)" % str(f_loose_dens_strict)
		)
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var f_open_post: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_open_post.has("left_leg"):
		CombatRegressionHarness._fail(failures, "depth_auto_lane: OPEN posture + tight should allow legs (got %s)" % str(f_open_post))
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_DUEL
	var f_duel_post: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_duel_post.has("left_leg"):
		CombatRegressionHarness._fail(failures, "depth_auto_lane: DUEL posture + tight should allow legs (got %s)" % str(f_duel_post))
	# LINE posture + normal discipline + tight: auto profile stays over-shoulder (stamped `pa` agrees).
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	var f_line_norm: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_line_norm.has("left_leg") or f_line_norm.has("right_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_auto_lane: LINE posture + normal discipline + tight should filter legs (got %s)"
			% str(f_line_norm)
		)
	var pa_ln: Dictionary = {}
	var en0: Dictionary = mgr.combatants[2]
	_StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, depth, en0, pa_ln)
	if bool(pa_ln.get("depth_polearm_allows_low_targets", true)):
		CombatRegressionHarness._fail(failures, "depth_auto_lane: stamped allows_low false for LINE+normal+tight depth attack")
	if str(pa_ln.get("depth_polearm_lane_type", "")) != CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER:
		CombatRegressionHarness._fail(
			failures,
			"depth_auto_lane: stamped lane_type over_shoulder got %s"
			% str(pa_ln.get("depth_polearm_lane_type"))
		)
	# Empty formation field falls back to encounter discipline (same as posture / fall-back policy).
	mgr.formations["player"]["line_discipline"] = ""
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_enc_strict: Array = _DepthPolearm.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_enc_strict.has("left_leg") or f_enc_strict.has("right_leg"):
		CombatRegressionHarness._fail(
			failures,
			"depth_auto_lane: encounter strict with empty formation discipline should filter legs (got %s)" % str(f_enc_strict)
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.6: pinch `wing_lacks_file_opposed` uses same-file rank-0 partner when depth spear lane is open.
static func _run_wing_lacks_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	var depth_spear: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		var w: Variant = _EntityAccess.get_weapon(c)
		if w != null and w is Weapon and _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 1:
			if (w as Weapon).depth_melee_eligible:
				depth_spear = c
		if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 1:
			front_f1 = c
	var front_f0: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.is_player_side(c) and _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
			front_f0 = c
			break
	if depth_spear.is_empty() or front_f1.is_empty() or front_f0.is_empty():
		CombatRegressionHarness._fail(failures, "wing_depth: expected 2×2 player grid with spear at rank1 file1")
		return
	if _TargetScoring.wing_lacks_file_opposed(mgr, front_f1):
		CombatRegressionHarness._fail(
			failures, "wing_depth: rank0 file1 should map to sole enemy file0 (nearest wing)"
		)
	if _TargetScoring.wing_lacks_file_opposed(mgr, front_f0):
		CombatRegressionHarness._fail(failures, "wing_depth: rank0 file0 should have file-opposed enemy")
	if _TargetScoring.wing_lacks_file_opposed(mgr, depth_spear):
		CombatRegressionHarness._fail(
			failures, "wing_depth: depth spear should inherit front file1 mapped opposition"
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: depth rank spear listing weights vs formation doctrine (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
static func _run_depth_polearm_doctrine_action_weights(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr, depth):
		CombatRegressionHarness._fail(failures, "depth_doc_weights: expected open depth polearm lane")
		CombatRegressionHarness._free_manager(mgr)
		return
	var w_base_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_base_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w_pinch_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_pinch_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var w_hold_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_hold_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	var w_probe_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_probe_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	if w_pinch_stab <= w_base_stab + 0.001:
		CombatRegressionHarness._fail(failures, "depth_doc_weights: pinch should raise stab vs default")
	if w_hold_stab >= w_base_stab - 0.001:
		CombatRegressionHarness._fail(failures, "depth_doc_weights: hold should lower stab vs default")
	if w_pinch_slash >= w_base_slash - 0.001:
		CombatRegressionHarness._fail(failures, "depth_doc_weights: pinch should lower non-stab vs default")
	if w_hold_slash <= w_base_slash + 0.001:
		CombatRegressionHarness._fail(failures, "depth_doc_weights: hold should raise non-stab vs default")
	if w_probe_stab <= w_hold_stab + 1e-5 or w_probe_stab >= w_pinch_stab - 1e-5:
		CombatRegressionHarness._fail(
			failures,
			"depth_doc_weights: probing stab should sit strictly between hold and pinch hold=%.6f probe=%.6f pinch=%.6f"
			% [w_hold_stab, w_probe_stab, w_pinch_stab]
		)
	if w_probe_slash <= w_pinch_slash + 1e-5 or w_probe_slash >= w_hold_slash - 1e-5:
		CombatRegressionHarness._fail(
			failures,
			"depth_doc_weights: probing non-stab should sit strictly between pinch and hold pinch=%.6f probe=%.6f hold=%.6f"
			% [w_pinch_slash, w_probe_slash, w_hold_slash]
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: optional encounter + preset **`depth_polearm_ai_doctrine_mults`** merged at **`CombatManager.start`** (preset wins; clamp **`DEPTH_POLEARM_AI_MULT_OVERRIDE_*`**).
static func _run_depth_polearm_ai_doctrine_mults_encounter_preset(failures: PackedStringArray) -> void:
	var pinch_k: String = CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB
	var pinch_def: float = CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT
	var merged_clamp: Dictionary = CombatConstants.merge_depth_polearm_ai_doctrine_mults(
		CombatConstants.default_depth_polearm_ai_doctrine_mults_dict(),
		{pinch_k: 9.0}
	)
	if not is_equal_approx(float(merged_clamp[pinch_k]), CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX):
		CombatRegressionHarness._fail(
			failures,
			"depth_ai_mults: clamp max want %.4f got %.4f"
			% [CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX, float(merged_clamp[pinch_k])]
		)
	var mgr0: Node = _MgrScript.new()
	mgr0.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr0.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr0.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr0.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth0: Dictionary = mgr0.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr0, depth0):
		CombatRegressionHarness._fail(failures, "depth_ai_mults: expected open depth polearm lane (baseline)")
		CombatRegressionHarness._free_manager(mgr0)
		return
	mgr0.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w0: float = _AIPicker._depth_polearm_action_weight_mult(mgr0, depth0, "spear_thrust")
	if not is_equal_approx(w0, CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * pinch_def):
		CombatRegressionHarness._fail(failures, "depth_ai_mults: baseline pinch stab mult mismatch got %.6f" % w0)
	var mgr1: Node = _MgrScript.new()
	mgr1.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.26}
	mgr1.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr1.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr1.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth1: Dictionary = mgr1.combatants[1]
	mgr1.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w1: float = _AIPicker._depth_polearm_action_weight_mult(mgr1, depth1, "spear_thrust")
	var expect_enc: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.26
	if not is_equal_approx(w1, expect_enc):
		CombatRegressionHarness._fail(failures, "depth_ai_mults: encounter pinch override want %.6f got %.6f" % [expect_enc, w1])
	if not is_equal_approx(w1 / w0, 1.26 / pinch_def):
		CombatRegressionHarness._fail(failures, "depth_ai_mults: encounter ratio vs default pinch")
	var p_preset: Dictionary = {
		"files": 1,
		"ranks": 2,
		"density": "normal",
		CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS: {pinch_k: 1.44},
	}
	var mgr2: Node = _MgrScript.new()
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.2}
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start(p_preset, {"files": 1, "ranks": 1, "density": "normal"})
	var depth2: Dictionary = mgr2.combatants[1]
	mgr2.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w2: float = _AIPicker._depth_polearm_action_weight_mult(mgr2, depth2, "spear_thrust")
	var expect_preset: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.44
	if not is_equal_approx(w2, expect_preset):
		CombatRegressionHarness._fail(
			failures,
			"depth_ai_mults: preset should win over encounter want %.6f got %.6f" % [expect_preset, w2]
		)
	var mgr3: Node = _MgrScript.new()
	mgr3.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY] = {pinch_k: 1.11}
	mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr3.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k), 1.11):
		CombatRegressionHarness._fail(
			failures,
			"depth_ai_mults: enemy encounter mult got %s"
			% str(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k))
		)
	if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k), pinch_def):
		CombatRegressionHarness._fail(
			failures,
			"depth_ai_mults: player pinch should stay default got %s"
			% str(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k))
		)
	CombatRegressionHarness._free_manager(mgr0)
	CombatRegressionHarness._free_manager(mgr1)
	CombatRegressionHarness._free_manager(mgr2)
	CombatRegressionHarness._free_manager(mgr3)


## Tier 1.9: **`CombatAIActionPicker._depth_polearm_action_weight_mult`** stays neutral (**1.0**) when no **`depth_polearm_valid_line_threat`** to any hostile rank 0 (lane may still be open); boosts stab when **3-wide** yields ≥1 valid line.
static func _run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures: PackedStringArray) -> void:
	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr_far.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _DepthPolearm.depth_polearm_lane_open(mgr_far, depth_far):
		CombatRegressionHarness._fail(failures, "ai_vlt_any: expected open lane")
		CombatRegressionHarness._free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	if _DepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr_far, depth_far, mgr_far.combatants):
		CombatRegressionHarness._fail(failures, "ai_vlt_any: expected no valid-line rank-0 hostile after pushing files")
		CombatRegressionHarness._free_manager(mgr_far)
		return
	var w_neutral_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr_far, depth_far, "spear_thrust")
	var w_neutral_close: float = _AIPicker._depth_polearm_action_weight_mult(
		mgr_far, depth_far, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
	)
	if absf(w_neutral_stab - 1.0) > 0.001 or absf(w_neutral_close - 1.0) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"ai_vlt_any: far-line AI mult should be 1.0 stab=%s close=%s" % [str(w_neutral_stab), str(w_neutral_close)]
		)
	CombatRegressionHarness._free_manager(mgr_far)
	var mgr3: Node = _MgrScript.new()
	mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr3.register(CombatRegressionHarness._new_entity("SPEAR"), "player")
	for _j in 3:
		mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr3._recompute_zoc_and_distance()
	var depth3: Dictionary = mgr3.combatants[1]
	if not _DepthPolearm.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr3, depth3, mgr3.combatants):
		CombatRegressionHarness._fail(failures, "ai_vlt_any: standard 3-wide should have ≥1 valid-line rank-0 target")
		CombatRegressionHarness._free_manager(mgr3)
		return
	var w_boost: float = _AIPicker._depth_polearm_action_weight_mult(mgr3, depth3, "spear_thrust")
	if w_boost <= 1.001:
		CombatRegressionHarness._fail(failures, "ai_vlt_any: standard layout should boost stab mult got %s" % str(w_boost))
	CombatRegressionHarness._free_manager(mgr3)


## Option 4: `CombatDoctrine.enemy_line_hollow_center_for_pinch` (automatic pinch trigger when `FEATURE_AUTOMATIC_DOCTRINE` is enabled).
static func _run_doctrine_hollow_center_pinch_heuristic(failures: PackedStringArray) -> void:
	_CombatDoctrine.evaluate_automatic_doctrine(null)
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var en_by_file: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_enemy_side(c):
			continue
		en_by_file[_EntityAccess.file_int(c)] = c
	if en_by_file.size() < 3:
		CombatRegressionHarness._fail(failures, "doctrine_hollow: expected 3 enemies")
		CombatRegressionHarness._free_manager(mgr)
		return
	(en_by_file[1] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		CombatRegressionHarness._fail(failures, "doctrine_hollow: 3-file line with dead center should read as hollow for pinch")
	(en_by_file[1] as Dictionary)["alive"] = true
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		CombatRegressionHarness._fail(failures, "doctrine_hollow: full enemy front should not be hollow")
	(en_by_file[1] as Dictionary)["alive"] = false
	(en_by_file[2] as Dictionary)["alive"] = false
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		CombatRegressionHarness._fail(failures, "doctrine_hollow: single-wing line should not qualify as hollow center")
	CombatRegressionHarness._free_manager(mgr)

	var mgr4: Node = _MgrScript.new()
	mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _k in 4:
		mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr4.start({"files": 1, "ranks": 1}, {"files": 4, "ranks": 1})
	var en4: Dictionary = {}
	for c in mgr4.combatants:
		if _EntityAccess.is_enemy_side(c):
			en4[_EntityAccess.file_int(c)] = c
	for kill_i in [1, 2]:
		(en4[kill_i] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr4, "player"):
		CombatRegressionHarness._fail(failures, "doctrine_hollow: 4-file empty middle pair + living wings should be hollow")
	CombatRegressionHarness._free_manager(mgr4)


static func _run_doctrine_normalize_and_manager_roundtrip(failures: PackedStringArray) -> void:
	if _CombatDoctrine.normalize("") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(failures, "doctrine_norm: empty string should be default")
	if _CombatDoctrine.normalize("  \t ") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(failures, "doctrine_norm: whitespace-only should be default")
	if _CombatDoctrine.normalize("pinch") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(failures, "doctrine_norm: pinch alias")
	if _CombatDoctrine.normalize("PINCH_CENTER") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(failures, "doctrine_norm: canonical pinch_center")
	if _CombatDoctrine.normalize("pincer") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(failures, "doctrine_norm: pincer alias")
	if _CombatDoctrine.normalize("hold") != CombatConstants.DOCTRINE_HOLD_LANE:
		CombatRegressionHarness._fail(failures, "doctrine_norm: hold alias")
	if _CombatDoctrine.normalize("probing") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(failures, "doctrine_norm: probing alias")
	if _CombatDoctrine.normalize(CombatConstants.DOCTRINE_PROBING) != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(failures, "doctrine_norm: probing canonical")
	if _CombatDoctrine.normalize("not_a_real_doctrine_string") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(failures, "doctrine_norm: unknown → default")
	if _CombatDoctrine.doctrine_for_fid(null, "player") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(failures, "doctrine_for_fid: null manager → default")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.set_formation_doctrine("player", "  pincer  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(
			failures,
			"doctrine_roundtrip: player got %s want pinch_center"
			% mgr.get_formation_doctrine("player")
		)
	mgr.set_formation_doctrine("player", "  probing  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(
			failures,
			"doctrine_rt: set probing expected %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	mgr.set_formation_doctrine("enemy", "bogus_doctrine_value")
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(
			failures,
			"doctrine_roundtrip: enemy unknown should store default got %s"
			% mgr.get_formation_doctrine("enemy")
		)
	CombatRegressionHarness._free_manager(mgr)


## Tier 1.9: **`encounter`** + optional **`start()`** preset dicts seed **`formation_doctrine`** (`ENCOUNTER_KEY_FORMATION_DOCTRINE_*`, else encounter alt keys, then preset **`FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, via **`CombatConstants.formation_doctrine_string_from_dict`** for presets).
static func _run_encounter_formation_doctrine_on_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  probing  "
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = "hold"
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_start: player want %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_start: enemy want %s got %s"
			% [CombatConstants.DOCTRINE_HOLD_LANE, mgr.get_formation_doctrine("enemy")]
		)
	CombatRegressionHarness._free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  \t  "
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr2.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr2.get_formation_doctrine("player") != CombatConstants.DOCTRINE_DEFAULT:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_start: whitespace-only encounter value should keep default got %s"
			% mgr2.get_formation_doctrine("player")
		)
	CombatRegressionHarness._free_manager(mgr2)
	var mgr3: Node = _MgrScript.new()
	mgr3.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	var pdoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "hold_lane"
	}
	mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr3.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr3.start(pdoc, {"files": 1, "ranks": 1})
	if mgr3.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		CombatRegressionHarness._fail(
			failures,
			"preset_doctrine_start: player preset should override encounter probing got %s"
			% mgr3.get_formation_doctrine("player")
		)
	CombatRegressionHarness._free_manager(mgr3)
	var mgr4: Node = _MgrScript.new()
	mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr4.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var edoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "pinch"
	}
	mgr4.start({"files": 1, "ranks": 1}, edoc)
	if mgr4.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
		CombatRegressionHarness._fail(
			failures,
			"preset_doctrine_start: enemy preset pinch alias want pinch_center got %s"
			% mgr4.get_formation_doctrine("enemy")
		)
	CombatRegressionHarness._free_manager(mgr4)
	var mgr5: Node = _MgrScript.new()
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "probing"
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT] = "hold"
	mgr5.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr5.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr5.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_alt: player doctrine_player want probing got %s"
			% mgr5.get_formation_doctrine("player")
		)
	if mgr5.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_alt: enemy doctrine_enemy want hold_lane got %s"
			% mgr5.get_formation_doctrine("enemy")
		)
	CombatRegressionHarness._free_manager(mgr5)
	var mgr6: Node = _MgrScript.new()
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "hold_lane"
	mgr6.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr6.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr6.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr6.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(
			failures,
			"encounter_doctrine_alt: canonical formation_doctrine_player should win over doctrine_player got %s"
			% mgr6.get_formation_doctrine("player")
		)
	CombatRegressionHarness._free_manager(mgr6)
	var mgr7: Node = _MgrScript.new()
	mgr7.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr7.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p7: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold",
	}
	mgr7.start(p7, {"files": 1, "ranks": 1})
	if mgr7.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		CombatRegressionHarness._fail(
			failures,
			"preset_doctrine_alt: player preset `doctrine` only want hold_lane got %s"
			% mgr7.get_formation_doctrine("player")
		)
	CombatRegressionHarness._free_manager(mgr7)
	var mgr8: Node = _MgrScript.new()
	mgr8.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr8.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	var p8: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
	}
	mgr8.start(p8, {"files": 1, "ranks": 1})
	if mgr8.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		CombatRegressionHarness._fail(
			failures,
			"preset_doctrine_alt: canonical formation_doctrine on preset should win over doctrine got %s"
			% mgr8.get_formation_doctrine("player")
		)
	CombatRegressionHarness._free_manager(mgr8)


## Tier 1.9: **`CombatConstants.encounter_formation_doctrine_string`** / **`formation_doctrine_string_from_dict`** match **`CombatManager.start()`** read order.
static func _run_encounter_formation_doctrine_string_helper(failures: PackedStringArray) -> void:
	var enc_alt: Dictionary = {
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "  hold  ",
	}
	var got_alt: String = CombatConstants.encounter_formation_doctrine_string(
		enc_alt,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if got_alt != "hold":
		CombatRegressionHarness._fail(failures, "encounter_doctrine_string: empty canonical should use alt got %s" % got_alt)
	var enc_canon: Dictionary = {
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "probing",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "hold_lane",
	}
	var got_canon: String = CombatConstants.encounter_formation_doctrine_string(
		enc_canon,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if got_canon != "probing":
		CombatRegressionHarness._fail(failures, "encounter_doctrine_string: canonical should win over alt got %s" % got_canon)
	var enc_ws: Dictionary = {CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "  \t  "}
	var got_ws: String = CombatConstants.encounter_formation_doctrine_string(
		enc_ws,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if not got_ws.is_empty():
		CombatRegressionHarness._fail(failures, "encounter_doctrine_string: whitespace-only canonical should fall through to empty got %s" % got_ws)
	var preset_alt_only: Dictionary = {
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "  hold  ",
	}
	var got_preset_alt: String = CombatConstants.formation_doctrine_string_from_dict(
		preset_alt_only,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if got_preset_alt != "hold":
		CombatRegressionHarness._fail(failures, "formation_doctrine_string_from_dict: preset alt-only want hold got %s" % got_preset_alt)
	var preset_both: Dictionary = {
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
	}
	var got_preset_canon: String = CombatConstants.formation_doctrine_string_from_dict(
		preset_both,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if got_preset_canon != "probing":
		CombatRegressionHarness._fail(
			failures,
			"formation_doctrine_string_from_dict: preset canonical should win got %s" % got_preset_canon
		)


## Pair moves cancel any queued `swap_rank_resolve` touching either combatant before scheduling a fresh resolve.
static func run_early(failures: PackedStringArray) -> void:
	_run_depth_polearm(failures)
	_run_depth_polearm_reciprocal_distance_bands(failures)
	_run_depth_polearm_only_file_opposed_line(failures)
	_run_depth_polearm_threatens_line_target_pure_guards(failures)
	_run_depth_polearm_valid_line_threat_false_when_lane_closed(failures)
	_run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(failures)
	_run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures)
	_run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(failures)
	_run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(failures)
	_run_depth_polearm_layout_fuzz(failures)
	_run_front_rank_pair_melee_listed(failures)
	_run_engagement_scenarios(failures)
	_run_opposition_offset_seeded_at_start(failures)
	_run_back_rank_depth_lane_skip_recheck(failures)
	_run_swap_rank_line_plug_weight_when_front_hole(failures)
	_run_same_file_depth_recheck_after_front_turn(failures)
	_run_same_file_depth_recheck_after_rank1_turn(failures)
	_run_windup_abort_same_file_depth_recheck(failures)
	_run_swap_rank_listed_line_plug_when_relief_blocked(failures)
	_run_swap_rank_resolve_line_plug_when_listed(failures)
	_run_swap_rank_depth_recheck_rank2_after_resolve(failures)
	_run_same_file_depth_rank2_plus_scheduler(failures)
	_run_fall_back_solo_demotes_when_rear_slot_empty(failures)
	_run_fall_back_solo_depth_recheck_rank2_after_resolve(failures)
	_run_line_plug_gauge_suffix_when_swap_listed(failures)
	_run_plug_forward_gauge_suffix_when_listed(failures)
	_run_front_gap_line_plug_hint_when_swap_listed(failures)
	_run_skirmish_line_gap_rotate_hint(failures)
	_run_rotate_line_plug_weight_skirmish_rank0_hole(failures)
	_run_plug_forward_incap_partner_hint(failures)
	_run_rotate_file_line_plug_weight_when_front_hole(failures)
	_run_rotate_file_depth_recheck_both_columns(failures)
	_run_skirmish_rotate_gauge_suffix_when_listed(failures)
	_run_geometry_skirmish_wide_line_no_compact(failures)
	_run_skirmish_outnumber_allows_rotate_file(failures)
	_run_envelop_mop_up_active_after_attrition(failures)
	_run_envelop_close_listed_mid_mop_up(failures)
	_run_envelop_close_resolve_mid_mop_up(failures)
	_run_envelop_close_resolve_close_mop_up(failures)
	_run_envelop_focus_ai_weight_damp_mop_up(failures)
	_run_attempt_close_ai_weight_mid_mop_up(failures)
	_run_envelop_mop_up_rotate_suppressed(failures)
	_run_envelop_mop_up_excludes_fled_allies(failures)
	_run_living_hostile_excludes_fled_enemy(failures)
	_run_fled_enemy_distance_to_purged_after_recompute(failures)
	_run_envelop_resolve_rotate_rejected_mop_up(failures)
	_run_envelop_mop_up_inactive_true_duel(failures)
	_run_envelop_close_listed_close_mop_up(failures)
	_run_envelop_melee_strike_listed_close_mop_up_reach_gap(failures)
	_run_pincer_wing_commitment_propagates_from_center(failures)
	_run_pincer_preferred_flank_target_mult(failures)
	_run_posture_mirror_symmetric(failures)
	_run_morale_cohesion_affects_line_cohesion(failures)
	_run_engagement_classifier_multi_seed(failures)
	_run_engagement_active_count_gate_exhaustive(failures)
	_run_engagement_mode_cache_reset_on_second_start(failures)
	_run_engagement_attrition_monotone(failures)
	_run_telemetry_lock_multi_seed(failures)
	_run_depth_polearm_band_vs_actions_fuzz(failures)
	_run_surround_production_path_dampens_defense_vs_compressed_flanks(failures)
	_run_telemetry_invalid_melee_resolve_blocked(failures)
	_run_telemetry_invalid_close_resolve_blocked(failures)
	_run_attempt_close_listed_only_at_long(failures)
	_run_attempt_close_ai_weight_zero_when_not_long(failures)
	_run_close_contest_failed_emits_reason(failures)
	_run_resolve_close_no_emit_when_target_incap(failures)
	_run_parry_deflect_formatter_clash_context_branches(failures)
	_run_parry_partial_formatter_clash_context_branches(failures)
	_run_telemetry_automatic_doctrine_pinch_record(failures)
	_run_combatants_snapshot_formation_doctrine_field(failures)
	_run_parry_pack_flank_effective_spacing(failures)
	_run_surround_sector_load_formula(failures)
	_run_surround_threat_weight_sum_three_file_line(failures)
	_run_surround_defense_multiplier_from_pa_both_paths(failures)
	_run_surround_live_weight_sum_matches_from_pa_sector_path(failures)
	_run_surround_single_threat_int_and_sector_neutral(failures)
	_run_sector_surround_feature_flag_respects_runtime_toggle(failures)
	_run_ai_targeting_posture_cohesion_mult(failures)
	_run_hostile_pair_distributed_pressure_ally_commit(failures)
	_run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures)
	_run_targeting_hold_lane_off_file_mult(failures)
	_run_targeting_file_opposed_mult(failures)
	_run_targeting_pinch_center_inward_bonus(failures)
	_run_targeting_commitment_match_mult(failures)
	_run_targeting_soft_geometry_eff_dist_formula(failures)
	_run_targeting_prune_expired_doctrine_commitment(failures)
	_run_targeting_prune_commitment_when_target_dies(failures)
	_run_targeting_clear_all_state_for_dead_defender(failures)
	_run_ai_targeting_opponent_formation_mult(failures)
	_run_targeting_formation_dict_cache_matches_live(failures)
	_run_ai_targeting_engagement_mode_mult(failures)
	_run_hostile_pair_cached_engagement_mode_matches_live(failures)
	_run_ai_targeting_stance_mult_ordering(failures)

static func run_mid(failures: PackedStringArray) -> void:
	_run_ai_targeting_incap_hostile_mult(failures)
	_run_no_hostile_actions_listed_vs_incap_enemy(failures)
	_run_stalemate_melee_rank1_when_rank0_incap(failures)
	_run_ordered_melee_opponents_file_opposed_sort(failures)
	_run_ordered_melee_opponents_commitment_tiebreak(failures)
	_run_ordered_melee_opponents_actor_zone_cache_parity(failures)
	_run_available_actions_build_double_invoke_parity(failures)
	_run_hostile_pair_opp_zone_cache_parity(failures)
	_run_depth_spear_tight_lane_parry_mult_invariant(failures)

static func run_late(failures: PackedStringArray) -> void:
	_run_depth_spear_thrust_closing_factor_invariant(failures)
	_run_spear_lane_profile_preset_normalized(failures)
	_run_weapon_depth_melee_eligible_fixture(failures)
	_run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures)
	_run_depth_polearm_lane_open_false_at_rank_zero(failures)
	_run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures)
	_run_depth_polearm_lane_cache_matches_builder(failures)
	_run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures)
	_run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures)
	_run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures)
	_run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures)
	_run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures)
	_run_depth_polearm_parts_filter_tracks_allows_low(failures)
	_run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures)
	_run_depth_polearm_restricted_profile_requires_lane_stress_for_allows_low(failures)
	_run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures)
	_run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures)
	_run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures)
	_run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures)
	_run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures)
	_run_depth_polearm_auto_lane_discipline_posture(failures)
	_run_wing_lacks_depth_polearm(failures)
	_run_depth_polearm_doctrine_action_weights(failures)
	_run_depth_polearm_ai_doctrine_mults_encounter_preset(failures)
	_run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures)
	_run_doctrine_hollow_center_pinch_heuristic(failures)
	_run_doctrine_normalize_and_manager_roundtrip(failures)
	_run_encounter_formation_doctrine_on_start(failures)
	_run_encounter_formation_doctrine_string_helper(failures)
