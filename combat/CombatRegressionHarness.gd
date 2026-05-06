class_name CombatRegressionHarness
extends RefCounted

## Manual / editor-invoked checks for Tier 1.5–1.9 (morale cohesion, engagement classifier, depth polearm).
## `incursion_allowed` expectations respect `CombatConstants.FEATURE_LINE_CRASH_INTRUSION`.
## Does not require a running battle scene. Example:
##   var r := CombatRegressionHarness.run_all()
##   assert(r.ok, str(r.failures))

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")

static func run_all() -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	_run_next_action_ready_map_matches_per_id(failures)
	_run_vacancy_reconcile_follow_up_regression(failures)
	_run_vacancy_reconcile_after_front_death(failures)
	_run_depth_polearm(failures)
	_run_depth_polearm_only_file_opposed_line(failures)
	_run_depth_polearm_layout_fuzz(failures)
	_run_front_rank_pair_melee_listed(failures)
	_run_engagement_scenarios(failures)
	_run_posture_mirror_symmetric(failures)
	_run_morale_cohesion_affects_line_cohesion(failures)
	_run_engagement_classifier_multi_seed(failures)
	_run_engagement_attrition_monotone(failures)
	_run_no_crash_actions_when_intrusion_disabled(failures)
	_run_combat_telemetry_crash_blocked(failures)
	return {"ok": failures.is_empty(), "failures": failures}


static func _fail(arr: PackedStringArray, msg: String) -> void:
	arr.append(msg)


## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).
static func _run_next_action_ready_map_matches_per_id(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var cmap: Dictionary = _EventScheduler.build_next_action_ready_times(mgr)
	for c in mgr.combatants:
		if not c.get("alive", true):
			continue
		var cid: int = int(c.id)
		var per: float = _EventScheduler.get_next_action_ready_at(mgr, cid)
		if per < 0.0:
			if cmap.has(cid):
				_fail(failures, "next_ready_map: id=%d no pending event but map has %s" % [cid, str(cmap[cid])])
		else:
			if not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001:
				_fail(
					failures,
					"next_ready_map: id=%d per=%.6f map=%s" % [cid, per, str(cmap.get(cid, "missing"))]
				)
	_free_manager(mgr)


## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.
static func _run_vacancy_reconcile_follow_up_regression(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var clk0: float = float(mgr.combat_clock)
	var q0: int = mgr.event_queue.size()
	var snap0: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, [], snap0, true)
	if float(mgr.combat_clock) != clk0:
		_fail(failures, "vacancy_follow_up: empty changed_fids mutated combat_clock")
	if mgr.event_queue.size() != q0:
		_fail(failures, "vacancy_follow_up: empty changed_fids mutated event_queue size")
	var snap1: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	var ch1: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
	if not ch1.is_empty():
		_fail(
			failures,
			"vacancy_follow_up: expected stable line after start, changed_fids=%s" % str(ch1)
		)
	var q1: int = mgr.event_queue.size()
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch1, snap1, true)
	if mgr.event_queue.size() != q1:
		_fail(failures, "vacancy_follow_up: no-op reconcile follow-up mutated event_queue")
	var cmap: Dictionary = _EventScheduler.build_next_action_ready_times(mgr)
	for c in mgr.combatants:
		if not c.get("alive", true):
			continue
		var cid: int = int(c.id)
		var per: float = _EventScheduler.get_next_action_ready_at(mgr, cid)
		if per >= 0.0 and (not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001):
			_fail(failures, "vacancy_follow_up: map/per mismatch id=%d" % cid)
	_free_manager(mgr)


## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.
static func _run_vacancy_reconcile_after_front_death(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var front_id: int = int(mgr.combatants[0].id)
	_soak_kill_combatant(mgr, front_id)
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
	var living_rank0_player: bool = false
	for c in mgr.combatants:
		if not c.get("alive", false) or str(c.get("side", "")) != "player":
			continue
		if int(c.get("rank", -9)) == 0:
			living_rank0_player = true
			break
	if not living_rank0_player:
		_fail(failures, "vacancy_death: no living player at rank 0 after plug")
	_free_manager(mgr)


static func _new_entity(weapon_id: String) -> CoreEntity:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	var w: Weapon = _Weapon.create_from_definition(weapon_id)
	if w != null:
		e.equip_weapon(w)
	return e


static func _free_manager(mgr: Node) -> void:
	if mgr == null:
		return
	for c in mgr.combatants:
		var n: Variant = c.get("node", null)
		if n is Node:
			(n as Node).queue_free()
	mgr.queue_free()


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
	for i in range(ids.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp


## Tier 1.8 (P9): `TacticalCombat.recompute_incursion_pressure` stores `_tactical_mode_snapshot`; keep it aligned with `CombatEngagementMode`.
static func _assert_tactical_snapshot_matches(
	failures: PackedStringArray,
	mgr: Node,
	ctx: String
) -> void:
	if mgr == null:
		return
	if not mgr.has_meta("_tactical_mode_snapshot"):
		_fail(failures, "%s: missing _tactical_mode_snapshot (run _recompute_zoc_and_distance?)" % ctx)
		return
	var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
	var resolved: String = _EngagementMode.engagement_mode(mgr)
	if str(ts.get("mode", "")) != resolved:
		_fail(failures, "%s: tactical mode=%s vs engagement_mode=%s" % [ctx, ts.get("mode"), resolved])
	var inc: bool = _EngagementMode.incursion_allowed(mgr)
	if bool(ts.get("incursion_allowed", false)) != inc:
		_fail(failures, "%s: tactical incursion_allowed vs CombatEngagementMode mismatch" % ctx)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
	if mgr == null or not mgr.has_method("_get_by_id"):
		return
	var c: Variant = mgr._get_by_id(combatant_id)
	if c == null or typeof(c) != TYPE_DICTIONARY:
		return
	if not c.get("alive", false):
		return
	c["alive"] = false
	mgr._on_combatant_died(c)


## Tier 1.7–1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot stays in sync.
static func _run_engagement_classifier_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 64:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var snap: Dictionary = _EngagementMode.snapshot(mgr)
		var raw: String = str(snap.get("raw_mode", ""))
		if raw == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				_fail(
					failures,
					"classifier_fuzz seed=%d: raw formation but can_enter false snap=%s" % [scenario_seed, str(snap)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "classifier_fuzz seed=%d" % scenario_seed)
		var resolved: String = _EngagementMode.engagement_mode(mgr)
		var resolved_again: String = _EngagementMode.engagement_mode(mgr)
		if resolved_again != resolved:
			_fail(
				failures,
				"classifier_fuzz seed=%d: engagement_mode not idempotent %s vs %s"
				% [scenario_seed, resolved, resolved_again]
			)
		var inc_ok: bool = _EngagementMode.incursion_allowed(mgr)
		var inc_expect: bool = (
			CombatConstants.FEATURE_LINE_CRASH_INTRUSION
			and resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION
		)
		if inc_ok != inc_expect:
			_fail(failures, "classifier_fuzz seed=%d: incursion_allowed vs resolved mismatch" % scenario_seed)
		_free_manager(mgr)


## Tier 1.8 soak: deaths-only path must not return to resolved formation after leaving it (hysteresis / classifier stability).
static func _run_engagement_attrition_monotone(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 32:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(4, 8)
		var en: int = rng.randi_range(4, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var order: Array = []
		for c in mgr.combatants:
			order.append(int(c.get("id", -1)))
		_shuffle_int_array_in_place(order, rng)
		var left_formation: bool = false
		for cid in order:
			var cur: Variant = mgr._get_by_id(int(cid))
			if cur == null or not cur.get("alive", false):
				continue
			_soak_kill_combatant(mgr, int(cid))
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved != CombatConstants.ENGAGEMENT_MODE_FORMATION:
				left_formation = true
			elif left_formation:
				_fail(
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
		_free_manager(mgr)


static func _run_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	# Rank-0 sword, rank-1 spear (same file); one enemy front.
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_polearm: expected open lane (rank-1 spear + rank-0 ally)")
	if _ActionsBuilder.can_melee_threaten(mgr, depth, enemy) != true:
		_fail(failures, "depth_polearm: can_melee_threaten should be true vs file-opposed rank-0")
	var dist: String = str(depth.get("distance_to", {}).get(enemy.get("id", -2), ""))
	if dist == CombatConstants.DISTANCE_LONG:
		_fail(failures, "depth_polearm: distance_to should not be LONG when lane open (got %s)" % dist)
	depth.gauge = 100.0
	var acts: Array = mgr.get_available_actions(int(depth.get("id", -1)))
	var w_depth: Variant = _EntityAccess.get_weapon(depth)
	var atk_ids: Dictionary = {}
	if w_depth != null and w_depth is Weapon:
		atk_ids = (w_depth as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != int(enemy.get("id", -1)):
			continue
		var mid: String = str(a.get("move_id", ""))
		if atk_ids.has(mid):
			has_melee_vs_enemy = true
			break
	if not has_melee_vs_enemy:
		_fail(failures, "depth_polearm: expected weapon strike vs enemy in available actions (had %s)" % str(acts))
	# Non-polearm depth: no extra reach to line.
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en2: Dictionary = mgr2.combatants[2]
	if _ActionsBuilder.can_melee_threaten(mgr2, depth_sw, en2):
		_fail(failures, "depth_polearm: rank-1 sword must not melee-threaten file-opposed rank-0")
	_free_manager(mgr2)
	# Tight density: over-shoulder filter drops legs when lane open.
	mgr.formations["player"]["density"] = "tight"
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt_tight: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		_fail(failures, "depth_polearm: tight lane should filter leg targets (got %s)" % str(filt_tight))
	mgr.formations["player"]["density"] = "loose"
	var filt_loose: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_loose.has("left_leg"):
		_fail(failures, "depth_polearm: loose lane should keep leg targets available")
	_free_manager(mgr)


## Tier 1.9: depth polearm may threaten opposed file + immediate neighbor files (lateral max); not beyond.
static func _run_depth_polearm_only_file_opposed_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_polearm_file: expected open lane")
	if not _ActionsBuilder.can_melee_threaten(mgr, depth, en_f0):
		_fail(failures, "depth_polearm_file: should threaten file-opposed rank-0")
	if not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en_f1):
		_fail(failures, "depth_polearm_file: neighbor file should be in lateral thrust window")
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en_f2):
		_fail(failures, "depth_polearm_file: file+2 beyond DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES must not count as lane target")
	if _ActionsBuilder.can_melee_threaten(mgr, depth, en_f2):
		_fail(failures, "depth_polearm_file: must not melee-threaten rank-0 two files over")
	_free_manager(mgr)


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
			mgr.register(_new_entity("SWORD"), "player")
		for _j in pf:
			mgr.register(_new_entity("SPEAR"), "player")
		for _k in ef:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start(
			{"files": pf, "ranks": 2, "density": "normal"},
			{"files": ef, "ranks": 1, "density": "normal"}
		)
		var fs: int = rng.randi_range(0, pf - 1)
		var depth_idx: int = pf + fs
		if depth_idx >= mgr.combatants.size():
			_fail(failures, "depth_polearm_fuzz seed=%d: bad depth idx" % scenario_seed)
			_free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		var lane_open: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, depth)
		if not lane_open:
			_fail(failures, "depth_polearm_fuzz seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			_free_manager(mgr)
			continue
		var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
		if front.is_empty():
			_fail(failures, "depth_polearm_fuzz seed=%d: missing front ally" % scenario_seed)
			_free_manager(mgr)
			continue
		var ff: int = int(front.get("file", -9))
		for c in mgr.combatants:
			if str(c.get("side", "")) != "enemy" or not c.get("alive", false):
				continue
			if int(c.get("rank", -1)) != 0:
				continue
			var lat: int = absi(int(c.get("file", 0)) - ff)
			var geo_ok: bool = lat <= max_lat
			var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
			if vlt != geo_ok:
				_fail(
					failures,
					(
						"depth_polearm_fuzz seed=%d: valid_line_threat=%s vs geo_ok=%s "
						+ "pf=%d ef=%d depth_file=%d opp_file=%d lat=%d"
					)
					% [scenario_seed, vlt, geo_ok, pf, ef, depth.get("file", -1), c.get("file", -1), lat]
				)
		_free_manager(mgr)


## Front-rank sword vs sword: CLOSE or MID must list real strikes (MID uses geometric reach, not only REACH_MID_MIN).
static func _run_front_rank_pair_melee_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var dist: String = str(p.get("distance_to", {}).get(e.get("id", -2), ""))
	if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
		_free_manager(mgr)
		return
	p.gauge = 100.0
	var acts: Array = mgr.get_available_actions(int(p.get("id", -1)))
	var w_p: Variant = _EntityAccess.get_weapon(p)
	var atk_ids: Dictionary = {}
	if w_p != null and w_p is Weapon:
		atk_ids = (w_p as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != int(e.get("id", -1)):
			continue
		var mid: String = str(a.get("move_id", ""))
		if atk_ids.has(mid):
			has_melee_vs_enemy = true
			break
	if not has_melee_vs_enemy:
		_fail(
			failures,
			"front_rank_pair: expected weapon strike vs enemy at band %s (acts=%s)" % [dist, str(acts)]
		)
	_free_manager(mgr)


static func _run_engagement_scenarios(failures: PackedStringArray) -> void:
	# 1v1 → duel classifier
	var d: Node = _MgrScript.new()
	d.register(_new_entity("SWORD"), "player")
	d.register(_new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var s1: Dictionary = _EngagementMode.snapshot(d)
	if str(s1.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(failures, "engagement: 1v1 expected raw duel, got %s" % str(s1.get("raw_mode", "")))
	if _EngagementMode.incursion_allowed(d):
		_fail(failures, "engagement: incursion must be disallowed in duel")
	_free_manager(d)
	# 4v4 two-wide line → formation-classifier band (Option 2 minimums)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(_new_entity("SWORD"), "player")
	for _j in 4:
		f.register(_new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var s4: Dictionary = _EngagementMode.snapshot(f)
	if str(s4.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(
			failures,
			"engagement: 4v4 two-file line expected raw formation, got %s snap=%s"
			% [str(s4.get("raw_mode", "")), str(s4)]
		)
	var mode_f: String = _EngagementMode.engagement_mode(f)
	var inc_expect_f: bool = (
		CombatConstants.FEATURE_LINE_CRASH_INTRUSION
		and mode_f == CombatConstants.ENGAGEMENT_MODE_FORMATION
	)
	if _EngagementMode.incursion_allowed(f) != inc_expect_f:
		_fail(
			failures,
			"engagement: incursion_allowed=%s expected %s (FEATURE_LINE_CRASH_INTRUSION=%s mode=%s)"
			% [
				_EngagementMode.incursion_allowed(f),
				inc_expect_f,
				CombatConstants.FEATURE_LINE_CRASH_INTRUSION,
				mode_f
			]
		)
	_free_manager(f)


## Tier 1.4: mirrored line → same cohesion → same `engagement_posture` (two-pass recompute + coupling neutral when equal).
static func _run_posture_mirror_symmetric(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var fp: String = str(mgr.formations["player"].get("engagement_posture", ""))
	var fe: String = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp.is_empty() or fe.is_empty():
		_fail(failures, "posture_mirror: missing posture player=%s enemy=%s" % [fp, fe])
	elif fp != fe:
		_fail(failures, "posture_mirror: symmetric presets expected same posture got %s vs %s" % [fp, fe])
	_FormationEngagement.recompute_all(mgr)
	fp = str(mgr.formations["player"].get("engagement_posture", ""))
	fe = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp != fe:
		_fail(failures, "posture_mirror: after recompute_all expected same posture got %s vs %s" % [fp, fe])
	_free_manager(mgr)


## Tier 1.5: encounter `morale_cohesion_*` lowers `line_cohesion` vs default factor 1.0.
static func _run_morale_cohesion_affects_line_cohesion(failures: PackedStringArray) -> void:
	var m_base: Node = _MgrScript.new()
	m_base.register(_new_entity("SWORD"), "player")
	m_base.register(_new_entity("SWORD"), "enemy")
	m_base.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_base: float = float(m_base.formations["player"].get("line_cohesion", 1.0))
	var m_low: Node = _MgrScript.new()
	m_low.register(_new_entity("SWORD"), "player")
	m_low.register(_new_entity("SWORD"), "enemy")
	m_low.encounter[CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER] = 0.35
	m_low.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_low: float = float(m_low.formations["player"].get("line_cohesion", 1.0))
	if coh_low >= coh_base - 0.001:
		_fail(
			failures,
			"morale_cohesion: expected lower player line_cohesion with low morale (base=%.4f low=%.4f)"
			% [coh_base, coh_low]
		)
	var m_agg: Node = _MgrScript.new()
	m_agg.register(_new_entity("SWORD"), "player")
	m_agg.register(_new_entity("SWORD"), "player")
	m_agg.register(_new_entity("SWORD"), "enemy")
	m_agg.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var coh_agg_hi: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	m_agg.combatants[0]["morale_cohesion"] = 0.2
	m_agg.combatants[1]["morale_cohesion"] = 0.2
	_FormationEngagement.recompute_all(m_agg)
	var coh_agg_lo: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	if coh_agg_lo >= coh_agg_hi - 0.001:
		_fail(
			failures,
			"morale_cohesion: combatant mean should drop cohesion (hi=%.4f lo=%.4f)" % [coh_agg_hi, coh_agg_lo]
		)
	_free_manager(m_base)
	_free_manager(m_low)
	_free_manager(m_agg)


## Tier 1.8: no crash breach action in lists while `FEATURE_LINE_CRASH_INTRUSION` is false.
static func _run_no_crash_actions_when_intrusion_disabled(failures: PackedStringArray) -> void:
	if CombatConstants.FEATURE_LINE_CRASH_INTRUSION:
		return
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	for c in mgr.combatants:
		if not c.get("alive", false):
			continue
		c.gauge = 100.0
		var acts: Array = mgr.get_available_actions(int(c.get("id", -1)))
		for a in acts:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				_fail(
					failures,
					"no_crash_when_disabled: crash listed for id=%d" % int(c.get("id", -1))
				)
				break
	_free_manager(mgr)


## Tier 1.8 telemetry: illegal crash resolve increments counter (intrusion disabled or wrong mode).
static func _run_combat_telemetry_crash_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = int(mgr.combatants[0].id)
	var e_id: int = int(mgr.combatants[1].id)
	_EngagementResolver.resolve_crash_attempt(mgr, p_id, e_id)
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_crash: missing telemetry meta after blocked crash")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_crash_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_crash: expected invalid_crash_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)
