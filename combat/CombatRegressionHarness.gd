class_name CombatRegressionHarness
extends RefCounted

## Manual / editor-invoked checks for Tier 1.5–1.9 (morale cohesion, engagement classifier, depth polearm, ZoC intruder zones).
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
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _IntrusionGeometry := preload("res://combat/CombatIntrusionGeometry.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _DefenseResolution := preload("res://combat/DefenseResolutionHandler.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
## Tier 3.2: full-stop **`parry_deflect`** — keys on **`parry_clash_context`** (see **`DefenseResolutionHandler`**) incl. Tier **3.0** strike kinematics + Tier **3.1** **`strike_measure_ratio`** (from **`pa`** when stamped, else **-1**); harness schema lock in **`_run_parry_clash_context_calibration_fields`**. **`parry_partial`** adds the same key set plus **`remaining_ratio`** / **`geometric_leak`** (**`_run_parry_partial_clash_context_calibration_fields`**); Tier **3.0** KE on partial uses reduced **`pa["velocity_m_s"]`**; **`CombatLogFormatter`** + harness **`_run_parry_partial_formatter_clash_context_branches`** (**`rem=`** when calibration **on**); **`_run_action_resolved_parry_partial_payload_includes_clash_context`** locks first **`action_resolved`** emit; **`_run_hit_clears_attacker_parry_calibration_fields`** locks **`hit`** erase of calibration carry; **`_run_parry_partial_bind_riposte_flags_when_aligned`** locks defender bind-riposte flags vs alignment + **`parry_control`** (misaligned **`erase`** vs aligned explicit **false**, stale-bind seed).
const PARRY_CLASH_CONTEXT_KEYS_FULL_STOP: Array[String] = [
	"archetype_id",
	"parry_control",
	"parry_p_a",
	"parry_c_d",
	"c_d_final",
	"m_a_parry",
	"m_d_parry",
	"m_a_velocity",
	"margin_ratio",
	"alignment",
	"defender_guard_line",
	"guard_angle_deg",
	"parry_time_to_react",
	"parry_readiness",
	"late_parry",
	"parry_off_balance",
	"is_block_parry",
	"attack_type",
	"contact_type",
	"effective_attack_line",
	"severity",
	"attack_angle_deg",
	"kinematic_delivery",
	"strike_velocity_m_s",
	"strike_kinetic_energy_j",
	"strike_measure_ratio",
]

static func run_all() -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	_run_next_action_ready_map_matches_per_id(failures)
	_run_vacancy_reconcile_follow_up_regression(failures)
	_run_vacancy_reconcile_after_front_death(failures)
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
	_run_posture_mirror_symmetric(failures)
	_run_morale_cohesion_affects_line_cohesion(failures)
	_run_crash_ai_cohesion_weight_monotone(failures)
	_run_engagement_classifier_multi_seed(failures)
	_run_engagement_active_count_gate_exhaustive(failures)
	_run_engagement_mode_cache_reset_on_second_start(failures)
	_run_engagement_attrition_monotone(failures)
	_run_telemetry_lock_multi_seed(failures)
	_run_depth_polearm_band_vs_actions_fuzz(failures)
	_run_no_crash_actions_when_intrusion_disabled(failures)
	_run_combat_telemetry_crash_blocked(failures)
	_run_telemetry_invalid_melee_resolve_blocked(failures)
	_run_telemetry_invalid_close_resolve_blocked(failures)
	_run_close_contest_failed_emits_reason(failures)
	_run_resolve_close_no_emit_when_target_incap(failures)
	_run_resolve_crash_no_emit_when_target_incap(failures)
	_run_crash_failed_formatter_reason_branches(failures)
	_run_parry_deflect_formatter_clash_context_branches(failures)
	_run_parry_partial_formatter_clash_context_branches(failures)
	_run_telemetry_automatic_doctrine_pinch_record(failures)
	_run_combatants_snapshot_formation_doctrine_field(failures)
	_run_parry_pack_flank_effective_spacing(failures)
	_run_intruder_zone_id_uses_host_grid(failures)
	_run_zoc_count_alive_includes_intruder_on_host(failures)
	_run_crash_neighbor_hold_uses_host_line_for_intruder(failures)
	_run_reschedule_back_rank_includes_intruder_on_host(failures)
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
	_run_ai_targeting_breach_file_mult(failures)
	_run_targeting_formation_dict_cache_matches_live(failures)
	_run_ai_targeting_engagement_mode_mult(failures)
	_run_hostile_pair_cached_engagement_mode_matches_live(failures)
	_run_ai_targeting_stance_mult_ordering(failures)
	_run_ai_targeting_incap_hostile_mult(failures)
	_run_no_hostile_actions_listed_vs_incap_enemy(failures)
	_run_stalemate_melee_rank1_when_rank0_incap(failures)
	_run_ordered_melee_opponents_file_opposed_sort(failures)
	_run_ordered_melee_opponents_commitment_tiebreak(failures)
	_run_depth_spear_tight_lane_parry_mult_invariant(failures)
	_run_windup_pending_attack_pair_geometry(failures)
	_run_strike_measure_constants_sanity(failures)
	_run_attack_result_applier_terminal_clears_pending(failures)
	_run_action_resolved_parry_deflect_payload_includes_clash_context(failures)
	_run_action_resolved_parry_partial_payload_includes_clash_context(failures)
	_run_hit_clears_attacker_parry_calibration_fields(failures)
	_run_parry_partial_bind_riposte_flags_when_aligned(failures)
	_run_depth_spear_thrust_closing_factor_invariant(failures)
	_run_spear_lane_profile_preset_normalized(failures)
	_run_weapon_depth_melee_eligible_fixture(failures)
	_run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures)
	_run_depth_polearm_lane_open_false_when_intruded(failures)
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
	_run_depth_polearm_restricted_profile_requires_wedge_for_allows_low(failures)
	_run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures)
	_run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures)
	_run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures)
	_run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures)
	_run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures)
	_run_depth_polearm_auto_lane_discipline_posture(failures)
	_run_wing_lacks_depth_polearm(failures)
	_run_depth_polearm_doctrine_action_weights(failures)
	_run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures)
	_run_doctrine_hollow_center_pinch_heuristic(failures)
	_run_doctrine_hollow_center_intruder_fills_center(failures)
	_run_doctrine_normalize_and_manager_roundtrip(failures)
	_run_encounter_formation_doctrine_on_start(failures)
	_run_encounter_formation_doctrine_string_helper(failures)
	_run_intruder_death_obstacle_on_host_formation(failures)
	_run_intruded_skips_start_pair_move(failures)
	_run_cancel_stale_swap_rank_resolve_events(failures)
	_run_parry_preserves_formation_pair_state(failures)
	_run_swap_rank_resolve_completes_rank_swap(failures)
	_run_negligible_hit_recovery_shorter_than_counted_hit(failures)
	_run_combat_log_formatter_negligible(failures)
	_run_weapon_part_mass_model_normalized(failures)
	_run_weapon_parry_part_selection_fallbacks(failures)
	_run_weapon_striking_part_mass_model(failures)
	_run_weapon_blade_strong_fraction(failures)
	_run_bind_riposte_contact_types_normalized(failures)
	_run_bind_riposte_contact_multipliers(failures)
	_run_parry_opposite_deflect_thresholds(failures)
	_run_parry_defender_vs_attack_modifiers(failures)
	_run_parry_clash_context_calibration_fields(failures)
	_run_parry_partial_clash_context_calibration_fields(failures)
	_run_parry_control_bind_deflect_formula(failures)
	_run_guard_line_deflected_severity_from_margin_ratio(failures)
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
		if not _EntityAccess.alive_bool(c, true):
			continue
		var cid: int = _EntityAccess.id_int(c)
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
		if not _EntityAccess.alive_bool(c, true):
			continue
		var cid: int = _EntityAccess.id_int(c)
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
	var front_id: int = _EntityAccess.id_int(mgr.combatants[0])
	_soak_kill_combatant(mgr, front_id)
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
	var living_rank0_player: bool = false
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.rank_int(c, -9) == 0:
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
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.queue_free()
	mgr.queue_free()


static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity(weapon_id), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	if bind:
		p["parry_was_bind"] = true
		p["parry_against_id"] = e_id
	seed(90210)
	_WindUpStarter.start(mgr, p_id, e_id, move_id)
	var dur: float = float(p.get("state_duration", 0.0))
	_free_manager(mgr)
	return dur


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
	if not _EntityAccess.alive_bool(c):
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
		if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				_fail(
					failures,
					"classifier_fuzz seed=%d: cold resolved formation but can_enter false snap=%s"
					% [scenario_seed, str(snap)]
				)
		_free_manager(mgr)


## Tier 1.7 (P8): Option 2 active-count floor — if either side has fewer actives than formation minimum, raw mode is never `formation`.
static func _run_engagement_active_count_gate_exhaustive(failures: PackedStringArray) -> void:
	var min_act: int = int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
	for pn in range(1, 8):
		for en in range(1, 8):
			if pn >= min_act and en >= min_act:
				continue
			var mgr: Node = _MgrScript.new()
			for _i in pn:
				mgr.register(_new_entity("SWORD"), "player")
			for _j in en:
				mgr.register(_new_entity("SWORD"), "enemy")
			mgr.start({}, {})
			var snap: Dictionary = _EngagementMode.snapshot(mgr)
			if str(snap.get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				_fail(
					failures,
					"active_gate: raw formation with active below min pn=%d en=%d snap=%s" % [pn, en, str(snap)]
				)
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				_fail(
					failures,
					"active_gate: resolved formation with active below min pn=%d en=%d snap=%s"
					% [pn, en, str(snap)]
				)
			_free_manager(mgr)


## Tier 1.7 (P8): second `start()` on same manager must not keep prior `formation` hysteresis (regression guard for `clear_resolved_mode_cache`).
static func _run_engagement_mode_cache_reset_on_second_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var m0: String = _EngagementMode.engagement_mode(mgr)
	if m0 != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(failures, "mode_cache_reset: expected first start formation-line mode got %s" % m0)
	# Rebuild as tiny duel on the **same** manager node.
	for c in mgr.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.queue_free()
	mgr.combatants.clear()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var m1: String = _EngagementMode.engagement_mode(mgr)
	if m1 != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(
			failures,
			"mode_cache_reset: after 1v1 restart expected duel got %s (stale formation cache?)" % m1
		)
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
			order.append(_EntityAccess.id_int(c))
		_shuffle_int_array_in_place(order, rng)
		var left_formation: bool = false
		for cid in order:
			var cur: Variant = mgr._get_by_id(int(cid))
			if cur == null or not _EntityAccess.alive_bool(cur):
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


## Tier 1.8 (P9): telemetry meta + embedded snapshot agree with resolved mode; no spurious transitions on cold start.
static func _run_telemetry_lock_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
			_fail(failures, "telemetry_lock seed=%d: missing combat telemetry meta" % scenario_seed)
		else:
			var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
			var mode: String = _EngagementMode.engagement_mode(mgr)
			if str(tel.get("last_resolved_mode", "")) != mode:
				_fail(
					failures,
					"telemetry_lock seed=%d: tel.last_resolved_mode=%s vs engagement_mode=%s"
					% [scenario_seed, tel.get("last_resolved_mode"), mode]
				)
			if int(tel.get("engagement_mode_transitions", -1)) != 0:
				_fail(
					failures,
					"telemetry_lock seed=%d: expected 0 mode transitions on cold start got %s"
					% [scenario_seed, str(tel.get("engagement_mode_transitions"))]
				)
			if (
				not tel.has("invalid_melee_resolve_blocked")
				or not tel.has("invalid_crash_resolve_blocked")
				or not tel.has("invalid_close_resolve_blocked")
			):
				_fail(
					failures,
					"telemetry_lock seed=%d: tel missing invalid_* keys (got keys=%s)"
					% [scenario_seed, str(tel.keys())]
				)
			if (
				int(tel.get("invalid_melee_resolve_blocked", -1)) != 0
				or int(tel.get("invalid_crash_resolve_blocked", -1)) != 0
				or int(tel.get("invalid_close_resolve_blocked", -1)) != 0
			):
				_fail(
					failures,
					"telemetry_lock seed=%d: expected 0 invalid melee/crash/close on cold start tel=%s"
					% [scenario_seed, str(tel)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "telemetry_lock seed=%d" % scenario_seed)
		if mgr.has_meta("_tactical_mode_snapshot"):
			var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
			if not ts.has("telemetry"):
				_fail(failures, "telemetry_lock seed=%d: _tactical_mode_snapshot missing telemetry" % scenario_seed)
			else:
				var emb: Dictionary = ts["telemetry"] as Dictionary
				var mode2: String = _EngagementMode.engagement_mode(mgr)
				if str(emb.get("last_resolved_mode", "")) != mode2:
					_fail(
						failures,
						"telemetry_lock seed=%d: snapshot.telemetry last_resolved_mode mismatch" % scenario_seed
					)
				if (
					not emb.has("invalid_melee_resolve_blocked")
					or not emb.has("invalid_crash_resolve_blocked")
					or not emb.has("invalid_close_resolve_blocked")
				):
					_fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry missing invalid_* keys" % scenario_seed
					)
				if (
					int(emb.get("invalid_melee_resolve_blocked", -1)) != 0
					or int(emb.get("invalid_crash_resolve_blocked", -1)) != 0
					or int(emb.get("invalid_close_resolve_blocked", -1)) != 0
				):
					_fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry expected 0 invalid counters got %s"
						% [scenario_seed, str(emb)]
					)
		_free_manager(mgr)


## Tier 1.9 (P10) multi-seed: `can_melee_threaten` implies MID/CLOSE band and a listed weapon strike vs that rank-0 enemy.
static func _run_depth_polearm_band_vs_actions_fuzz(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
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
			_fail(failures, "depth_polearm_band_acts seed=%d: bad depth idx" % scenario_seed)
			_free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
			_fail(failures, "depth_polearm_band_acts seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			_free_manager(mgr)
			continue
		depth["gauge"] = 100.0
		var w_depth: Variant = _EntityAccess.get_weapon(depth)
		var atk_ids: Dictionary = {}
		if w_depth != null and w_depth is Weapon:
			atk_ids = (w_depth as Weapon).attack_types
		for c in mgr.combatants:
			if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			if not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c):
				continue
			if not _ActionsBuilder.can_melee_threaten(mgr, depth, c):
				continue
			var dist: String = str(
				_EntityAccess.nested_dictionary_read(depth, "distance_to").get(_EntityAccess.id_int(c, -2), "")
			)
			if dist == CombatConstants.DISTANCE_LONG:
				_fail(
					failures,
					"depth_polearm_band_acts seed=%d: threaten true but distance LONG vs id=%s"
					% [scenario_seed, str(_EntityAccess.id_int(c))]
				)
				continue
			if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
				_fail(
					failures,
					"depth_polearm_band_acts seed=%d: expected CLOSE/MID vs id=%s got %s"
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist]
				)
				continue
			var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
			var has_melee_vs: bool = false
			for a in acts:
				if int(a.get("target_id", -9)) != _EntityAccess.id_int(c):
					continue
				var mid: String = str(a.get("move_id", ""))
				if atk_ids.has(mid):
					has_melee_vs = true
					break
			if not has_melee_vs:
				_fail(
					failures,
					(
						"depth_polearm_band_acts seed=%d: threaten true but no weapon strike vs id=%s dist=%s acts=%s"
					)
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist, str(acts)]
				)
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
	var dist: String = str(_EntityAccess.nested_dictionary_read(depth, "distance_to").get(_EntityAccess.id_int(enemy, -2), ""))
	if dist == CombatConstants.DISTANCE_LONG:
		_fail(failures, "depth_polearm: distance_to should not be LONG when lane open (got %s)" % dist)
	depth.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
	var w_depth: Variant = _EntityAccess.get_weapon(depth)
	var atk_ids: Dictionary = {}
	if w_depth != null and w_depth is Weapon:
		atk_ids = (w_depth as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != _EntityAccess.id_int(enemy):
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
	# Tight density: over-shoulder filter drops legs when lane open (pin strict — duel/open posture alone opens lows per Tier 1.9).
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt_tight: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		_fail(failures, "depth_polearm: tight lane should filter leg targets (got %s)" % str(filt_tight))
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	var filt_wedge_gap: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_wedge_gap.has("left_leg") and not filt_wedge_gap.has("right_leg"):
		_fail(
			failures,
			"depth_polearm: intrusion wedge at file should open low targets in tight lane (got %s)" % str(filt_wedge_gap)
		)
	mgr.formations["player"]["density"] = "loose"
	var filt_loose: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_loose.has("left_leg"):
		_fail(failures, "depth_polearm: loose lane should keep leg targets available")
	# Optional `spear_lane_profile` on formation (Tier 1.9): open on tight without wedge; restricted on loose without wedge.
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var filt_prof_open: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_prof_open.has("left_leg"):
		_fail(
			failures,
			"depth_polearm: spear_lane_profile open + tight should allow leg targets (got %s)" % str(filt_prof_open)
		)
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	var filt_prof_rest: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_prof_rest.has("left_leg") or filt_prof_rest.has("right_leg"):
		_fail(
			failures,
			"depth_polearm: spear_lane_profile restricted + loose should filter legs without wedge (got %s)"
			% str(filt_prof_rest)
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	_free_manager(mgr)


## Tier 1.9: reciprocal bands — rank-0 defender is not stuck at LONG vs an enemy depth spear when spear→defender is MID/CLOSE.
static func _run_depth_polearm_reciprocal_distance_bands(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var player: Dictionary = mgr.combatants[0]
	var en_depth: Dictionary = mgr.combatants[2]
	var pid: int = _EntityAccess.id_int(player)
	var did: int = _EntityAccess.id_int(en_depth)
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, en_depth):
		_fail(failures, "depth_polearm_recip: expected enemy depth spear lane open")
	if not _ActionsBuilder.can_melee_threaten(mgr, en_depth, player):
		_fail(failures, "depth_polearm_recip: enemy spear should melee-threaten player rank-0")
	var d_depth_to_p: String = str(_EntityAccess.nested_dictionary_read(en_depth, "distance_to").get(pid, ""))
	var d_p_to_depth: String = str(_EntityAccess.nested_dictionary_read(player, "distance_to").get(did, ""))
	if d_depth_to_p == CombatConstants.DISTANCE_LONG:
		_fail(failures, "depth_polearm_recip: spear→player band unexpected LONG (got %s)" % d_depth_to_p)
	if d_p_to_depth == CombatConstants.DISTANCE_LONG:
		_fail(
			failures,
			"depth_polearm_recip: player→spear should not be LONG when spear threatens (player=%s spear=%s)"
			% [d_p_to_depth, d_depth_to_p]
		)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var pl2: Dictionary = mgr2.combatants[0]
	var en_deep_sword: Dictionary = mgr2.combatants[2]
	var eid2: int = _EntityAccess.id_int(en_deep_sword)
	if _ActionsBuilder.depth_polearm_lane_open(mgr2, en_deep_sword):
		_fail(failures, "depth_polearm_recip: rank-1 sword must not have open polearm lane")
	var band_r0_to_r1: String = str(_EntityAccess.nested_dictionary_read(pl2, "distance_to").get(eid2, ""))
	if band_r0_to_r1 != CombatConstants.DISTANCE_LONG:
		_fail(
			failures,
			"depth_polearm_recip: rank-1 non-polearm should stay LONG from rank-0 (got %s)" % band_r0_to_r1
		)
	_free_manager(mgr2)
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


## Tier 1.9: **`depth_polearm_threatens_line_target`** pure guards (no manager): empty ally/opp, rank≠0, same side, dead, **`abs(Δfile)`** vs **`DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES`**.
static func _run_depth_polearm_threatens_line_target_pure_guards(failures: PackedStringArray) -> void:
	var front: Dictionary = {"rank": 0, "file": 1, "side": "player", "alive": true}
	var opp_line: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target({}, opp_line):
		_fail(failures, "threatens_pure: empty front ally → false")
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, {}):
		_fail(failures, "threatens_pure: empty opp → false")
	var ally_same: Dictionary = {"rank": 0, "file": 2, "side": "player", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, ally_same):
		_fail(failures, "threatens_pure: same-side rank-0 → false")
	var opp_deep: Dictionary = {"rank": 1, "file": 1, "side": "enemy", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_deep):
		_fail(failures, "threatens_pure: enemy rank≠0 → false")
	var opp_dead: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": false}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_dead):
		_fail(failures, "threatens_pure: dead enemy → false")
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_line):
		_fail(failures, "threatens_pure: file-opposed same file → true")
	var opp_near: Dictionary = {"rank": 0, "file": 2, "side": "enemy", "alive": true}
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_near):
		_fail(failures, "threatens_pure: neighbor within lateral max → true")
	var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
	var opp_beyond: Dictionary = {
		"rank": 0,
		"file": 1 + max_lat + 1,
		"side": "enemy",
		"alive": true
	}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_beyond):
		_fail(failures, "threatens_pure: beyond lateral max → false")


## Tier 1.9: **`depth_polearm_valid_line_threat`** is **false** when **`depth_polearm_lane_open`** is **false**, even if **`depth_polearm_threatens_line_target`** (same-file rank-0 vs enemy rank-0) is **true**.
static func _run_depth_polearm_valid_line_threat_false_when_lane_closed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	var en: Dictionary = mgr.combatants[2]
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "valid_lt_lane: rank-1 sword should not open depth polearm lane")
		_free_manager(mgr)
		return
	var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		_fail(failures, "valid_lt_lane: missing same-file rank-0 ally")
		_free_manager(mgr)
		return
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, en):
		_fail(failures, "valid_lt_lane: expected geometric line threat rank-0 vs rank-0 same column")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en):
		_fail(failures, "valid_lt_lane: closed lane must force valid_line_threat false")
	_free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_valid_line_threat(manager, depth, opp)`** equals **`depth_polearm_threatens_line_target(same_file_living_rank0_ally, opp)`** ( **`depth_polearm_valid_line_threat`** implementation path).
static func _run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "valid_lt_agree: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		_fail(failures, "valid_lt_agree: missing same-file rank-0 ally")
		_free_manager(mgr)
		return
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		var thr: bool = _ActionsBuilder.depth_polearm_threatens_line_target(front, c)
		if vlt != thr:
			_fail(
				failures,
				"valid_lt_agree: id=%d rank=%d valid=%s threatens=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(vlt), str(thr)]
			)
	_free_manager(mgr)


## Tier 1.9: **`_opp_matches_melee_rank_target(..., 0)`** (depth polearm branch in **`build`**) matches **`depth_polearm_valid_line_threat`** vs every living enemy on a **3-wide** opposing front (no host intruders — listing gate stays aligned with **`valid_line_threat`**).
static func _run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "opp_match_vlt: expected open depth polearm lane")
		_free_manager(mgr)
		return
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var om: bool = _ActionsBuilder._opp_matches_melee_rank_target(mgr, depth, c, 0)
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		if om != vlt:
			_fail(
				failures,
				"opp_match_vlt: id=%d rank=%d om=%s vlt=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(om), str(vlt)]
			)
	_free_manager(mgr)


## Tier 1.9: **`_melee_pair_rank_allowed`** home-depth vs enemy rank-0 uses **`depth_polearm_valid_line_threat`** — open **3-wide** + closed-lane **SWORD** depth fixtures match **`valid_line_threat`** per living enemy.
static func _run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr_open: Node = _MgrScript.new()
	mgr_open.register(_new_entity("SWORD"), "player")
	mgr_open.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_open.register(_new_entity("SWORD"), "enemy")
	mgr_open.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_open._recompute_zoc_and_distance()
	var depth_open: Dictionary = mgr_open.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_open, depth_open):
		_fail(failures, "mpra_vlt: open fixture expected depth polearm lane")
		_free_manager(mgr_open)
		return
	for c in mgr_open.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var pr: bool = _ActionsBuilder._melee_pair_rank_allowed(mgr_open, depth_open, c)
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr_open, depth_open, c)
		if pr != vlt:
			_fail(
				failures,
				"mpra_vlt open: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr), str(vlt)]
			)
	_free_manager(mgr_open)
	var mgr_closed: Node = _MgrScript.new()
	mgr_closed.register(_new_entity("SWORD"), "player")
	mgr_closed.register(_new_entity("SWORD"), "player")
	mgr_closed.register(_new_entity("SWORD"), "enemy")
	mgr_closed.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr_closed._recompute_zoc_and_distance()
	var depth_closed: Dictionary = mgr_closed.combatants[1]
	if _ActionsBuilder.depth_polearm_lane_open(mgr_closed, depth_closed):
		_fail(failures, "mpra_vlt: closed fixture expected lane closed")
		_free_manager(mgr_closed)
		return
	for c in mgr_closed.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var pr2: bool = _ActionsBuilder._melee_pair_rank_allowed(mgr_closed, depth_closed, c)
		var vlt2: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr_closed, depth_closed, c)
		if pr2 != vlt2:
			_fail(
				failures,
				"mpra_vlt closed: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr2), str(vlt2)]
			)
	_free_manager(mgr_closed)


## Tier 1.9: **`can_melee_threaten`** never **true** vs a **home-line** enemy rank 0 unless **`depth_polearm_valid_line_threat`** (open **3-wide** + closed-lane control).
static func _run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "cm_vlt: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var host_fid: String = _EntityAccess.formation_id_str(depth)
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _ZoneOfControl.intruder_on_host_formation(c, host_fid):
			continue
		if (
			_ActionsBuilder.can_melee_threaten(mgr, depth, c)
			and not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		):
			_fail(failures, "cm_vlt: can_melee_threaten without valid_line id=%d" % _EntityAccess.id_int(c))
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr2._recompute_zoc_and_distance()
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en: Dictionary = mgr2.combatants[2]
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr2, depth_sw, en):
		_fail(failures, "cm_vlt: closed lane expected valid_line false")
		_free_manager(mgr2)
		return
	if _ActionsBuilder.can_melee_threaten(mgr2, depth_sw, en):
		_fail(failures, "cm_vlt: closed lane rank-1 sword must not can_melee_threaten rank-0 enemy")
	_free_manager(mgr2)


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
		var ff: int = _EntityAccess.file_int(front, -9)
		for c in mgr.combatants:
			if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			var lat: int = absi(_EntityAccess.file_int(c) - ff)
			var geo_ok: bool = lat <= max_lat
			var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
			if vlt != geo_ok:
				_fail(
					failures,
					(
						"depth_polearm_fuzz seed=%d: valid_line_threat=%s vs geo_ok=%s "
						+ "pf=%d ef=%d depth_file=%d opp_file=%d lat=%d"
					)
					% [scenario_seed, vlt, geo_ok, pf, ef, _EntityAccess.file_int(depth, -1), _EntityAccess.file_int(c, -1), lat]
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
	var dist: String = str(_EntityAccess.nested_dictionary_read(p, "distance_to").get(_EntityAccess.id_int(e, -2), ""))
	if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
		_free_manager(mgr)
		return
	p.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(p))
	var w_p: Variant = _EntityAccess.get_weapon(p)
	var atk_ids: Dictionary = {}
	if w_p != null and w_p is Weapon:
		atk_ids = (w_p as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != _EntityAccess.id_int(e):
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


## Tier 1.6 (P7): crash AI multiplier increases with formation `line_cohesion` (same combatant, synthetic cohesion values).
static func _run_crash_ai_cohesion_weight_monotone(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var c: Dictionary = mgr.combatants[0]
	mgr.formations["player"]["line_cohesion"] = 0.12
	var w_lo: float = _AIPicker.crash_line_cohesion_weight_mult(mgr, c)
	mgr.formations["player"]["line_cohesion"] = 0.96
	var w_hi: float = _AIPicker.crash_line_cohesion_weight_mult(mgr, c)
	if w_lo + 0.0001 >= w_hi:
		_fail(
			failures,
			"crash_ai_cohesion: expected higher mult at high line_cohesion (lo=%.4f hi=%.4f)" % [w_lo, w_hi]
		)
	_free_manager(mgr)


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
		if not _EntityAccess.alive_bool(c):
			continue
		c.gauge = 100.0
		var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(c))
		for a in acts:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				_fail(
					failures,
					"no_crash_when_disabled: crash listed for id=%d" % _EntityAccess.id_int(c)
				)
				break
	_free_manager(mgr)


## Tier 1.9 auto profile: `line_discipline` / `engagement_posture` steer over-shoulder vs open when `spear_lane_profile` is auto.
static func _run_depth_polearm_auto_lane_discipline_posture(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "tight"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_strict.has("left_leg") or f_strict.has("right_leg"):
		_fail(failures, "depth_auto_lane: strict discipline + tight should filter legs (got %s)" % str(f_strict))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	var f_loose_disc: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_loose_disc.has("left_leg"):
		_fail(failures, "depth_auto_lane: loose discipline + tight should allow legs (got %s)" % str(f_loose_disc))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_loose_dens_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_loose_dens_strict.has("left_leg") or f_loose_dens_strict.has("right_leg"):
		_fail(
			failures,
			"depth_auto_lane: strict should override loose density for legs (got %s)" % str(f_loose_dens_strict)
		)
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var f_open_post: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_open_post.has("left_leg"):
		_fail(failures, "depth_auto_lane: OPEN posture + tight should allow legs (got %s)" % str(f_open_post))
	# Empty formation field falls back to encounter discipline (same as posture / fall-back policy).
	mgr.formations["player"]["line_discipline"] = ""
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE] = CombatConstants.LINE_DISCIPLINE_STRICT
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	var f_enc_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_enc_strict.has("left_leg") or f_enc_strict.has("right_leg"):
		_fail(
			failures,
			"depth_auto_lane: encounter strict with empty formation discipline should filter legs (got %s)" % str(f_enc_strict)
		)
	_free_manager(mgr)


## Tier 1.6: pinch `wing_lacks_file_opposed` uses same-file rank-0 partner when depth spear lane is open.
static func _run_wing_lacks_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	var depth_spear: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		var w: Variant = _EntityAccess.get_weapon(c)
		if w != null and w is Weapon and _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 1:
			if (w as Weapon).depth_melee_eligible:
				depth_spear = c
		if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 1:
			front_f1 = c
	var front_f0: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player" and _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
			front_f0 = c
			break
	if depth_spear.is_empty() or front_f1.is_empty() or front_f0.is_empty():
		_fail(failures, "wing_depth: expected 2×2 player grid with spear at rank1 file1")
		return
	if not _TargetScoring.wing_lacks_file_opposed(mgr, front_f1):
		_fail(failures, "wing_depth: rank0 file1 should lack file-opposed enemy (single enemy file0)")
	if _TargetScoring.wing_lacks_file_opposed(mgr, front_f0):
		_fail(failures, "wing_depth: rank0 file0 should have file-opposed enemy")
	if not _TargetScoring.wing_lacks_file_opposed(mgr, depth_spear):
		_fail(failures, "wing_depth: depth spear file1 should match front wing (lack opposed)")
	_free_manager(mgr)


## Tier 1.9: depth rank spear listing weights vs formation doctrine (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
static func _run_depth_polearm_doctrine_action_weights(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_doc_weights: expected open depth polearm lane")
		_free_manager(mgr)
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
		_fail(failures, "depth_doc_weights: pinch should raise stab vs default")
	if w_hold_stab >= w_base_stab - 0.001:
		_fail(failures, "depth_doc_weights: hold should lower stab vs default")
	if w_pinch_slash >= w_base_slash - 0.001:
		_fail(failures, "depth_doc_weights: pinch should lower non-stab vs default")
	if w_hold_slash <= w_base_slash + 0.001:
		_fail(failures, "depth_doc_weights: hold should raise non-stab vs default")
	if w_probe_stab <= w_hold_stab + 1e-5 or w_probe_stab >= w_pinch_stab - 1e-5:
		_fail(
			failures,
			"depth_doc_weights: probing stab should sit strictly between hold and pinch hold=%.6f probe=%.6f pinch=%.6f"
			% [w_hold_stab, w_probe_stab, w_pinch_stab]
		)
	if w_probe_slash <= w_pinch_slash + 1e-5 or w_probe_slash >= w_hold_slash - 1e-5:
		_fail(
			failures,
			"depth_doc_weights: probing non-stab should sit strictly between pinch and hold pinch=%.6f probe=%.6f hold=%.6f"
			% [w_pinch_slash, w_probe_slash, w_hold_slash]
		)
	_free_manager(mgr)


## Tier 1.9: **`CombatAIActionPicker._depth_polearm_action_weight_mult`** stays neutral (**1.0**) when no **`depth_polearm_valid_line_threat`** to any hostile rank 0 (lane may still be open); boosts stab when **3-wide** yields ≥1 valid line.
static func _run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures: PackedStringArray) -> void:
	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(_new_entity("SWORD"), "player")
	mgr_far.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(_new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_far, depth_far):
		_fail(failures, "ai_vlt_any: expected open lane")
		_free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	if _ActionsBuilder.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr_far, depth_far, mgr_far.combatants):
		_fail(failures, "ai_vlt_any: expected no valid-line rank-0 hostile after pushing files")
		_free_manager(mgr_far)
		return
	var w_neutral_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr_far, depth_far, "spear_thrust")
	var w_neutral_close: float = _AIPicker._depth_polearm_action_weight_mult(
		mgr_far, depth_far, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
	)
	if absf(w_neutral_stab - 1.0) > 0.001 or absf(w_neutral_close - 1.0) > 0.001:
		_fail(
			failures,
			"ai_vlt_any: far-line AI mult should be 1.0 stab=%s close=%s" % [str(w_neutral_stab), str(w_neutral_close)]
		)
	_free_manager(mgr_far)
	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SPEAR"), "player")
	for _j in 3:
		mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr3._recompute_zoc_and_distance()
	var depth3: Dictionary = mgr3.combatants[1]
	if not _ActionsBuilder.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr3, depth3, mgr3.combatants):
		_fail(failures, "ai_vlt_any: standard 3-wide should have ≥1 valid-line rank-0 target")
		_free_manager(mgr3)
		return
	var w_boost: float = _AIPicker._depth_polearm_action_weight_mult(mgr3, depth3, "spear_thrust")
	if w_boost <= 1.001:
		_fail(failures, "ai_vlt_any: standard layout should boost stab mult got %s" % str(w_boost))
	_free_manager(mgr3)


## Option 4: `CombatDoctrine.enemy_line_hollow_center_for_pinch` (automatic pinch trigger when `FEATURE_AUTOMATIC_DOCTRINE` is enabled).
static func _run_doctrine_hollow_center_pinch_heuristic(failures: PackedStringArray) -> void:
	_CombatDoctrine.evaluate_automatic_doctrine(null)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var en_by_file: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		en_by_file[_EntityAccess.file_int(c)] = c
	if en_by_file.size() < 3:
		_fail(failures, "doctrine_hollow: expected 3 enemies")
		_free_manager(mgr)
		return
	(en_by_file[1] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: 3-file line with dead center should read as hollow for pinch")
	(en_by_file[1] as Dictionary)["alive"] = true
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: full enemy front should not be hollow")
	(en_by_file[1] as Dictionary)["alive"] = false
	(en_by_file[2] as Dictionary)["alive"] = false
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: single-wing line should not qualify as hollow center")
	_free_manager(mgr)

	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	for _k in 4:
		mgr4.register(_new_entity("SWORD"), "enemy")
	mgr4.start({"files": 1, "ranks": 1}, {"files": 4, "ranks": 1})
	var en4: Dictionary = {}
	for c in mgr4.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			en4[_EntityAccess.file_int(c)] = c
	for kill_i in [1, 2]:
		(en4[kill_i] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr4, "player"):
		_fail(failures, "doctrine_hollow: 4-file empty middle pair + living wings should be hollow")
	_free_manager(mgr4)


## `enemy_line_hollow_center_for_pinch`: rank-0 intruder on host center counts as **filled** (not hollow).
static func _run_doctrine_hollow_center_intruder_fills_center(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var en_by_file: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		en_by_file[_EntityAccess.file_int(c)] = c
	if not en_by_file.has(1):
		_fail(failures, "doctrine_hollow_intr: expected enemy at file 1")
		_free_manager(mgr)
		return
	(en_by_file[1] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow_intr: expected hollow with dead native center")
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 1
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow_intr: intruder rank0 at center should not read as hollow")
	_free_manager(mgr)


## Tier 1.9 / doctrine: **`CombatDoctrine.normalize`** aliases + **`CombatManager.set_formation_doctrine`** → **`get_formation_doctrine`** round-trip.
static func _run_doctrine_normalize_and_manager_roundtrip(failures: PackedStringArray) -> void:
	if _CombatDoctrine.normalize("") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: empty string should be default")
	if _CombatDoctrine.normalize("  \t ") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: whitespace-only should be default")
	if _CombatDoctrine.normalize("pinch") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: pinch alias")
	if _CombatDoctrine.normalize("PINCH_CENTER") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: canonical pinch_center")
	if _CombatDoctrine.normalize("pincer") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: pincer alias")
	if _CombatDoctrine.normalize("hold") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(failures, "doctrine_norm: hold alias")
	if _CombatDoctrine.normalize("probing") != CombatConstants.DOCTRINE_PROBING:
		_fail(failures, "doctrine_norm: probing alias")
	if _CombatDoctrine.normalize(CombatConstants.DOCTRINE_PROBING) != CombatConstants.DOCTRINE_PROBING:
		_fail(failures, "doctrine_norm: probing canonical")
	if _CombatDoctrine.normalize("not_a_real_doctrine_string") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: unknown → default")
	if _CombatDoctrine.doctrine_for_fid(null, "player") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_for_fid: null manager → default")
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.set_formation_doctrine("player", "  pincer  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(
			failures,
			"doctrine_roundtrip: player got %s want pinch_center"
			% mgr.get_formation_doctrine("player")
		)
	mgr.set_formation_doctrine("player", "  probing  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"doctrine_rt: set probing expected %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	mgr.set_formation_doctrine("enemy", "bogus_doctrine_value")
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(
			failures,
			"doctrine_roundtrip: enemy unknown should store default got %s"
			% mgr.get_formation_doctrine("enemy")
		)
	_free_manager(mgr)


## Tier 1.9: **`encounter`** + optional **`start()`** preset dicts seed **`formation_doctrine`** (`ENCOUNTER_KEY_FORMATION_DOCTRINE_*`, else encounter alt keys, then preset **`FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, via **`CombatConstants.formation_doctrine_string_from_dict`** for presets).
static func _run_encounter_formation_doctrine_on_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  probing  "
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = "hold"
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_start: player want %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"encounter_doctrine_start: enemy want %s got %s"
			% [CombatConstants.DOCTRINE_HOLD_LANE, mgr.get_formation_doctrine("enemy")]
		)
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  \t  "
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr2.get_formation_doctrine("player") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(
			failures,
			"encounter_doctrine_start: whitespace-only encounter value should keep default got %s"
			% mgr2.get_formation_doctrine("player")
		)
	_free_manager(mgr2)
	var mgr3: Node = _MgrScript.new()
	mgr3.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	var pdoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "hold_lane"
	}
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start(pdoc, {"files": 1, "ranks": 1})
	if mgr3.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"preset_doctrine_start: player preset should override encounter probing got %s"
			% mgr3.get_formation_doctrine("player")
		)
	_free_manager(mgr3)
	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	mgr4.register(_new_entity("SWORD"), "enemy")
	var edoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "pinch"
	}
	mgr4.start({"files": 1, "ranks": 1}, edoc)
	if mgr4.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(
			failures,
			"preset_doctrine_start: enemy preset pinch alias want pinch_center got %s"
			% mgr4.get_formation_doctrine("enemy")
		)
	_free_manager(mgr4)
	var mgr5: Node = _MgrScript.new()
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "probing"
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT] = "hold"
	mgr5.register(_new_entity("SWORD"), "player")
	mgr5.register(_new_entity("SWORD"), "enemy")
	mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr5.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_alt: player doctrine_player want probing got %s"
			% mgr5.get_formation_doctrine("player")
		)
	if mgr5.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"encounter_doctrine_alt: enemy doctrine_enemy want hold_lane got %s"
			% mgr5.get_formation_doctrine("enemy")
		)
	_free_manager(mgr5)
	var mgr6: Node = _MgrScript.new()
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "hold_lane"
	mgr6.register(_new_entity("SWORD"), "player")
	mgr6.register(_new_entity("SWORD"), "enemy")
	mgr6.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr6.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_alt: canonical formation_doctrine_player should win over doctrine_player got %s"
			% mgr6.get_formation_doctrine("player")
		)
	_free_manager(mgr6)
	var mgr7: Node = _MgrScript.new()
	mgr7.register(_new_entity("SWORD"), "player")
	mgr7.register(_new_entity("SWORD"), "enemy")
	var p7: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold",
	}
	mgr7.start(p7, {"files": 1, "ranks": 1})
	if mgr7.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"preset_doctrine_alt: player preset `doctrine` only want hold_lane got %s"
			% mgr7.get_formation_doctrine("player")
		)
	_free_manager(mgr7)
	var mgr8: Node = _MgrScript.new()
	mgr8.register(_new_entity("SWORD"), "player")
	mgr8.register(_new_entity("SWORD"), "enemy")
	var p8: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
	}
	mgr8.start(p8, {"files": 1, "ranks": 1})
	if mgr8.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"preset_doctrine_alt: canonical formation_doctrine on preset should win over doctrine got %s"
			% mgr8.get_formation_doctrine("player")
		)
	_free_manager(mgr8)


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
		_fail(failures, "encounter_doctrine_string: empty canonical should use alt got %s" % got_alt)
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
		_fail(failures, "encounter_doctrine_string: canonical should win over alt got %s" % got_canon)
	var enc_ws: Dictionary = {CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "  \t  "}
	var got_ws: String = CombatConstants.encounter_formation_doctrine_string(
		enc_ws,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if not got_ws.is_empty():
		_fail(failures, "encounter_doctrine_string: whitespace-only canonical should fall through to empty got %s" % got_ws)
	var preset_alt_only: Dictionary = {
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "  hold  ",
	}
	var got_preset_alt: String = CombatConstants.formation_doctrine_string_from_dict(
		preset_alt_only,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if got_preset_alt != "hold":
		_fail(failures, "formation_doctrine_string_from_dict: preset alt-only want hold got %s" % got_preset_alt)
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
		_fail(
			failures,
			"formation_doctrine_string_from_dict: preset canonical should win got %s" % got_preset_canon
		)


## `on_combatant_died`: intruder corpse **`slot_obstacles`** on **host** formation at death `(rank,file)`.
static func _run_intruder_death_obstacle_on_host_formation(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 2
	var pid: int = _EntityAccess.id_int(p)
	p["alive"] = false
	_FormationFlow.on_combatant_died(mgr, p)
	var form_enemy: Dictionary = _FormationSlots.formation_record_read(mgr.formations, "enemy")
	var obst: Dictionary = _FormationSlots.formation_nested_dictionary_read(form_enemy, "slot_obstacles")
	var key := Vector2i(0, 2)
	if not obst.has(key):
		_fail(failures, "death_obst_intr: missing slot_obstacles on enemy formation at host cell")
	var arr: Variant = obst[key]
	if typeof(arr) != TYPE_ARRAY or not (arr as Array).has(pid):
		_fail(failures, "death_obst_intr: obstacle list missing dead intruder id %d (got %s)" % [pid, str(arr)])
	_free_manager(mgr)


## `start_pair_move` / `start_rotate_file` bail on intruders; slot mutations stay home-keyed and must not run for intruded initiators.
static func _run_intruded_skips_start_pair_move(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1 or _EntityAccess.file_int(p0) != _EntityAccess.file_int(p1):
		_fail(failures, "intr_pair_setup: expected same-file rank0/rank1 player column")
		_free_manager(mgr)
		return
	p0["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p0["intrusion_host_fid"] = "enemy"
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	for ev in mgr.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		if str(ev.get("type", "")) != CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			continue
		var cid: int = int(ev.get("combatant_id", -1))
		var evd: Variant = ev.get("data", null)
		var pid: int = int((evd as Dictionary).get("partner_id", -1)) if typeof(evd) == TYPE_DICTIONARY else -1
		if (cid == id0 and pid == id1) or (cid == id1 and pid == id0):
			_fail(failures, "intr_pair: swap_rank_resolve must not enqueue when initiator is intruded")
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var q0: Dictionary = mgr2.combatants[0]
	var q1: Dictionary = mgr2.combatants[1]
	var qid0: int = _EntityAccess.id_int(q0)
	var qid1: int = _EntityAccess.id_int(q1)
	if _EntityAccess.rank_int(q0) != 0 or _EntityAccess.rank_int(q1) != 0 or abs(_EntityAccess.file_int(q0) - _EntityAccess.file_int(q1)) != 1:
		_fail(failures, "intr_pair_setup2: expected adjacent-file rank-0 pair")
		_free_manager(mgr2)
		return
	q1["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	q1["intrusion_host_fid"] = "enemy"
	_FormationFlow.start_rotate_file(mgr2, qid0, qid1)
	for ev in mgr2.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		if str(ev.get("type", "")) != CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
			continue
		var cid2: int = int(ev.get("combatant_id", -1))
		var evd2: Variant = ev.get("data", null)
		var pid2: int = int((evd2 as Dictionary).get("partner_id", -1)) if typeof(evd2) == TYPE_DICTIONARY else -1
		if (cid2 == qid0 and pid2 == qid1) or (cid2 == qid1 and pid2 == qid0):
			_fail(failures, "intr_pair: rotate_file_resolve must not enqueue when partner is intruded")
	_free_manager(mgr2)


## Pair moves cancel any queued `swap_rank_resolve` touching either combatant before scheduling a fresh resolve.
static func _run_cancel_stale_swap_rank_resolve_events(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": id0,
		"resolve_at": mgr.combat_clock + 10.0,
		"data": {"partner_id": id1, "move_kind": "swap_rank"}
	})
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": id1,
		"resolve_at": mgr.combat_clock + 11.0,
		"data": {"partner_id": id0, "move_kind": "swap_rank"}
	})
	var swap_queued: int = 0
	for ev in mgr.event_queue:
		if typeof(ev) == TYPE_DICTIONARY and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			swap_queued += 1
	if swap_queued != 2:
		_fail(failures, "swap_cancel_setup: expected 2 stale swap_rank_resolve events, got %d" % swap_queued)
		_free_manager(mgr)
		return
	_EventScheduler.cancel_pending_swap_rank_pair_events(mgr, id0, id1)
	for ev in mgr.event_queue:
		if typeof(ev) == TYPE_DICTIONARY and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			_fail(failures, "swap_cancel: stale swap_rank_resolve should be removed")
			_free_manager(mgr)
			return
	_free_manager(mgr)


## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).
static func _run_parry_preserves_formation_pair_state(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var en: Dictionary = mgr.combatants[2]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	var eid: int = _EntityAccess.id_int(en)
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: expected rank0 in swap_rank after start_pair_move (got %s)" % _EntityAccess.state_str(p0))
		_free_manager(mgr)
		return
	if _EntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: expected rank1 in swap_rank after start_pair_move")
		_free_manager(mgr)
		return
	en["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high"}
	_AttackResultApplier.apply_result(mgr, eid, {
		"action": "parry_deflect",
		"target_id": id0,
		"recovery_duration": 0.5,
		"parry_clash_context": {"archetype_id": "", "parry_control": 0.0}
	})
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(
			failures,
			"parry_swap: parry_deflect must not set defender to waiting mid pair move (got %s)"
			% _EntityAccess.state_str(p0)
		)
	if _EntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: partner must stay swap_rank (got %s)" % _EntityAccess.state_str(p1))
	_free_manager(mgr)


## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.
static func _run_swap_rank_resolve_completes_rank_swap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
		_fail(failures, "swap_resolve_setup: expected player rank0/rank1 same file")
		_free_manager(mgr)
		return
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "swap_resolve: expected swap_rank state on initiator")
		_free_manager(mgr)
		return
	_FormationFlow.handle_swap_rank_resolve(
		mgr,
		{"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
	)
	if _EntityAccess.rank_int(p0) != 1 or _EntityAccess.rank_int(p1) != 0:
		_fail(
			failures,
			"swap_resolve: expected ranks swapped (p0=%d p1=%d)" % [_EntityAccess.rank_int(p0), _EntityAccess.rank_int(p1)]
		)
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_WAITING or _EntityAccess.state_str(p1) != CombatConstants.STATE_WAITING:
		_fail(failures, "swap_resolve: both should return to waiting (got %s / %s)" % [_EntityAccess.state_str(p0), _EntityAccess.state_str(p1)])
	if p0.has("formation_move_partner_id") or p1.has("formation_move_partner_id"):
		_fail(failures, "swap_resolve: formation_move_partner_id should be cleared")
	_free_manager(mgr)


## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.
static func _run_negligible_hit_recovery_shorter_than_counted_hit(failures: PackedStringArray) -> void:
	var i: float = 0.55
	var t_hit: float = _CombatTiming.recovery_duration(i, "hit", 1.0, 1.0, 100, -1.0)
	var t_neg: float = _CombatTiming.recovery_duration(i, "negligible", 1.0, 1.0, 100, -1.0)
	if not (t_neg < t_hit):
		_fail(
			failures,
			"negligible_recovery: expected negligible < hit (hit=%.4f negligible=%.4f)" % [t_hit, t_neg]
		)


## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.
static func _run_combat_log_formatter_negligible(failures: PackedStringArray) -> void:
	var line: String = _CombatLogFormatter.format_action_line(
		"Ally",
		"player",
		"Foe",
		"enemy",
		{
			"outcome": "negligible",
			"part": "head",
			"dmg": 0,
			"died": false,
			"total_physical": 0.2,
			"final_cut": 0.0,
			"final_blunt": 0.2,
			"health_before": 10,
			"health_after": 10
		}
	)
	if not line.contains("negligible"):
		_fail(failures, "combat_log_negligible: expected 'negligible' in formatted line: %s" % line)
	var row_neg: String = _CombatLogFormatter.format_last_hit_on_target_row(
		{"outcome": "negligible", "part": "head", "total_physical": 0.2, "dmg": 0}
	)
	if not row_neg.begins_with("Graze:"):
		_fail(failures, "combat_log_negligible_row: expected Graze prefix, got: %s" % row_neg)
	var row_hit: String = _CombatLogFormatter.format_last_hit_on_target_row(
		{"outcome": "hit", "part": "head", "total_physical": 5.0, "dmg": 5}
	)
	if not row_hit.begins_with("Hit:"):
		_fail(failures, "combat_log_hit_row: expected Hit prefix, got: %s" % row_hit)


## Intruders: `assign_combatant_zones` uses host `files`/`ranks` (`formation_id_for_zone_geometry`), not home 1-wide line.
static func _run_intruder_zone_id_uses_host_grid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_FRONT:
		_fail(
			failures,
			"intruder_zoc: non-intruded 1-file fighter expected zone %s got %s"
			% [_ZoneOfControl.ZONE_FRONT, str(p.get("zone_id", ""))]
		)
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 0
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_LEFT_FLANK:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=0 expected %s got %s"
			% [_ZoneOfControl.ZONE_LEFT_FLANK, str(p.get("zone_id", ""))]
		)
	p["file"] = 1
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_FRONT:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=1 (center) expected %s got %s"
			% [_ZoneOfControl.ZONE_FRONT, str(p.get("zone_id", ""))]
		)
	p["file"] = 2
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_RIGHT_FLANK:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=2 expected %s got %s"
			% [_ZoneOfControl.ZONE_RIGHT_FLANK, str(p.get("zone_id", ""))]
		)
	_free_manager(mgr)


## ZoC zone fill: intruders on host `rank`/`file` count toward **host** formation zone tallies (not only `formation_id_str`).
static func _run_zoc_count_alive_includes_intruder_on_host(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	e["rank"] = 0
	e["file"] = 2
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 0
	var n_left: int = _ZoneOfControl.count_alive_in_zone(mgr, "enemy", _ZoneOfControl.ZONE_LEFT_FLANK)
	var n_right: int = _ZoneOfControl.count_alive_in_zone(mgr, "enemy", _ZoneOfControl.ZONE_RIGHT_FLANK)
	if n_left != 1:
		_fail(failures, "zoc_count: enemy left_flank expected 1 (intruder) got %d" % n_left)
	if n_right != 1:
		_fail(failures, "zoc_count: enemy right_flank expected 1 (native) got %d" % n_right)
	if _ZoneOfControl.count_alive_in_zone(mgr, "player", _ZoneOfControl.ZONE_LEFT_FLANK) != 0:
		_fail(failures, "zoc_count: player formation should have no left_flank occupant in this setup")
	_free_manager(mgr)


## Crash neighbor hold: intruder defender uses **host** line neighbors (`formation_id_for_zone_geometry`), not home-roster `formation_id`.
static func _run_crash_neighbor_hold_uses_host_line_for_intruder(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	e0["rank"] = 0
	e0["file"] = 0
	e1["rank"] = 0
	e1["file"] = 2
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 1
	var form_b: Dictionary = mgr.formations["enemy"]
	var hold_n: float = _IntrusionGeometry.crash_neighbor_hold_support(mgr, p, form_b)
	if hold_n < CombatConstants.CRASH_NEIGHBOR_HOLD_BASE * 0.65:
		_fail(
			failures,
			"crash_neighbor_hold: intruder center file expected flank native bonus, got %.3f" % hold_n
		)
	_free_manager(mgr)


## `reschedule_back_rank_turns(host_fid)` must hit intruders lodged on that host grid (`rank`>0, waiting).
static func _run_reschedule_back_rank_includes_intruder_on_host(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var p: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(p)
	_EventScheduler.cancel_pending_action_ready(mgr, pid)
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 1
	p["file"] = 0
	p["state"] = CombatConstants.STATE_WAITING
	_EventScheduler.reschedule_back_rank_turns(mgr, "enemy")
	var ready: float = _EventScheduler.get_next_action_ready_at(mgr, pid)
	if ready < 0.0:
		_fail(
			failures,
			"event_reschedule_back_rank: intruder rank>0 on enemy host should schedule formation recheck"
		)
	_free_manager(mgr)


## Tier 1.9: `start()` formation preset copies `spear_lane_profile` into formation dict (normalized).
static func _run_spear_lane_profile_preset_normalized(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 1, "density": "normal", CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE: "full"},
		{"files": 1, "ranks": 1}
	)
	var sp: String = str(mgr.formations["player"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
	if sp != CombatConstants.SPEAR_LANE_PROFILE_OPEN:
		_fail(failures, "spear_lane_preset: expected open from alias 'full' got %s" % sp)
	var se: String = str(mgr.formations["enemy"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
	if se != CombatConstants.SPEAR_LANE_PROFILE_AUTO:
		_fail(failures, "spear_lane_preset: enemy default profile should be auto/empty got %s" % se)
	_free_manager(mgr)


## Tier 1.9: **`Weapon.depth_melee_eligible`** from **`WeaponConstants`** definitions — **SPEAR** **true**; **SWORD** default **false** ( **`AvailableActionsBuilder.depth_polearm_lane_open`** gate).
static func _run_weapon_depth_melee_eligible_fixture(failures: PackedStringArray) -> void:
	var w_spear: Weapon = _Weapon.create_from_definition("SPEAR")
	var w_sword: Weapon = _Weapon.create_from_definition("SWORD")
	if w_spear == null or w_sword == null:
		_fail(failures, "depth_melee_elig: missing weapon fixtures")
		return
	if not w_spear.depth_melee_eligible:
		_fail(failures, "depth_melee_elig: SPEAR should be depth_melee_eligible")
	if w_sword.depth_melee_eligible:
		_fail(failures, "depth_melee_elig: SWORD should not be depth_melee_eligible by default")


## Tier 1.9: rank>1 without **`depth_melee_eligible`** weapon → **`depth_polearm_lane_open`** **false** even with same-file living rank-0 ally (lane predicate, not only **`can_melee_threaten`**).
static func _run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr.combatants[1]
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth_sw):
		_fail(
			failures,
			"depth_lane_non_eligible: rank-1 sword must not open depth polearm lane (rank-0 ally present)"
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** for **`ENGAGEMENT_ROLE_INTRUDED`** combatants (depth lane is home-formation fiction; intruders use host grid / intrusion rules).
static func _run_depth_polearm_lane_open_false_when_intruded(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 1
	p["file"] = 0
	if _ActionsBuilder.depth_polearm_lane_open(mgr, p):
		_fail(
			failures,
			"depth_lane_intruded: intruded rank-1 spear must not open home depth polearm lane"
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** at **`rank` ≤ 0** (lane is for **home** depth ranks only).
static func _run_depth_polearm_lane_open_false_at_rank_zero(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var front: Dictionary = mgr.combatants[0]
	if _EntityAccess.rank_int(front) != 0:
		_fail(failures, "depth_lane_r0: expected player spear at rank 0 got rank %s" % str(_EntityAccess.rank_int(front)))
	if _ActionsBuilder.depth_polearm_lane_open(mgr, front):
		_fail(failures, "depth_lane_r0: rank-0 spear must not open depth polearm lane")
	_free_manager(mgr)


## Tier 1.9: no **living** same-file rank-0 partner → **`depth_polearm_lane_open`** **false** (even with **`depth_melee_eligible`** weapon).
static func _run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth_f1: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) != 1:
			continue
		if _EntityAccess.rank_int(c) == 1:
			depth_f1 = c
		elif _EntityAccess.rank_int(c) == 0:
			front_f1 = c
	if depth_f1.is_empty() or front_f1.is_empty():
		_fail(failures, "depth_lane_no_r0: expected player rank-0 + rank-1 at file 1")
		_free_manager(mgr)
		return
	front_f1["alive"] = false
	mgr._recompute_zoc_and_distance()
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth_f1):
		_fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 1 must not open lane when same-file rank-0 is dead"
		)
	var depth_f0: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) == 0 and _EntityAccess.rank_int(c) == 1:
			depth_f0 = c
			break
	if depth_f0.is_empty():
		_fail(failures, "depth_lane_no_r0: expected player rank-1 at file 0")
	elif not _ActionsBuilder.depth_polearm_lane_open(mgr, depth_f0):
		_fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 0 should still open lane (living same-file rank-0 at file 0)"
		)
	_free_manager(mgr)


## Tier 1.9: **`CombatDistanceBands.depth_polearm_lane_open_by_combatant_id`** matches **`AvailableActionsBuilder.depth_polearm_lane_open`** ( **`formation_id_for_zone_geometry`** `fid` ).
static func _run_depth_polearm_lane_cache_matches_builder(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	mgr._recompute_zoc_and_distance()
	_assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:1file")
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 2, "ranks": 2, "density": "normal"}, e_preset)
	var front_f1: Dictionary = {}
	for c in mgr2.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) != 1 or _EntityAccess.rank_int(c) != 0:
			continue
		front_f1 = c
		break
	if front_f1.is_empty():
		_fail(failures, "depth_lane_cache:2wide expected rank-0 file 1")
		_free_manager(mgr2)
		return
	front_f1["alive"] = false
	mgr2._recompute_zoc_and_distance()
	_assert_depth_lane_open_cache_matches_builder(mgr2, failures, "depth_lane_cache:2wide_dead_r0f1")
	_free_manager(mgr2)


## Tier 1.9: same-file rank-0 partner **incapacitated** → **`depth_polearm_lane_open`** **false** (**`same_file_living_rank0_ally`** skips incap).
static func _run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var ent_r0: CoreEntity = _new_entity("SWORD")
	mgr.register(ent_r0, "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var front: Dictionary = mgr.combatants[0]
	var depth: Dictionary = mgr.combatants[1]
	ent_r0.consciousness = 5.0
	mgr._recompute_zoc_and_distance()
	if not _EntityAccess.is_incapacitated(front):
		_fail(failures, "depth_lane_r0_incap: rank-0 ally should read incapacitated")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(
			failures,
			"depth_lane_r0_incap: rank-1 spear must not open lane when same-file rank-0 is incapacitated"
		)
	_assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:r0_incap")
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open(manager, c, "")`** matches **`depth_polearm_lane_open(manager, c, fid)`** when **`fid == formation_id_for_zone_geometry(manager, c)`** (explicit **`zone_geometry_fid`** contract). Covers **home** ranks and an **`ENGAGEMENT_ROLE_INTRUDED`** rank-1 **SPEAR** on the **host** grid.
static func _run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
		var o_default: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, "")
		var o_explicit: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, fid)
		if o_default != o_explicit:
			_fail(
				failures,
				"depth_lane_fid_rt: id=%d default=%s explicit_fid=%s fid=%s"
				% [_EntityAccess.id_int(c), str(o_default), str(o_explicit), fid]
			)
	_free_manager(mgr)

	var mgr_i: Node = _MgrScript.new()
	mgr_i.register(_new_entity("SPEAR"), "player")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var pin: Dictionary = mgr_i.combatants[0]
	pin["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	pin["intrusion_host_fid"] = "enemy"
	pin["rank"] = 1
	pin["file"] = 0
	mgr_i._recompute_zoc_and_distance()
	for c in mgr_i.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var fid_i: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr_i, c)
		var o_def_i: bool = _ActionsBuilder.depth_polearm_lane_open(mgr_i, c, "")
		var o_exp_i: bool = _ActionsBuilder.depth_polearm_lane_open(mgr_i, c, fid_i)
		if o_def_i != o_exp_i:
			_fail(
				failures,
				"depth_lane_fid_rt_intr: id=%d default=%s explicit_fid=%s fid=%s"
				% [_EntityAccess.id_int(c), str(o_def_i), str(o_exp_i), fid_i]
			)
	_free_manager(mgr_i)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — open depth lane + **strict** + **tight** + no wedge → **false** (over-shoulder); **`spear_lane_profile` open** on same geometry → **true**.
static func _run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_allows_low: expected open depth polearm lane for setup")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth):
		_fail(failures, "depth_allows_low: strict+tight+lane open+no wedge should not allow low targets")
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth):
		_fail(failures, "depth_allows_low: spear_lane_profile open should allow low targets on tight formation")
	_free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** **`pa`** depth keys match **`depth_polearm_lane_allows_low_targets`** ( **`assume_depth_lane_open` true** ) and **`DEPTH_POLEARM_LANE_TYPE_*`**.
static func _run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "stamp_depth_geom: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var live_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
	if bool(pa.get("depth_polearm_attack", false)) != true:
		_fail(failures, "stamp_depth_geom: expected depth_polearm_attack true")
	var stamped_allow: bool = bool(pa.get("depth_polearm_allows_low_targets", true))
	if stamped_allow != live_tight:
		_fail(
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
		_fail(failures, "stamp_depth_geom: lane_type=%s expected %s (strict tight)" % [lt, expect_lt])
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var live_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa2: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa2)
	if bool(pa2.get("depth_polearm_allows_low_targets", false)) != live_open:
		_fail(
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
		_fail(failures, "stamp_depth_geom: lane_type=%s expected %s (profile open)" % [lt2, expect_lt2])
	_free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** leaves **`depth_polearm_*`** at non-depth defaults when attacker is rank **0** or rank **>0** with **`depth_polearm_lane_open`** **false**.
static func _run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(_new_entity("SPEAR"), "player")
	m0.register(_new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	var en0: Dictionary = m0.combatants[1]
	if _EntityAccess.rank_int(atk0) != 0:
		_fail(failures, "stamp_depth_def: expected rank-0 spear")
		_free_manager(m0)
		return
	var pa0: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(m0, atk0, en0, pa0)
	_assert_stamp_depth_pa_defaults(pa0, failures, "stamp_depth_def:rank0")
	_free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "enemy")
	var p1: Dictionary = {"files": 1, "ranks": 2, "density": "normal"}
	var e1: Dictionary = {"files": 1, "ranks": 1, "density": "normal"}
	m1.start(p1, e1)
	var atk1: Dictionary = m1.combatants[1]
	var en1: Dictionary = m1.combatants[2]
	if _EntityAccess.rank_int(atk1) <= 0:
		_fail(failures, "stamp_depth_def: expected rank-1 sword")
		_free_manager(m1)
		return
	if _ActionsBuilder.depth_polearm_lane_open(m1, atk1):
		_fail(failures, "stamp_depth_def: rank-1 sword should not open depth lane")
		_free_manager(m1)
		return
	var pa1: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(m1, atk1, en1, pa1)
	_assert_stamp_depth_pa_defaults(pa1, failures, "stamp_depth_def:rank1_no_lane")
	_free_manager(m1)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** drops legs iff **`depth_polearm_lane_allows_low_targets`** (**`assume_depth_lane_open` true**) is **false** (same strict/tight vs **`spear_lane_profile` open** flip as other depth harnesses).
static func _run_depth_polearm_parts_filter_tracks_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_parts_al: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_al: strict+tight should not allow low targets before filter assert")
	var filt_tight: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		_fail(failures, "depth_parts_al: filter should drop legs when allows_low false (got %s)" % str(filt_tight))
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_al: open profile should allow low targets before filter assert")
	var filt_open: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_open.has("left_leg") or not filt_open.has("right_leg"):
		_fail(failures, "depth_parts_al: filter should keep legs when allows_low true (got %s)" % str(filt_open))
	_free_manager(mgr)


## Tier 1.9: **`intrusion_wedge_by_file`** pressure at depth file opens lows under **strict**/**tight** (no **`spear_lane_profile` open**) — **`depth_polearm_lane_allows_low_targets`** + **`depth_polearm_targetable_parts_filter`**.
static func _run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_parts_wedge: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_wedge: intrusion wedge should open low targets under strict+tight")
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt.has("left_leg") or not filt.has("right_leg"):
		_fail(failures, "depth_parts_wedge: filter should keep legs when wedge opens lane (got %s)" % str(filt))
	_free_manager(mgr)


## Tier 1.9: **`spear_lane_profile` restricted** — **`depth_polearm_lane_allows_low_targets`** is **false** without wedge pressure, **true** after **`upsert_from_intrusion`** ( **`depth_polearm_targetable_parts_filter`** follows).
static func _run_depth_polearm_restricted_profile_requires_wedge_for_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_prof_rest: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = (
		CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_prof_rest: restricted + loose should not allow lows without wedge")
	var parts_in: Array = ["head", "left_leg", "right_leg"]
	var filt_no_w: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_no_w.has("left_leg") or filt_no_w.has("right_leg"):
		_fail(failures, "depth_prof_rest: filter should drop legs without wedge (got %s)" % str(filt_no_w))
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_prof_rest: wedge should allow lows under restricted profile")
	var filt_w: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_w.has("left_leg") or not filt_w.has("right_leg"):
		_fail(failures, "depth_prof_rest: filter should keep legs after wedge (got %s)" % str(filt_w))
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** with explicit **`formation_dict_cache`** (deep copy of live dict) matches **`null`** cache (same **`fid`**, **`assume_depth_lane_open` true**).
static func _run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_fd_cache: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var fd_dup: Dictionary = fd.duplicate(true)
	var a_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_tight != b_tight:
		_fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch strict+tight (null=%s cache=%s)" % [str(a_tight), str(b_tight)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	fd_dup = fd.duplicate(true)
	var a_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_open != b_open:
		_fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch profile open (null=%s cache=%s)" % [str(a_open), str(b_open)]
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** is a **pass-through** when **`depth_polearm_lane_open`** is **false** (rank-1 non-polearm) or attacker **`rank` ≤ 0** (no depth lane use).
static func _run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(_new_entity("SPEAR"), "player")
	m0.register(_new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	if _EntityAccess.rank_int(atk0) != 0:
		_fail(failures, "depth_parts_pass: expected rank-0 attacker")
		_free_manager(m0)
		return
	var parts0: Array = ["head", "left_leg", "right_leg"]
	var out0: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(m0, atk0, parts0)
	if out0 != parts0:
		_fail(failures, "depth_parts_pass: rank-0 should not filter parts (got %s)" % str(out0))
	_free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "enemy")
	m1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk1: Dictionary = m1.combatants[1]
	if _EntityAccess.rank_int(atk1) <= 0:
		_fail(failures, "depth_parts_pass: expected rank-1 sword")
		_free_manager(m1)
		return
	if _ActionsBuilder.depth_polearm_lane_open(m1, atk1):
		_fail(failures, "depth_parts_pass: rank-1 sword should not open depth lane")
		_free_manager(m1)
		return
	var parts1: Array = ["head", "left_leg"]
	var out1: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(m1, atk1, parts1)
	if out1 != parts1:
		_fail(failures, "depth_parts_pass: lane closed should not filter parts (got %s)" % str(out1))
	_free_manager(m1)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — **`assume_depth_lane_open` false** returns **true** when **`depth_polearm_lane_open`** is **false** (depth lane N/A); **`assume_depth_lane_open` true** skips that guard and runs wedge / **`spear_lane_profile`** / discipline (strict+tight → **false** without open profile).
static func _run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if _EntityAccess.rank_int(depth) <= 0:
		_fail(failures, "depth_al_assume: expected rank-1 depth combatant")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_assume: rank-1 sword must not open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var without_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if not without_assume:
		_fail(
			failures,
			"depth_al_assume: lane closed + assume false should return true (depth lane N/A)"
		)
	if with_assume:
		_fail(
			failures,
			"depth_al_assume: strict+tight + assume true should evaluate lane rules → false (no open profile)"
		)
	if without_assume == with_assume:
		_fail(failures, "depth_al_assume: assume flag must change result when lane closed vs strict+tight body")
	_free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_lane_allows_low_targets`** returns the same value whether **`assume_depth_lane_open`** is **false** or **true** (closed-lane early exit skipped in both cases once the lane is open).
static func _run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_agree: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var tight_no_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var tight_with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if tight_no_assume != tight_with_assume:
		_fail(
			failures,
			"depth_al_agree: strict+tight assume false vs true mismatch (%s vs %s)"
			% [str(tight_no_assume), str(tight_with_assume)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var open_no_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var open_with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if open_no_assume != open_with_assume:
		_fail(
			failures,
			"depth_al_agree: profile open assume false vs true mismatch (%s vs %s)"
			% [str(open_no_assume), str(open_with_assume)]
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets(manager, c, "", …)`** matches **`…(manager, c, fid, …)`** when **`fid == formation_id_for_zone_geometry(manager, c)`** — same **`zone_geometry_fid`** contract as **`depth_polearm_lane_open`** / **`formation_dict_for_zone_geometry`**. Covers **`assume_depth_lane_open` false + true** on **home** line + **`ENGAGEMENT_ROLE_INTRUDED`** rank-1 **SPEAR** on host grid.
static func _run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	_assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, "depth_al_fid_rt:home")
	_free_manager(mgr)

	var mgr_i: Node = _MgrScript.new()
	mgr_i.register(_new_entity("SPEAR"), "player")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var pin: Dictionary = mgr_i.combatants[0]
	pin["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	pin["intrusion_host_fid"] = "enemy"
	pin["rank"] = 1
	pin["file"] = 0
	mgr_i._recompute_zoc_and_distance()
	_assert_depth_polearm_allows_low_fid_round_trip_slice(mgr_i, failures, "depth_al_fid_rt:intr")
	_free_manager(mgr_i)


static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
	mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
	for assume_open in [false, true]:
		for c in mgr.combatants:
			if not _EntityAccess.alive_bool(c):
				continue
			var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
			var via_empty: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, c, "", null, assume_open)
			var via_fid: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, c, fid, null, assume_open)
			if via_empty != via_fid:
				_fail(
					failures,
					"%s assume=%s id=%d empty=%s explicit=%s fid=%s"
					% [ctx, str(assume_open), _EntityAccess.id_int(c), str(via_empty), str(via_fid), fid]
				)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
	if bool(pa.get("depth_polearm_attack", true)):
		_fail(failures, "%s: depth_polearm_attack should be false" % ctx)
	if not bool(pa.get("depth_polearm_allows_low_targets", false)):
		_fail(failures, "%s: depth_polearm_allows_low_targets should stay default true" % ctx)
	if str(pa.get("depth_polearm_lane_type", "x")) != "":
		_fail(failures, "%s: depth_polearm_lane_type should be empty" % ctx)


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
	var by_id: Dictionary = _DistanceBands.depth_polearm_lane_open_by_combatant_id(mgr)
	for c in mgr.combatants:
		var cid: int = _EntityAccess.id_int(c)
		if not _EntityAccess.alive_bool(c):
			if by_id.has(cid):
				_fail(failures, "%s: dead id=%d should not be in lane cache" % [ctx, cid])
			continue
		if not by_id.has(cid):
			_fail(failures, "%s: alive id=%d missing from lane cache" % [ctx, cid])
			continue
		var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
		var live: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, fid)
		if bool(by_id[cid]) != live:
			_fail(
				failures,
				"%s: lane cache id=%d cached=%s live=%s rank=%d"
				% [ctx, cid, str(by_id[cid]), str(live), _EntityAccess.rank_int(c)]
			)


## Tier 3.1: pack / protection-circle parry flank uses wedge/lane-aware effective file spacing (falls back to |Δfile|≥2).
## Tier 3.1: sector surround `1/(1+k·excess)` matches integer **`surround_defense_multiplier`** when total weight = 2 (two full-width flank threats).
static func _run_surround_sector_load_formula(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var m_int_two_threats: float = _TacticalCombat.surround_defense_multiplier(d, 2)
	var m_sector: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)
	if not is_equal_approx(m_int_two_threats, m_sector):
		_fail(
			failures,
			"surround_sector: int n=2 %.4f vs sector wsum=2 %.4f" % [m_int_two_threats, m_sector]
		)
	var m_mild: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 1.15)
	if m_mild <= m_int_two_threats + 0.01:
		_fail(
			failures,
			"surround_sector: compressed wsum=1.15 should be milder than int n=2 (%.4f vs %.4f)" % [m_mild, m_int_two_threats]
		)


## Tier 3.1: two adjacent-file enemies vs center defender — summed sector weight stays below two full flank weights.
static func _run_surround_threat_weight_sum_three_file_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def_id: int = _EntityAccess.id_int(mgr.combatants[0])
	if _TacticalCombat.count_engaging_threats(mgr, def_id) != 2:
		_fail(failures, "surround_weight_sum: expected two engaging threats")
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02:
		_fail(failures, "surround_weight_sum: adjacent pair should sum < 2 full weights, got %.4f" % wsum)
	if wsum < 0.9:
		_fail(failures, "surround_weight_sum: expected meaningful stacked weight, got %.4f" % wsum)
	_free_manager(mgr)


## Tier 3.1: **`surround_defense_multiplier_from_pa_with_sector`** — integer **`surround_threat_count`** vs sector **`surround_threat_weight_sum`** (explicit flag; production uses **`is_feature_sector_surround_load`**).
static func _run_surround_defense_multiplier_from_pa_both_paths(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var pa_two: Dictionary = {"surround_threat_count": 2}
	var m_int_path: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, false)
	var m_sector_equiv: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, true)
	if not is_equal_approx(m_int_path, _TacticalCombat.surround_defense_multiplier(d, 2)):
		_fail(failures, "surround_from_pa: int path should match surround_defense_multiplier(n=2)")
	if not is_equal_approx(m_sector_equiv, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)):
		_fail(failures, "surround_from_pa: sector path with count-only pa should match wsum=2")
	if not is_equal_approx(m_int_path, m_sector_equiv):
		_fail(
			failures,
			"surround_from_pa: n=2 int vs sector(count fallback) %.6f vs %.6f" % [m_int_path, m_sector_equiv]
		)
	var pa_mixed: Dictionary = {"surround_threat_count": 2, "surround_threat_weight_sum": 1.15}
	var m_split_two: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, false)
	var m_sector_mild: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, true)
	if not is_equal_approx(m_split_two, m_int_path):
		_fail(failures, "surround_from_pa: mixed pa int path should still use count=2")
	if m_sector_mild <= m_split_two + 0.001:
		_fail(
			failures,
			"surround_from_pa: sector wsum=1.15 should beat int n=2 split (%.6f vs %.6f)" % [m_sector_mild, m_split_two]
		)


## Tier 3.1: live **`compute_surround_threat_weight_sum`** matches **`surround_defense_multiplier_from_pa_with_sector(..., true)`** with **`pa`** shaped like **`AttackResolver`** (count + weight sum).
static func _run_surround_live_weight_sum_matches_from_pa_sector_path(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(failures, "surround_live_pa: expected two engaging threats got %d" % n_threats)
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02 or wsum < 0.9:
		_fail(failures, "surround_live_pa: unexpected wsum=%.4f (want compressed flank pair)" % wsum)
		_free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_sector: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	var m_ref: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)
	if not is_equal_approx(m_sector, m_ref):
		_fail(
			failures,
			"surround_live_pa: sector from_pa %.6f vs harness wsum ref %.6f" % [m_sector, m_ref]
		)
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_int_ref: float = _TacticalCombat.surround_defense_multiplier(def, n_threats)
	if not is_equal_approx(m_int, m_int_ref):
		_fail(
			failures,
			"surround_live_pa: int from_pa %.6f vs surround_defense_multiplier %.6f" % [m_int, m_int_ref]
		)
	if m_sector <= m_int + 0.001:
		_fail(
			failures,
			"surround_live_pa: sector path should be milder than int n=2 (%.6f vs %.6f) wsum=%.4f"
			% [m_sector, m_int, wsum]
		)
	_free_manager(mgr)


## Tier 3.1: one engaging threat — integer **n≤1** and sector **`wsum`≤`SURROUND_SECTOR_LOAD_FREE`** both stay neutral (**1.0**).
static func _run_surround_single_threat_int_and_sector_neutral(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	if n_threats != 1:
		_fail(failures, "surround_single: expected one engaging threat got %d" % n_threats)
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + 0.02:
		_fail(
			failures,
			"surround_single: wsum=%.4f should sit in free tier (≤%.3f)" % [wsum, CombatConstants.SURROUND_SECTOR_LOAD_FREE]
		)
		_free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	if not is_equal_approx(m_int, 1.0):
		_fail(failures, "surround_single: int path want 1.0 got %.6f" % m_int)
	if not is_equal_approx(m_sec, 1.0):
		_fail(failures, "surround_single: sector path want 1.0 got %.6f (wsum=%.4f)" % [m_sec, wsum])
	if not is_equal_approx(m_sec, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)):
		_fail(failures, "surround_single: sector from_pa vs harness ref mismatch")
	_free_manager(mgr)


## Tier 3.1: **`is_feature_sector_surround_load`** — `surround_defense_multiplier_from_pa` follows runtime toggle (int path off, sector path on).
static func _run_sector_surround_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
	var prev_flag: bool = CombatConstants.is_feature_sector_surround_load()
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_free_manager(mgr)
		_fail(failures, "sector_flag_toggle: need compressed two-threat layout (n=%d wsum=%.4f)" % [n_threats, wsum])
		return
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	CombatConstants.set_feature_sector_surround_load(false)
	var from_pa_off: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_off, m_int):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: flag off from_pa %.6f vs int ref %.6f" % [from_pa_off, m_int]
		)
		return
	CombatConstants.set_feature_sector_surround_load(true)
	var from_pa_on: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_on, m_sec):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: flag on from_pa %.6f vs sector ref %.6f" % [from_pa_on, m_sec]
		)
		return
	if from_pa_on <= from_pa_off + 0.001:
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: sector-on %.6f should exceed int-off %.6f (milder surround)" % [from_pa_on, from_pa_off]
		)
		return
	CombatConstants.set_feature_sector_surround_load(prev_flag)
	_free_manager(mgr)


## Tier 1.6: `posture_cohesion_targeting_mult` rises with line cohesion in LINE posture; OPEN uses inverse (looser line → higher mult).
static func _run_ai_targeting_posture_cohesion_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var fd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, pfid)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	fd["line_cohesion"] = 0.0
	var m_line_lo: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 1.0
	var m_line_hi: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_line_hi < m_line_lo + 0.001:
		_fail(
			failures,
			"ai_targeting_posture: LINE mult should increase with cohesion (lo=%.4f hi=%.4f)" % [m_line_lo, m_line_hi]
		)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	fd["line_cohesion"] = 1.0
	var m_open_tight: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 0.0
	var m_open_loose: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_open_loose < m_open_tight + 0.001:
		_fail(
			failures,
			"ai_targeting_posture: OPEN mult should increase when cohesion drops (tight=%.4f loose=%.4f)"
			% [m_open_tight, m_open_loose]
		)
	_free_manager(mgr)


## Tier 1.6: **`distributed_pressure_mult`** — ally doctrine commit to the same defender lowers **`hostile_pair_targeting_weight_mult`** for a second attacker (cached engagement-mode mult so snapshot stays stable).
static func _run_hostile_pair_distributed_pressure_ally_commit(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr.combat_clock = 10.0
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var e0: Dictionary = mgr.combatants[2]
	if _EntityAccess.side_str(p0) != "player" or _EntityAccess.side_str(p1) != "player":
		_fail(failures, "dist_pressure: expected first two combatants on player side")
		_free_manager(mgr)
		return
	if _EntityAccess.side_str(e0) != "enemy":
		_fail(failures, "dist_pressure: expected third combatant enemy")
		_free_manager(mgr)
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
		_fail(
			failures,
			"dist_pressure: distributed mult should drop when ally commits none=%.6f ally=%.6f" % [dp_none, dp_ally]
		)
	if w_after >= w_before - 1e-6:
		_fail(
			failures,
			"dist_pressure: hostile weight should drop before=%.6f after=%.6f" % [w_before, w_after]
		)
	var cnt: int = _TargetScoring.ally_pressure_count(mgr, e0id, "player", p0id)
	if cnt != 1:
		_fail(failures, "dist_pressure: expected ally_pressure_count=1 got %d" % cnt)
	p1["doctrine_target_commit_id"] = -1
	p1.erase("doctrine_commit_until")
	var dp_restored: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	if not is_equal_approx(dp_restored, dp_none):
		_fail(
			failures,
			"dist_pressure: clearing commit should restore pressure mult restored=%.6f none=%.6f"
			% [dp_restored, dp_none]
		)
	_free_manager(mgr)


## Tier 1.6 / 1.9: **`CombatTargetScoring.ally_pressure_count`** — committed rank>0 allies count only when **`AvailableActionsBuilder._melee_pair_rank_allowed`** to the committed defender ( **`depth_polearm_valid_line_threat`** for home depth vs rank-0; intruder paths unchanged).
static func _run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures: PackedStringArray) -> void:
	var mgr_near: Node = _MgrScript.new()
	mgr_near.register(_new_entity("SWORD"), "player")
	mgr_near.register(_new_entity("SPEAR"), "player")
	mgr_near.register(_new_entity("SWORD"), "enemy")
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
	if not _ActionsBuilder._melee_pair_rank_allowed(mgr_near, p1n, e0n):
		_fail(failures, "ally_press_dep: near layout expected _melee_pair_rank_allowed depth→e0")
		_free_manager(mgr_near)
		return
	_TargetScoring.on_combat_commitment(mgr_near, p1nid, e0nid)
	var cnt_near: int = _TargetScoring.ally_pressure_count(mgr_near, e0nid, "player", p0nid)
	if cnt_near != 1:
		_fail(failures, "ally_press_dep: near expected ally_pressure_count=1 got %d" % cnt_near)
	p1n["doctrine_target_commit_id"] = -1
	_free_manager(mgr_near)

	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(_new_entity("SWORD"), "player")
	mgr_far.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(_new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c2 in mgr_far.combatants:
		c2["gauge"] = 100.0
	mgr_far.combat_clock = 10.0
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_far, depth_far):
		_fail(failures, "ally_press_dep: far layout expected open depth lane")
		_free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	var e0_far: Dictionary = mgr_far.combatants[2]
	if _ActionsBuilder._melee_pair_rank_allowed(mgr_far, depth_far, e0_far):
		_fail(failures, "ally_press_dep: far enemies expected no _melee_pair_rank_allowed depth→e0")
		_free_manager(mgr_far)
		return
	var p0f: Dictionary = mgr_far.combatants[0]
	var p0fid: int = _EntityAccess.id_int(p0f)
	var e0fid: int = _EntityAccess.id_int(e0_far)
	var p1fid: int = _EntityAccess.id_int(depth_far)
	_TargetScoring.on_combat_commitment(mgr_far, p1fid, e0fid)
	var cnt_far: int = _TargetScoring.ally_pressure_count(mgr_far, e0fid, "player", p0fid)
	if cnt_far != 0:
		_fail(
			failures,
			"ally_press_dep: far-line committed depth should not count pressure got %d" % cnt_far
		)
	_free_manager(mgr_far)


## Tier 1.6: **`CombatTargetScoring.hold_lane_mult`** — **`hold_lane`** doctrine hedges listed weights vs **non**-file-opposed rank-0 pairs; file-opposed front returns **1.0**.
static func _run_targeting_hold_lane_off_file_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_off: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_off, CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT):
		_fail(
			failures,
			"hold_lane_mult: off-file expected %.4f got %.4f" % [CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT, m_off]
		)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_same: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_same, 1.0):
		_fail(failures, "hold_lane_mult: file-opposed front should be neutral got %.4f" % m_same)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var m_pinch: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, 1.0):
		_fail(failures, "hold_lane_mult: pinch doctrine should not apply hold hedge got %.4f" % m_pinch)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.hold_lane_mult(mgr, p, e), 1.0):
		_fail(failures, "hold_lane_mult: default doctrine should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.file_opposed_mult`** — same-file rank-0 pair (or depth polearm using same-file rank-0 ally) applies **`DOCTRINE_FILE_OPPOSED_WEIGHT_MULT`**; off-file → **1.0**.
static func _run_targeting_file_opposed_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var m_off: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_off, 1.0):
		_fail(failures, "file_opposed_mult: off-file rank-0 expected 1.0 got %.4f" % m_off)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_front: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_front, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		_fail(
			failures,
			"file_opposed_mult: same-file rank-0 expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_front]
		)
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.register(_new_entity("SWORD"), "enemy")
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
	if not _ActionsBuilder.depth_polearm_lane_open(mgr2, depth):
		_fail(failures, "file_opposed_mult_depth: expected depth spear lane open")
		_free_manager(mgr2)
		return
	var m_depth_same: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_same)
	if not is_equal_approx(m_depth_same, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		_fail(
			failures,
			"file_opposed_mult_depth: front ally file-opposed expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_depth_same]
		)
	var m_depth_off: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_off)
	if not is_equal_approx(m_depth_off, 1.0):
		_fail(failures, "file_opposed_mult_depth: off-file enemy expected 1.0 got %.4f" % m_depth_off)
	_free_manager(mgr2)


## Tier 1.6: **`CombatTargetScoring.pinch_score_mult`** — **`pinch_center`** + **`wing_lacks_file_opposed`** nudges weight toward enemies nearer the hostile line center ( **`DOCTRINE_PINCH_INWARD_BIAS_PER_FILE`** ).
static func _run_targeting_pinch_center_inward_bonus(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	if not _TargetScoring.wing_lacks_file_opposed(mgr, p):
		_fail(failures, "pinch_bonus: expected wing_lacks_file_opposed for off-file rank-0 pair")
		_free_manager(mgr)
		return
	var inward: float = absf(float(_EntityAccess.file_int(e)) - 1.0)
	var want: float = 1.0 + CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
	var m_pinch: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, want):
		_fail(failures, "pinch_bonus: expected %.6f got %.6f (inward=%.4f)" % [want, m_pinch, inward])
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_opposed: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_opposed, 1.0):
		_fail(failures, "pinch_bonus: file-opposed front should suppress pinch got %.4f" % m_opposed)
	e["file"] = 1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_hold_doc: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_hold_doc, 1.0):
		_fail(failures, "pinch_bonus: hold_lane doctrine should not apply pinch inward got %.4f" % m_hold_doc)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.pinch_score_mult(mgr, p, e), 1.0):
		_fail(failures, "pinch_bonus: default doctrine should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.commitment_match_mult`** after **`on_combat_commitment`** ( **`DOCTRINE_COMMIT_MATCH_WEIGHT_MULT`** ).
static func _run_targeting_commitment_match_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	p["doctrine_target_commit_id"] = -1
	var m_neutral: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_neutral, 1.0):
		_fail(failures, "commit_match: no commit should be 1.0 got %.4f" % m_neutral)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	var m_match: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_match, CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		_fail(
			failures,
			"commit_match: expected %.4f got %.4f" % [CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT, m_match]
		)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid + 9999), 1.0):
		_fail(failures, "commit_match: wrong target id should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.soft_geometry_score`** = **`1/(1 + effective_pair_eff_dist × DOCTRINE_SOFT_DISTANCE_SCALE)`**; larger eff → lower score (monotone).
static func _run_targeting_soft_geometry_eff_dist_formula(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	if _EntityAccess.side_str(p) != "player":
		_fail(failures, "soft_geom: expected combatants[0] player")
		_free_manager(mgr)
		return
	if _EntityAccess.side_str(e0) != "enemy" or _EntityAccess.side_str(e1) != "enemy":
		_fail(failures, "soft_geom: expected combatants[1–2] enemy")
		_free_manager(mgr)
		return
	p["file"] = 1
	p["rank"] = 0
	e0["file"] = 0
	e0["rank"] = 0
	e1["file"] = 2
	e1["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var eff0: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p, e0)
	var eff1: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p, e1)
	var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
	var s0: float = _TargetScoring.soft_geometry_score(mgr, p, e0)
	var s1: float = _TargetScoring.soft_geometry_score(mgr, p, e1)
	var want0: float = 1.0 / (1.0 + eff0 * k)
	var want1: float = 1.0 / (1.0 + eff1 * k)
	if not is_equal_approx(s0, want0):
		_fail(failures, "soft_geom: pair0 formula want %.6f got %.6f eff=%.4f" % [want0, s0, eff0])
	if not is_equal_approx(s1, want1):
		_fail(failures, "soft_geom: pair1 formula want %.6f got %.6f eff=%.4f" % [want1, s1, eff1])
	if absf(eff0 - eff1) > 0.02:
		if eff0 < eff1 and not (s0 > s1 + 1e-5):
			_fail(
				failures,
				"soft_geom: lower eff should score higher eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
			)
		if eff0 > eff1 and not (s0 < s1 - 1e-5):
			_fail(
				failures,
				"soft_geom: higher eff should score lower eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
			)
	_free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears stale **`doctrine_target_commit_id`** after **`doctrine_commit_until`** vs **`combat_clock`**.
static func _run_targeting_prune_expired_doctrine_commitment(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		_fail(failures, "prune_commit: expected match mult after on_combat_commitment")
	mgr.combat_clock = float(p.get("doctrine_commit_until", 0.0)) + 0.25
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "prune_commit: expected doctrine_target_commit_id cleared after expiry")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		_fail(failures, "prune_commit: commitment_match_mult should be neutral after prune")
	_free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears doctrine commit when the **committed target** is no longer alive (before clock expiry).
static func _run_targeting_prune_commitment_when_target_dies(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if int(p.get("doctrine_target_commit_id", -2)) != eid:
		_fail(failures, "prune_dead_tgt: expected live commit before kill")
	e["alive"] = false
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "prune_dead_tgt: expected commit cleared when target dies")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		_fail(failures, "prune_dead_tgt: commitment_match_mult should be neutral after dead-target prune")
	_free_manager(mgr)


## Tier 1.6: **`clear_all_targeting_state_for_dead_defender`** (death hook) clears **all** allies’ doctrine commits and **close_block** rows keyed to the dead defender.
static func _run_targeting_clear_all_state_for_dead_defender(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(failures, "clear_dead_def: expected both allies committed to dead target id")
	var blk0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	blk0[eid] = 999.0
	p0["close_block_until_by_target_id"] = blk0
	var blk1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	blk1[eid] = 888.0
	p1["close_block_until_by_target_id"] = blk1
	_TargetScoring.clear_all_targeting_state_for_dead_defender(mgr, eid)
	if int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "clear_dead_def: expected doctrine_target_commit_id cleared for both allies")
	var b0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	var b1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	if b0.has(eid) or b1.has(eid):
		_fail(failures, "clear_dead_def: expected close_block_until_by_target_id entries for dead id erased")
	_free_manager(mgr)


## Tier 1.6 breadth: `opponent_formation_targeting_mult` — solid enemy LINE hedges listed weights; ragged LINE presses; OPEN uses fixed nudge.
static func _run_ai_targeting_opponent_formation_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var opp: Dictionary = mgr.combatants[1]
	var efid: String = _EntityAccess.formation_id_str(opp)
	var efd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, efid)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	efd["line_cohesion"] = 1.0
	var m_solid: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	efd["line_cohesion"] = 0.0
	var m_ragged: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if m_solid >= m_ragged - 0.001:
		_fail(
			failures,
			"ai_targeting_opp_form: LINE solid should hedge vs ragged (solid=%.4f ragged=%.4f)" % [m_solid, m_ragged]
		)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var m_open: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if not is_equal_approx(m_open, CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT):
		_fail(
			failures,
			"ai_targeting_opp_form: OPEN expected %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT, m_open]
		)
	_free_manager(mgr)


## Tier 1.6 breadth: `opponent_breach_file_targeting_mult` — higher listed weight vs enemies on a breached file column.
static func _run_ai_targeting_breach_file_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1, "density": "normal"})
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	if _EntityAccess.file_int(e0) != 0 or _EntityAccess.file_int(e1) != 1:
		_fail(failures, "ai_targeting_breach: expected enemy files 0 and 1")
	var efid: String = _EntityAccess.formation_id_str(e0)
	var efd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, efid)
	efd["breached_files"] = {0: 1.0}
	var m_clean: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e1)
	var m_breach: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e0)
	if not is_equal_approx(m_clean, 1.0):
		_fail(
			failures,
			"ai_targeting_breach: unbreached file mult should be 1.0 got %.4f" % m_clean
		)
	if m_breach <= m_clean + 0.001:
		_fail(
			failures,
			"ai_targeting_breach: breached file should raise mult (breach=%.4f clean=%.4f)" % [m_breach, m_clean]
		)
	if not is_equal_approx(m_breach, CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX):
		_fail(
			failures,
			"ai_targeting_breach: full severity want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX, m_breach]
		)
	efd["breached_files"] = {0: 0.5}
	var m_half: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e0)
	var want_half: float = lerpf(1.0, CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX, 0.5)
	if not is_equal_approx(m_half, want_half):
		_fail(
			failures,
			"ai_targeting_breach: half severity want %.4f got %.4f" % [want_half, m_half]
		)
	_free_manager(mgr)


## Tier 1.6: **`formation_dict_cache`** on **`opponent_formation_targeting_mult`**, **`opponent_breach_file_targeting_mult`**, **`posture_cohesion_targeting_mult`** matches live **`ZoneOfControl.formation_dict_for_zone_geometry`**.
static func _run_targeting_formation_dict_cache_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var opp: Dictionary = mgr.combatants[1]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var pfd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, pfid)
	pfd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	pfd["line_cohesion"] = 0.42
	var ofid: String = _EntityAccess.formation_id_str(opp)
	var ofd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, ofid)
	ofd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	ofd["line_cohesion"] = 0.61
	ofd["breached_files"] = {0: 0.75}
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var fd_p: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, p)
	var fd_o: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, opp)
	var m_pc_l: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	var m_pc_c: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p, fd_p)
	if not is_equal_approx(m_pc_l, m_pc_c):
		_fail(
			failures,
			"tgt_fd_cache: posture_cohesion live %.6f vs cache %.6f" % [m_pc_l, m_pc_c]
		)
	var m_of_l: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	var m_of_c: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp, fd_o)
	if not is_equal_approx(m_of_l, m_of_c):
		_fail(
			failures,
			"tgt_fd_cache: opponent_formation live %.6f vs cache %.6f" % [m_of_l, m_of_c]
		)
	var m_br_l: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, opp)
	var m_br_c: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, opp, fd_o)
	if not is_equal_approx(m_br_l, m_br_c):
		_fail(
			failures,
			"tgt_fd_cache: opponent_breach live %.6f vs cache %.6f" % [m_br_l, m_br_c]
		)
	_free_manager(mgr)


## Tier 1.6 / 1.7: `engagement_mode_targeting_mult` tracks resolved duel / skirmish / formation.
static func _run_ai_targeting_engagement_mode_mult(failures: PackedStringArray) -> void:
	var d: Node = _MgrScript.new()
	d.register(_new_entity("SWORD"), "player")
	d.register(_new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if _EngagementMode.engagement_mode(d) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(
			failures,
			"ai_targeting_eng_mode: expected duel for 1v1 got %s" % _EngagementMode.engagement_mode(d)
		)
	var m_duel: float = _TargetScoring.engagement_mode_targeting_mult(d)
	if not is_equal_approx(m_duel, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: duel mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT, m_duel]
		)
	_free_manager(d)
	var s: Node = _MgrScript.new()
	for _i in 3:
		s.register(_new_entity("SWORD"), "player")
	for _j in 3:
		s.register(_new_entity("SWORD"), "enemy")
	s.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(s).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		_fail(
			failures,
			"ai_targeting_eng_mode: 3v3 expected raw skirmish got %s"
			% str(_EngagementMode.snapshot(s).get("raw_mode", ""))
		)
	var m_sk: float = _TargetScoring.engagement_mode_targeting_mult(s)
	if not is_equal_approx(m_sk, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: skirmish mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT, m_sk]
		)
	_free_manager(s)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(_new_entity("SWORD"), "player")
	for _j in 4:
		f.register(_new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	if _EngagementMode.engagement_mode(f) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(
			failures,
			"ai_targeting_eng_mode: expected formation for 4v4 line got %s"
			% _EngagementMode.engagement_mode(f)
		)
	var m_form: float = _TargetScoring.engagement_mode_targeting_mult(f)
	if not is_equal_approx(m_form, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: formation mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT, m_form]
		)
	_free_manager(f)


## Tier 1.6: **`hostile_pair_targeting_weight_mult`** — passing **`engagement_mode_targeting_mult(manager)`** as **`cached_engagement_mode_targeting_mult`** matches the **null** overload (same snapshot).
static func _run_hostile_pair_cached_engagement_mode_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(
			failures,
			"hostile_pair_em_cache: live %.8f vs cached-arg %.8f (em=%.8f)" % [w_live, w_cached, em]
		)
	_free_manager(mgr)


## Tier 3.1: depth spear lane parry mults in `DefenseChoiceResolver` (tight → `parry_c_d`; open + stab → `parry_p_a`).
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
		_fail(
			failures,
			"depth_spear_parry_mult: expected 1.0 for non-depth or open lane got m0=%.4f m_open=%.4f" % [m0, m_open]
		)
	if not is_equal_approx(m_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
		_fail(
			failures,
			"depth_spear_parry_mult: tight lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_tight]
		)
	if not is_equal_approx(m_empty_allows, 1.0):
		_fail(
			failures,
			"depth_spear_parry_mult: empty lane_type + allows_low should follow open got %.4f" % m_empty_allows
		)
	if not is_equal_approx(m_empty_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
		_fail(
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
		_fail(
			failures,
			"depth_spear_parry_p_a: open+stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_stab]
		)
	if not is_equal_approx(a_legacy_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		_fail(
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
		_fail(
			failures,
			"depth_spear_parry_p_a: explicit open lane id should win over allows_low=false got %.4f"
			% a_open_id_over_allows
		)
	if not is_equal_approx(a_tight_stab, 1.0) or not is_equal_approx(a_slash, 1.0) or not is_equal_approx(a0, 1.0):
		_fail(
			failures,
			"depth_spear_parry_p_a: expected 1.0 for tight stab / open slash / non-depth got tight=%.4f slash=%.4f a0=%.4f"
			% [a_tight_stab, a_slash, a0]
		)


## Tier 3.1: **`CombatConstants.STRIKE_MEASURE_*`** drive **`strike_measure_ratio_for_weapon_eff_dist`** (formula lock).
static func _run_strike_measure_constants_sanity(failures: PackedStringArray) -> void:
	var w: Weapon = _Weapon.create_from_definition("SWORD")
	if w == null:
		_fail(failures, "strike_meas_const: missing SWORD weapon")
		return
	var eff_in: float = 1.0
	var got: float = _ActionsBuilder.strike_measure_ratio_for_weapon_eff_dist(w, eff_in)
	var eff: float = maxf(eff_in, CombatConstants.STRIKE_MEASURE_EFF_DIST_FLOOR)
	var melee: float = w.melee_range
	var want: float = clampf(
		melee / eff, CombatConstants.STRIKE_MEASURE_RATIO_MIN, CombatConstants.STRIKE_MEASURE_RATIO_MAX
	)
	if not is_equal_approx(got, want):
		_fail(
			failures,
			"strike_meas_const: got %.4f want %.4f (melee=%.3f eff_floor=%.3f)"
			% [got, want, melee, eff]
		)


## Tier 3.1: `AvailableActionsBuilder.stamp_attack_pair_geometry_on_dict` via wind-up (re-stamped each resolve).
## Covers rank-0, depth 1-file line, and depth vs 3-wide enemy frontage (stamp vs live builder).
static func _run_windup_pending_attack_pair_geometry(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p0_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_WindUpStarter.start(mgr, p0_id, e0_id, "thrust")
	var comb_pa0: Variant = mgr._get_by_id(p0_id)
	var pa0: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa0 if comb_pa0 is Dictionary else {}, "pending_attack")
	if pa0.is_empty():
		_fail(failures, "windup_geom: empty pending_attack (rank0)")
	else:
		if not pa0.has("effective_pair_file_spacing_equivalent") or not pa0.has("effective_pair_eff_dist"):
			_fail(failures, "windup_geom: rank0 missing spacing keys")
		var p0: Dictionary = mgr.combatants[0]
		var e0: Dictionary = mgr.combatants[1]
		var want_eff0: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p0, e0)
		var want_space0: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e0)
		if not is_equal_approx(float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0):
			_fail(
				failures,
				"windup_geom: rank0 eff_dist stamp %.4f vs builder %.4f"
				% [float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0]
			)
		if not is_equal_approx(float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0):
			_fail(
				failures,
				"windup_geom: rank0 file_spacing_eq stamp %.4f vs builder %.4f"
				% [float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0]
			)
		var w0: Variant = _EntityAccess.get_weapon(p0)
		if w0 != null:
			var want_meas0: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr, p0, e0, w0, want_eff0)
			if not is_equal_approx(float(pa0.get("strike_measure_ratio", -9.0)), want_meas0):
				_fail(
					failures,
					"windup_geom: rank0 strike_measure_ratio %.4f vs eff-keyed measure %.4f"
					% [float(pa0.get("strike_measure_ratio", -9.0)), want_meas0]
				)
		if bool(pa0.get("depth_polearm_attack", true)):
			_fail(failures, "windup_geom: rank0 must not set depth_polearm_attack")
		if str(pa0.get("depth_polearm_lane_type", "")) != "":
			_fail(failures, "windup_geom: rank0 must not set depth_polearm_lane_type")
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 2, "density": "loose"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr2._recompute_zoc_and_distance()
	var depth: Dictionary = mgr2.combatants[1]
	var en: Dictionary = mgr2.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr2, depth):
		_fail(failures, "windup_geom: expected depth polearm lane open")
	else:
		var d_id: int = _EntityAccess.id_int(depth)
		var en_id: int = _EntityAccess.id_int(en)
		_WindUpStarter.start(mgr2, d_id, en_id, "spear_thrust")
		var comb_pa1: Variant = mgr2._get_by_id(d_id)
		var pa1: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa1 if comb_pa1 is Dictionary else {}, "pending_attack")
		if pa1.is_empty():
			_fail(failures, "windup_geom: empty pending_attack (depth)")
		elif not pa1.has("effective_pair_file_spacing_equivalent") or not pa1.has("effective_pair_eff_dist"):
			_fail(failures, "windup_geom: depth missing spacing keys")
		elif not bool(pa1.get("depth_polearm_attack", false)):
			_fail(failures, "windup_geom: depth spear should set depth_polearm_attack")
		else:
			var want_eff1: float = _ActionsBuilder.effective_pair_eff_dist(mgr2, depth, en)
			var want_space1: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr2, depth, en)
			if not is_equal_approx(float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1):
				_fail(
					failures,
					"windup_geom: depth eff_dist stamp %.4f vs builder %.4f"
					% [float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1]
				)
			if not is_equal_approx(float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1):
				_fail(
					failures,
					"windup_geom: depth file_spacing_eq stamp %.4f vs builder %.4f"
					% [float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1]
				)
			var want_allow: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr2, depth)
			if bool(pa1.get("depth_polearm_allows_low_targets", not want_allow)) != want_allow:
				_fail(
					failures,
					"windup_geom: depth_polearm_allows_low_targets=%s want %s"
					% [str(pa1.get("depth_polearm_allows_low_targets")), str(want_allow)]
				)
			var want_lane: String = "open" if want_allow else "over_shoulder"
			if str(pa1.get("depth_polearm_lane_type", "")) != want_lane:
				_fail(
					failures,
					"windup_geom: depth_polearm_lane_type=%s want %s"
					% [str(pa1.get("depth_polearm_lane_type")), want_lane]
				)
			var w1: Variant = _EntityAccess.get_weapon(depth)
			if w1 != null:
				var want_meas1: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr2, depth, en, w1, want_eff1)
				if not is_equal_approx(float(pa1.get("strike_measure_ratio", -9.0)), want_meas1):
					_fail(
						failures,
						"windup_geom: depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
						% [float(pa1.get("strike_measure_ratio", -9.0)), want_meas1]
					)
	_free_manager(mgr2)

	# 3-wide enemy line: stamped `effective_pair_*` must still match builder (wedge/lane/ZoC path stress).
	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr3._recompute_zoc_and_distance()
	var depth3: Dictionary = mgr3.combatants[1]
	var en30: Dictionary = mgr3.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr3, depth3):
		_fail(failures, "windup_geom: 3-file enemy expected depth polearm lane open")
	elif not _ActionsBuilder.can_melee_threaten(mgr3, depth3, en30):
		_fail(failures, "windup_geom: 3-file enemy depth should melee-threaten file-opposed rank-0")
	else:
		var d3_id: int = _EntityAccess.id_int(depth3)
		var e3_id: int = _EntityAccess.id_int(en30)
		_WindUpStarter.start(mgr3, d3_id, e3_id, "spear_thrust")
		var comb_pa3: Variant = mgr3._get_by_id(d3_id)
		var pa3: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa3 if comb_pa3 is Dictionary else {}, "pending_attack")
		if pa3.is_empty():
			_fail(failures, "windup_geom: empty pending_attack (depth 3-file line)")
		elif not bool(pa3.get("depth_polearm_attack", false)):
			_fail(failures, "windup_geom: depth 3-file should set depth_polearm_attack")
		else:
			var want_eff3: float = _ActionsBuilder.effective_pair_eff_dist(mgr3, depth3, en30)
			var want_space3: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr3, depth3, en30)
			if not is_equal_approx(float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3):
				_fail(
					failures,
					"windup_geom: 3-file depth eff_dist stamp %.4f vs builder %.4f"
					% [float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3]
				)
			if not is_equal_approx(float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3):
				_fail(
					failures,
					"windup_geom: 3-file depth file_spacing_eq stamp %.4f vs builder %.4f"
					% [
						float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)),
						want_space3
					]
				)
			var w3: Variant = _EntityAccess.get_weapon(depth3)
			if w3 != null:
				var want_meas3: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr3, depth3, en30, w3, want_eff3)
				if not is_equal_approx(float(pa3.get("strike_measure_ratio", -9.0)), want_meas3):
					_fail(
						failures,
						"windup_geom: 3-file depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
						% [float(pa3.get("strike_measure_ratio", -9.0)), want_meas3]
					)
	_free_manager(mgr3)


## `AttackResultApplier`: terminal outcomes clear `pending_attack` (defeated / miss / dodge / skip).
static func _run_attack_result_applier_terminal_clears_pending(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	p.state = CombatConstants.STATE_WIND_UP
	p.pending_attack = {"target_id": e_id, "attack_type": "thrust", "intensity": 0.5}
	_AttackResultApplier.apply_result(
		mgr,
		p_id,
		{"action": "defeated", "target_id": e_id}
	)
	if not _EntityAccess.nested_dictionary_read(p, "pending_attack").is_empty():
		_fail(failures, "result_applier: defeated should clear attacker pending_attack")
	if _EntityAccess.state_str(p) != CombatConstants.STATE_WAITING:
		_fail(
			failures,
			"result_applier: defeated attacker should be WAITING got %s" % _EntityAccess.state_str(p)
		)
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p2: Dictionary = mgr2.combatants[0]
	var e2: Dictionary = mgr2.combatants[1]
	var p2_id: int = _EntityAccess.id_int(p2)
	var e2_id: int = _EntityAccess.id_int(e2)
	p2.state = CombatConstants.STATE_WIND_UP
	p2.pending_attack = {
		"target_id": e2_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high"
	}
	_AttackResultApplier.apply_result(
		mgr2,
		p2_id,
		{"action": "miss", "target_id": e2_id, "recovery_duration": 0.35}
	)
	if not _EntityAccess.nested_dictionary_read(p2, "pending_attack").is_empty():
		_fail(failures, "result_applier: miss should clear attacker pending_attack")
	if str(p2.get("last_move_id", "")) != "thrust":
		_fail(failures, "result_applier: miss should set last_move_id from pending thrust")
	if _EntityAccess.state_str(p2) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: miss attacker should be RECOVERING got %s" % _EntityAccess.state_str(p2)
		)
	_free_manager(mgr2)

	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p3: Dictionary = mgr3.combatants[0]
	var e3: Dictionary = mgr3.combatants[1]
	var p3_id: int = _EntityAccess.id_int(p3)
	var e3_id: int = _EntityAccess.id_int(e3)
	p3.state = CombatConstants.STATE_WIND_UP
	p3.pending_attack = {"target_id": e3_id, "attack_type": "slash", "intensity": 0.5, "effective_attack_line": "left"}
	_AttackResultApplier.apply_result(
		mgr3,
		p3_id,
		{"action": "dodge", "target_id": e3_id, "recovery_duration": 0.4}
	)
	if not _EntityAccess.nested_dictionary_read(p3, "pending_attack").is_empty():
		_fail(failures, "result_applier: dodge should clear attacker pending_attack")
	if _EntityAccess.state_str(p3) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: dodge attacker should be RECOVERING got %s" % _EntityAccess.state_str(p3)
		)
	_free_manager(mgr3)

	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	mgr4.register(_new_entity("SWORD"), "enemy")
	mgr4.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p4: Dictionary = mgr4.combatants[0]
	var e4: Dictionary = mgr4.combatants[1]
	var p4_id: int = _EntityAccess.id_int(p4)
	var e4_id: int = _EntityAccess.id_int(e4)
	p4.state = CombatConstants.STATE_WIND_UP
	p4.pending_attack = {"target_id": e4_id, "attack_type": "thrust", "intensity": 0.5}
	_AttackResultApplier.apply_result(
		mgr4,
		p4_id,
		{"action": "skip", "target_id": e4_id, "recovery_duration": 0.28}
	)
	if not _EntityAccess.nested_dictionary_read(p4, "pending_attack").is_empty():
		_fail(failures, "result_applier: skip+recovery should clear attacker pending_attack")
	if _EntityAccess.state_str(p4) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: skip+recovery attacker should be RECOVERING got %s" % _EntityAccess.state_str(p4)
		)
	_free_manager(mgr4)

	var mgr5: Node = _MgrScript.new()
	mgr5.register(_new_entity("SWORD"), "player")
	mgr5.register(_new_entity("SWORD"), "enemy")
	mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p5: Dictionary = mgr5.combatants[0]
	var e5_id: int = _EntityAccess.id_int(mgr5.combatants[1])
	var p5_id: int = _EntityAccess.id_int(p5)
	p5.state = CombatConstants.STATE_WIND_UP
	p5.pending_attack = {"target_id": e5_id, "attack_type": "slash", "intensity": 0.5}
	_AttackResultApplier.apply_result(mgr5, p5_id, {"action": "skip", "target_id": e5_id, "recovery_duration": 0.0})
	if not _EntityAccess.nested_dictionary_read(p5, "pending_attack").is_empty():
		_fail(failures, "result_applier: skip no-recovery should clear attacker pending_attack")
	if _EntityAccess.state_str(p5) != CombatConstants.STATE_WAITING:
		_fail(
			failures,
			"result_applier: skip no-recovery attacker should be WAITING got %s" % _EntityAccess.state_str(p5)
		)
	_free_manager(mgr5)


## **`AttackResultApplier`**: **`parry_deflect`** → **`action_resolved`** payload includes resolver **`parry_clash_context`** (signal args: defender id, attacker id, **`BattleScene`** slot names reversed).
static func _run_action_resolved_parry_deflect_payload_includes_clash_context(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	var captured: Array = []
	mgr.action_resolved.connect(
		func(first_id: int, second_id: int, res: Dictionary) -> void:
			captured.clear()
			captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
	)
	e["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5}
	var pclash: Dictionary = {"kinematic_delivery": "thrust", "strike_measure_ratio": 1.05, "parry_control": 0.41}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{"action": "parry_deflect", "target_id": p_id, "recovery_duration": 0.45, "parry_clash_context": pclash}
	)
	if captured.is_empty():
		_fail(failures, "parry_resolve_emit: expected action_resolved")
		_free_manager(mgr)
		return
	var slot: Dictionary = captured[0] as Dictionary
	if int(slot.get("first", -99)) != p_id:
		_fail(
			failures,
			"parry_resolve_emit: first signal arg should be defender id %d got %d" % [p_id, int(slot.get("first", -99))]
		)
	if int(slot.get("second", -99)) != e_id:
		_fail(
			failures,
			"parry_resolve_emit: second signal arg should be attacker id %d got %d" % [e_id, int(slot.get("second", -99))]
		)
	var res: Dictionary = slot.get("res", {}) as Dictionary
	if str(res.get("outcome", "")) != "parry_deflect":
		_fail(failures, "parry_resolve_emit: outcome want parry_deflect got %s" % str(res.get("outcome", "")))
	var ctx: Variant = res.get("parry_clash_context", null)
	if not (ctx is Dictionary):
		_fail(failures, "parry_resolve_emit: missing parry_clash_context on resolved payload")
		_free_manager(mgr)
		return
	var cd: Dictionary = ctx as Dictionary
	if str(cd.get("kinematic_delivery", "")) != "thrust":
		_fail(failures, "parry_resolve_emit: clash kinematic_delivery mismatch")
	if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
		_fail(failures, "parry_resolve_emit: strike_measure_ratio mismatch")
	if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
		_fail(failures, "parry_resolve_emit: parry_control mismatch")
	_free_manager(mgr)


## **`AttackResultApplier`**: first **`action_resolved`** on **`parry_partial`** is defender, attacker, payload with **`parry_clash_context`** (nested **`_execute_attack`** may append further rows).
static func _run_action_resolved_parry_partial_payload_includes_clash_context(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	var captured: Array = []
	mgr.action_resolved.connect(
		func(first_id: int, second_id: int, res: Dictionary) -> void:
			captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
	)
	e["pending_attack"] = {"target_id": p_id, "attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5}
	var pclash: Dictionary = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.05,
		"parry_control": 0.41,
		"remaining_ratio": 0.33
	}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
	)
	if captured.is_empty():
		_fail(failures, "parry_partial_resolve_emit: expected at least one action_resolved")
		_free_manager(mgr)
		return
	var slot: Dictionary = captured[0] as Dictionary
	if int(slot.get("first", -99)) != p_id:
		_fail(
			failures,
			"parry_partial_resolve_emit: first signal arg should be defender id %d got %d" % [p_id, int(slot.get("first", -99))]
		)
	if int(slot.get("second", -99)) != e_id:
		_fail(
			failures,
			"parry_partial_resolve_emit: second signal arg should be attacker id %d got %d" % [e_id, int(slot.get("second", -99))]
		)
	var res: Dictionary = slot.get("res", {}) as Dictionary
	if str(res.get("outcome", "")) != "parry_partial":
		_fail(
			failures,
			"parry_partial_resolve_emit: first outcome want parry_partial got %s" % str(res.get("outcome", ""))
		)
	var ctx: Variant = res.get("parry_clash_context", null)
	if not (ctx is Dictionary):
		_fail(failures, "parry_partial_resolve_emit: missing parry_clash_context on first payload")
		_free_manager(mgr)
		return
	var cd: Dictionary = ctx as Dictionary
	if str(cd.get("kinematic_delivery", "")) != "thrust":
		_fail(failures, "parry_partial_resolve_emit: clash kinematic_delivery mismatch")
	if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: strike_measure_ratio mismatch")
	if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: parry_control mismatch")
	if absf(float(cd.get("remaining_ratio", 0.0)) - 0.33) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: remaining_ratio mismatch")
	_free_manager(mgr)


## **`AttackResultApplier`**: **`hit`** erases **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the striker (stale calibration after **`parry_partial`** follow-through).
static func _run_hit_clears_attacker_parry_calibration_fields(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	p.state = CombatConstants.STATE_WAITING
	p.pending_attack = {}
	e.state = CombatConstants.STATE_WIND_UP
	e.pending_attack = {
		"target_id": p_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high",
	}
	e["parry_clash_context"] = {"kinematic_delivery": "thrust", "parry_control": 0.5}
	e["defender_guard_line_at_parry"] = "high"
	var rd: Dictionary = {
		"dmg": 2,
		"died": false,
		"part": "chest",
		"outcome": "hit",
		"damage_type": "cut",
		"health_before": 100,
		"health_after": 98,
		"final_cut": 1.0,
		"final_blunt": 1.0,
		"final_bone": 0.0,
		"total_physical": 2.0,
	}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{
			"action": "hit",
			"target_id": p_id,
			"intensity": 0.2,
			"recovery_duration": 0.45,
			"result_dict": rd,
		}
	)
	if e.has("parry_clash_context"):
		_fail(failures, "hit_clear_parry: attacker should not retain parry_clash_context after hit")
	if e.has("defender_guard_line_at_parry"):
		_fail(failures, "hit_clear_parry: attacker should not retain defender_guard_line_at_parry after hit")
	_free_manager(mgr)


## **`parry_partial`**: defender **`parry_was_bind`** / **`parry_against_id`** when alignment ≥ partial threshold and clash **`parry_control`** crosses bind threshold; cleared when misaligned or control low (misaligned path **`erase`**s stale **`parry_was_bind`**).
static func _run_parry_partial_bind_riposte_flags_when_aligned(failures: PackedStringArray) -> void:
	var _apply_partial_bind := func(
		attack_angle_deg: float,
		parry_control: float,
		expect_bind: bool,
		label: String,
		seed_stale_bind: bool = false,
		misaligned_erase_bind_key: bool = false
	) -> void:
		var mgr: Node = _MgrScript.new()
		mgr.register(_new_entity("SWORD"), "player")
		mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
		var p: Dictionary = mgr.combatants[0]
		var e: Dictionary = mgr.combatants[1]
		var p_id: int = _EntityAccess.id_int(p)
		var e_id: int = _EntityAccess.id_int(e)
		p.state = CombatConstants.STATE_WAITING
		p["guard"] = 1.0
		p["guard_line"] = "high"
		p.pending_attack = {}
		if seed_stale_bind:
			p["parry_was_bind"] = true
			p["parry_against_id"] = e_id
			p["parry_bonus_until"] = 1.0e9
		e.state = CombatConstants.STATE_WIND_UP
		e.pending_attack = {
			"target_id": p_id,
			"attack_type": "thrust",
			"effective_attack_line": "high",
			"attack_angle_deg": attack_angle_deg,
			"intensity": 0.5,
		}
		var pclash: Dictionary = {"parry_control": parry_control, "archetype_id": "stab"}
		_AttackResultApplier.apply_result(
			mgr,
			e_id,
			{"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
		)
		if expect_bind:
			if not bool(p.get("parry_was_bind", false)):
				_fail(
					failures,
					"parry_partial_bind %s: parry_was_bind want true got %s"
					% [label, str(p.get("parry_was_bind", false))]
				)
			if int(p.get("parry_against_id", -99)) != e_id:
				_fail(
					failures,
					"parry_partial_bind %s: parry_against_id want %d got %s"
					% [label, e_id, str(p.get("parry_against_id", -99))]
				)
			if not p.has("parry_bonus_until"):
				_fail(failures, "parry_partial_bind %s: expected parry_bonus_until set" % label)
		else:
			if p.has("parry_against_id"):
				_fail(
					failures,
					"parry_partial_bind %s: expected no parry_against_id got %s"
					% [label, str(p.get("parry_against_id", -99))]
				)
			if p.has("parry_bonus_until"):
				_fail(failures, "parry_partial_bind %s: expected no parry_bonus_until" % label)
			if misaligned_erase_bind_key:
				if p.has("parry_was_bind"):
					_fail(
						failures,
						"parry_partial_bind %s: expected parry_was_bind erased (misaligned / stale clear)"
						% label
					)
			else:
				if not p.has("parry_was_bind") or bool(p["parry_was_bind"]):
					_fail(
						failures,
						"parry_partial_bind %s: want parry_was_bind key false got has=%s val=%s"
						% [label, str(p.has("parry_was_bind")), str(p.get("parry_was_bind", "<absent>"))]
					)
		_free_manager(mgr)

	_apply_partial_bind.call(0.0, 0.9, true, "aligned_high_control", false, false)
	_apply_partial_bind.call(0.0, 0.5, false, "aligned_low_control", false, false)
	_apply_partial_bind.call(90.0, 0.9, false, "misaligned_high_control", false, true)
	_apply_partial_bind.call(90.0, 0.9, false, "misaligned_clears_stale_bind", true, true)


## Tier 3.1: `StrikePhysics.depth_polearm_thrust_closing_factor` — depth lane + stab only.
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
		_fail(
			failures,
			"depth_spear_closing: expected 1.0 for empty / non-stab got f0=%.4f f_cut=%.4f" % [f0, f_cut]
		)
	if not is_equal_approx(f_stab, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab]
		)
	if not is_equal_approx(f_stab_open, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: stab+open lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open]
		)
	if not is_equal_approx(f_stab_tight, 1.0):
		_fail(failures, "depth_spear_closing: stab+tight lane want 1.0 got %.4f" % f_stab_tight)
	if not is_equal_approx(f_stab_shoulder_overrides_allows, 1.0):
		_fail(
			failures,
			"depth_spear_closing: over_shoulder lane id must override allows_low=true got %.4f"
			% f_stab_shoulder_overrides_allows
		)
	if not is_equal_approx(f_stab_empty_tight, 1.0):
		_fail(failures, "depth_spear_closing: empty lane + allows_low false want 1.0 got %.4f" % f_stab_empty_tight)
	if not is_equal_approx(f_stab_garbage_tight, 1.0):
		_fail(failures, "depth_spear_closing: unknown lane + allows_low false want 1.0 got %.4f" % f_stab_garbage_tight)
	if not is_equal_approx(f_stab_open_ignores_allows, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: explicit open lane should ignore allows_low want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open_ignores_allows]
		)


## Tier 1.6: **`ordered_melee_opponents`** — **`is_melee_file_opposed_priority`** sorts **before** **`hostile_pair_targeting_weight_mult`** (same-file rank-0 line pair ahead of lateral rank-0).
static func _run_ordered_melee_opponents_file_opposed_sort(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e_same: Dictionary = {}
	var e_off: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
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
		_fail(failures, "melee_order_fo: need >=2 rank0 opponents got %d" % ordered.size())
		_free_manager(mgr)
		return
	var want_id: int = _EntityAccess.id_int(e_same, -998)
	if _EntityAccess.id_int(ordered[0], -999) != want_id:
		var w_same: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_same)
		var w_off: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_off)
		var id_list: Array = []
		for x in ordered:
			id_list.append(_EntityAccess.id_int(x, -1))
		_fail(
			failures,
			"melee_order_fo: file-opposed enemy id=%d should sort first got order=%s w_same=%.4f w_off=%.4f"
			% [want_id, str(id_list), w_same, w_off]
		)
	_free_manager(mgr)


## Tier 1.6: `ordered_melee_opponents` tiebreak uses full hostile weight (committed doctrine target first when file-opposed ties).
static func _run_ordered_melee_opponents_commitment_tiebreak(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e1: Dictionary = {}
	var e2: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
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
		_fail(failures, "melee_order_commit: ordered list empty")
	else:
		var first_id: int = _EntityAccess.id_int(ordered[0], -999)
		if first_id != e1id:
			var id_list: Array = []
			for x in ordered:
				id_list.append(_EntityAccess.id_int(x, -1))
			_fail(
				failures,
				"melee_order_commit: expected committed opponent first got first_id=%d want e1=%d order=%s"
				% [first_id, e1id, str(id_list)]
			)
	_free_manager(mgr)


## Tier 4.1: `stance_ai_targeting_mult` orders defensive < balanced < aggressive.
static func _run_ai_targeting_stance_mult_ordering(failures: PackedStringArray) -> void:
	var m_def: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_DEFENSIVE})
	var m_bal: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_BALANCED})
	var m_agg: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_AGGRESSIVE})
	if not (m_def < m_bal + 0.001 and m_bal < m_agg + 0.001):
		_fail(
			failures,
			"ai_targeting_stance: expected def<bal<agg got %.4f %.4f %.4f" % [m_def, m_bal, m_agg]
		)


## Tier 1.6: `hostile_pair_targeting_weight_mult` × **`AI_TARGETING_INCAP_HOSTILE_MULT`** vs incapacitated opponent (`CoreEntity` consciousness below threshold; dirty flag off so value sticks).
## Rank-0 pair must **not** be file-opposed: incap clears `is_file_opposed_rank0_pair`, which would otherwise drop the file-opposed mult and invalidate “only × incap”.
static func _run_ai_targeting_incap_hostile_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy = _new_entity("SWORD")
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var opp: Dictionary = mgr.combatants[1]
	p["file"] = 0
	opp["file"] = 1
	mgr._recompute_zoc_and_distance()
	var w_up: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
	if w_up <= 0.0:
		_fail(failures, "ai_incap: baseline hostile weight should be > 0")
		_free_manager(mgr)
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
		_fail(
			failures,
			"ai_incap: expected down=%.6f ≈ clamp(up*mult)=%.6f (up=%.6f raw=%.6f mult=%.4f)"
			% [w_down, expected_w, w_up, raw_down, CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT]
		)
	if not _EntityAccess.is_incapacitated(opp):
		_fail(failures, "ai_incap: test setup failed — opponent should read as incapacitated")
	_free_manager(mgr)


## Tier 1.6: `AvailableActionsBuilder` does not list melee / `attempt_close` / crash vs incapacitated enemies.
static func _run_no_hostile_actions_listed_vs_incap_enemy(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy = _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(e):
		_fail(failures, "incap_acts: enemy should be incapacitated for test")
		_free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	var acts: Array = mgr.get_available_actions(pid)
	for a in acts:
		if int(a.get("target_id", -9)) != eid:
			continue
		var mid: String = str(a.get("move_id", ""))
		_fail(
			failures,
			"incap_acts: unexpected action vs incap enemy move_id=%s full=%s" % [mid, str(a)]
		)
		_free_manager(mgr)
		return
	_free_manager(mgr)


## Tier 1.6 / stalemate: all rank-0 enemies incap → `any_enemy_rank0` false → rank-1 pass may list vs deeper hostiles (no soft-lock).
static func _run_stalemate_melee_rank1_when_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_e0 = _new_entity("SWORD")
	ent_e0.consciousness = 5.0
	mgr.register(ent_e0, "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
			p = c
			break
	if p.is_empty():
		_fail(failures, "stalemate_incap: no player combatant after start")
		_free_manager(mgr)
		return
	var e0: Dictionary = {}
	var e1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		var rr: int = _EntityAccess.rank_int(c)
		if rr == 0:
			e0 = c
		elif rr == 1:
			e1 = c
	if e0.is_empty() or e1.is_empty():
		_fail(failures, "stalemate_incap: missing enemy rank0 or rank1 after start")
		_free_manager(mgr)
		return
	if not _EntityAccess.is_incapacitated(e0) or _EntityAccess.is_incapacitated(e1):
		_fail(failures, "stalemate_incap: e0 should be incap, e1 upright")
		_free_manager(mgr)
		return
	var any_r0: bool = false
	for oc in mgr.combatants:
		if _EntityAccess.side_str(oc) == "player":
			continue
		if _EntityAccess.rank_int(oc) != 0:
			continue
		if _ActionsBuilder._opp_matches_melee_rank_target(mgr, p, oc, 0):
			any_r0 = true
			break
	if any_r0:
		_fail(failures, "stalemate_incap: expected no _opp_matches rank0 after incap")
		_free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var e0id: int = _EntityAccess.id_int(e0)
	var e1id: int = _EntityAccess.id_int(e1)
	var acts: Array = mgr.get_available_actions(pid)
	for a in acts:
		if int(a.get("target_id", -9)) == e0id:
			_fail(failures, "stalemate_incap: should not list actions vs incap rank0 got %s" % str(a))
			_free_manager(mgr)
			return
	var seen_e1: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) == e1id:
			seen_e1 = true
			break
	if not seen_e1:
		_fail(failures, "stalemate_incap: expected at least one action vs rank1 enemy acts=%s" % str(acts))
	_free_manager(mgr)


## Tier 3.2: weapon part mass fractions must cover the whole weapon; parry contact uses the intended part.
static func _run_weapon_part_mass_model_normalized(failures: PackedStringArray) -> void:
	for wid in WeaponConstants.get_all_weapon_ids():
		var weapon: Weapon = _Weapon.create_from_definition(wid)
		if weapon == null:
			_fail(failures, "weapon_parts: could not create %s" % wid)
			continue
		if not weapon.has_parts():
			_fail(failures, "weapon_parts: %s should define part model data" % wid)
			continue
		var total_fraction: float = 0.0
		for part in weapon.parts:
			if part is Dictionary:
				total_fraction += float((part as Dictionary).get("mass_fraction", 0.0))
		if absf(total_fraction - 1.0) > 0.001:
			_fail(failures, "weapon_parts: %s mass fractions sum %.3f, want 1.000" % [wid, total_fraction])
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if spear == null:
		_fail(failures, "weapon_parts: missing spear")
		return
	if spear.get_parry_contact_type() != "shaft":
		_fail(failures, "weapon_parts: spear should parry with shaft, got %s" % spear.get_parry_contact_type())
	var expected_spear_parry_mass: float = spear.mass * 0.85
	if absf(spear.get_parry_part_mass_kg() - expected_spear_parry_mass) > 0.001:
		_fail(
			failures,
			"weapon_parts: spear parry mass %.3f want %.3f"
			% [spear.get_parry_part_mass_kg(), expected_spear_parry_mass]
		)


## Tier 3.2: parry part id selection follows documented fallback order.
static func _run_weapon_parry_part_selection_fallbacks(failures: PackedStringArray) -> void:
	var parts: Array = [
		{"id": "head", "length_cm": 10, "mass_fraction": 0.65, "parry_eligible": false},
		{"id": "shaft", "length_cm": 60, "mass_fraction": 0.35, "parry_eligible": true}
	]
	var selector := Callable(_Weapon, "parry_part_id_from_parts")
	var preferred: String = str(selector.call(parts, " Shaft "))
	if preferred != "shaft":
		_fail(failures, "weapon_parry_part: normalized preferred id got %s want shaft" % preferred)
	var invalid_preferred: String = str(selector.call(parts, "head"))
	if invalid_preferred != "shaft":
		_fail(failures, "weapon_parry_part: non-eligible preferred should fallback to shaft got %s" % invalid_preferred)
	var missing_preferred: String = str(selector.call(parts, "blade"))
	if missing_preferred != "shaft":
		_fail(failures, "weapon_parry_part: missing preferred should fallback to shaft got %s" % missing_preferred)
	var no_eligible: Array = [
		{"id": "light", "length_cm": 10, "mass_fraction": 0.25, "parry_eligible": false},
		{"id": "heavy", "length_cm": 30, "mass_fraction": 0.75, "parry_eligible": false}
	]
	var largest: String = str(selector.call(no_eligible, ""))
	if largest != "heavy":
		_fail(failures, "weapon_parry_part: no eligible should fallback to largest mass got %s" % largest)


## Tier 3.2: attack momentum / KE helpers use the intended striking part mass.
static func _run_weapon_striking_part_mass_model(failures: PackedStringArray) -> void:
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	var axe: Weapon = _Weapon.create_from_definition("AXE")
	if spear == null or mace == null or axe == null:
		_fail(failures, "weapon_striking_parts: missing spear/mace/axe")
		return
	var spear_stab: float = spear.get_striking_part_mass_kg(" STAB ")
	var spear_blunt: float = spear.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_BLUNT)
	var mace_blunt: float = mace.get_striking_part_mass_kg("BLUNT")
	var axe_stab: float = axe.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_STAB)
	if absf(spear_stab - spear.mass * 0.15) > 0.001:
		_fail(failures, "weapon_striking_parts: spear stab mass %.3f want %.3f" % [spear_stab, spear.mass * 0.15])
	if absf(spear_blunt - spear.mass * 0.85) > 0.001:
		_fail(failures, "weapon_striking_parts: spear blunt mass %.3f want %.3f" % [spear_blunt, spear.mass * 0.85])
	if absf(mace_blunt - mace.mass * 0.7) > 0.001:
		_fail(failures, "weapon_striking_parts: mace blunt mass %.3f want %.3f" % [mace_blunt, mace.mass * 0.7])
	if absf(axe_stab - axe.mass * 0.15) > 0.001:
		_fail(failures, "weapon_striking_parts: axe stab mass %.3f want %.3f" % [axe_stab, axe.mass * 0.15])


## Tier 3.2: blade strong/weak fraction uses handle length over total blade weapon length.
static func _run_weapon_blade_strong_fraction(failures: PackedStringArray) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	var dagger: Weapon = _Weapon.create_from_definition("DAGGER")
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if sword == null or dagger == null or spear == null:
		_fail(failures, "weapon_strong_fraction: missing sword/dagger/spear")
		return
	var sword_want: float = 30.0 / 120.0
	var dagger_want: float = 12.0 / 32.0
	if absf(sword.get_parry_strong_fraction() - sword_want) > 0.001:
		_fail(
			failures,
			"weapon_strong_fraction: sword %.3f want %.3f"
			% [sword.get_parry_strong_fraction(), sword_want]
		)
	if absf(dagger.get_parry_strong_fraction() - dagger_want) > 0.001:
		_fail(
			failures,
			"weapon_strong_fraction: dagger %.3f want %.3f"
			% [dagger.get_parry_strong_fraction(), dagger_want]
		)
	if absf(spear.get_parry_strong_fraction() - 0.25) > 0.001:
		_fail(failures, "weapon_strong_fraction: non-blade spear should use neutral 0.25")


## Tier 3.2: bind-riposte contact sets are normalized, deduped, and data-driven per weapon.
static func _run_bind_riposte_contact_types_normalized(failures: PackedStringArray) -> void:
	var valid: Dictionary = {
		WeaponConstants.ATTACK_TYPE_STAB: true,
		WeaponConstants.ATTACK_TYPE_CUT: true,
		WeaponConstants.ATTACK_TYPE_BLUNT: true
	}
	var expected: Dictionary = {
		"SWORD": [WeaponConstants.ATTACK_TYPE_STAB, WeaponConstants.ATTACK_TYPE_CUT],
		"AXE": [WeaponConstants.ATTACK_TYPE_CUT, WeaponConstants.ATTACK_TYPE_STAB],
		"MACE": [WeaponConstants.ATTACK_TYPE_BLUNT],
		"DAGGER": [WeaponConstants.ATTACK_TYPE_STAB],
		"SPEAR": [WeaponConstants.ATTACK_TYPE_STAB]
	}
	for wid in expected.keys():
		var weapon: Weapon = _Weapon.create_from_definition(str(wid))
		if weapon == null:
			_fail(failures, "bind_contacts: missing weapon %s" % str(wid))
			continue
		var seen: Dictionary = {}
		for raw_ct in weapon.bind_riposte_contact_types:
			var ct: String = str(raw_ct)
			if not valid.get(ct, false):
				_fail(failures, "bind_contacts: %s invalid contact %s" % [str(wid), ct])
			if seen.get(ct, false):
				_fail(failures, "bind_contacts: %s duplicate contact %s" % [str(wid), ct])
			seen[ct] = true
		if weapon.bind_riposte_contact_types != expected[wid]:
			_fail(
				failures,
				"bind_contacts: %s got %s want %s"
				% [str(wid), str(weapon.bind_riposte_contact_types), str(expected[wid])]
			)


## Tier 3.2: bind riposte speed depends on parry contact part plus the riposte contact type.
static func _run_bind_riposte_contact_multipliers(failures: PackedStringArray) -> void:
	var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
	var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
	var spear_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["stab"])
	if spear_normal <= 0.0 or absf((spear_bind / spear_normal) - spear_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: spear stab ratio %.3f want %.3f"
			% [(spear_bind / spear_normal) if spear_normal > 0.0 else -1.0, spear_want]
		)
	var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
	var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
	var mace_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["blunt"])
	if mace_normal <= 0.0 or absf((mace_bind / mace_normal) - mace_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: mace blunt ratio %.3f want %.3f"
			% [(mace_bind / mace_normal) if mace_normal > 0.0 else -1.0, mace_want]
		)
	var axe_normal: float = _windup_duration_for_bind_test("AXE", "spike_thrust", false)
	var axe_bind: float = _windup_duration_for_bind_test("AXE", "spike_thrust", true)
	var axe_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["haft"] as Dictionary)["stab"])
	if axe_normal <= 0.0 or absf((axe_bind / axe_normal) - axe_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: axe spike ratio %.3f want %.3f"
			% [(axe_bind / axe_normal) if axe_normal > 0.0 else -1.0, axe_want]
		)
	var spear_slash_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", false)
	var spear_slash_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", true)
	if spear_slash_normal <= 0.0 or absf((spear_slash_bind / spear_slash_normal) - 1.0) > 0.001:
		_fail(
			failures,
			"bind_riposte: spear slash should not be eligible by default ratio %.3f"
			% [(spear_slash_bind / spear_slash_normal) if spear_slash_normal > 0.0 else -1.0]
		)


## Tier 3.2: opposite-line parry magnitude uses contact-type severity thresholds.
static func _run_parry_opposite_deflect_thresholds(failures: PackedStringArray) -> void:
	var align: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
	var cut_low: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.01,
		WeaponConstants.ATTACK_TYPE_CUT,
		align
	)
	if cut_low not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: weak cut should partial-deflect high to adjacent, got %s" % cut_low)
	var cut_full: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT + 0.01,
		WeaponConstants.ATTACK_TYPE_CUT,
		align
	)
	if cut_full != "low":
		_fail(failures, "parry_deflect_threshold: strong cut should deflect high to low, got %s" % cut_full)
	var stab_mid: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		0.55,
		WeaponConstants.ATTACK_TYPE_STAB,
		align
	)
	if stab_mid != "low":
		_fail(failures, "parry_deflect_threshold: thrust should reach full opposite at 0.55, got %s" % stab_mid)
	var blunt_mid: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		0.55,
		WeaponConstants.ATTACK_TYPE_BLUNT,
		align
	)
	if blunt_mid not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: blunt at 0.55 should partial-deflect to adjacent, got %s" % blunt_mid)
	seed(1205)
	var adj_align: float = CombatConstants.get_alignment_from_angles(0.0, 90.0)
	var adjacent_guard: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		90.0,
		1.0,
		WeaponConstants.ATTACK_TYPE_CUT,
		adj_align
	)
	if adjacent_guard not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: adjacent guard should stay adjacent, got %s" % adjacent_guard)


## Tier 3.2: defender weapon type × attack contact modifiers apply through Weapon object fields.
static func _run_parry_defender_vs_attack_modifiers(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("DAGGER"), "player")
	mgr.register(_new_entity("MACE"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var dagger_defender: Dictionary = mgr.combatants[0]
	var mace_defender: Dictionary = mgr.combatants[1]
	var spear_defender: Dictionary = mgr.combatants[2]
	var dagger: Weapon = _EntityAccess.get_weapon(dagger_defender)
	var mace: Weapon = _EntityAccess.get_weapon(mace_defender)
	var spear: Weapon = _EntityAccess.get_weapon(spear_defender)
	if dagger == null:
		_fail(failures, "parry_def_vs_atk: missing dagger weapon")
		_free_manager(mgr)
		return
	if mace == null:
		_fail(failures, "parry_def_vs_atk: missing mace weapon")
		_free_manager(mgr)
		return
	if spear == null:
		_fail(failures, "parry_def_vs_atk: missing spear weapon")
		_free_manager(mgr)
		return
	var dagger_stab_cd: float = _DefenseChoice._compute_parry_c_d(dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_STAB.to_upper())
	var dagger_cut_cd: float = _DefenseChoice._compute_parry_c_d(dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var dagger_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["DAGGER"] as Dictionary)["stab"])
	var dagger_ratio: float = dagger_stab_cd / dagger_cut_cd if dagger_cut_cd > 0.0 else -1.0
	if dagger_cut_cd <= 0.0 or absf(dagger_ratio - dagger_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: dagger stab/cut ratio %.3f want %.3f"
			% [dagger_ratio, dagger_expected]
		)
	var mace_blunt_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_BLUNT)
	var mace_cut_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var mace_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["MACE"] as Dictionary)["blunt"])
	var mace_ratio: float = mace_blunt_cd / mace_cut_cd if mace_cut_cd > 0.0 else -1.0
	if mace_cut_cd <= 0.0 or absf(mace_ratio - mace_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: mace blunt/cut ratio %.3f want %.3f"
			% [mace_ratio, mace_expected]
		)
	var spear_cut_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var spear_stab_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_STAB)
	var spear_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["SPEAR"] as Dictionary)["cut"])
	var spear_ratio: float = spear_cut_cd / spear_stab_cd if spear_stab_cd > 0.0 else -1.0
	if spear_stab_cd <= 0.0 or absf(spear_ratio - spear_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: spear cut/stab ratio %.3f want %.3f"
			% [spear_ratio, spear_expected]
		)
	_free_manager(mgr)


## Tier 3.2 + 3.0: parry clash context preserves bind/deflect calibration + strike kinematics; asserts geometry + move ids vs **`DefenseResolutionHandler._resolve_parry`** and **`WeaponDamageHelper`** / **`StrikeRealismProfile`**; Tier **3.1** **`strike_measure_ratio`** vs **`pa`** after **`stamp_attack_pair_geometry_on_dict`** + **`strike_measure_ratio_for_attack_pair`** (full-stop key set **`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP`**); stamped path sets **`impact_blade_station`** before **`resolve`** so post-resolve kinematics recompute matches **`velocity_intent_mult_from_pa`** (no extra **`randf()`** vs resolver); unstamped **`pa`** → clash **`strike_measure_ratio`** **-1**, then **`seed(3312)`** before stamped path for stable RNG.
static func _parry_clash_context_expected_strike_kinematics(
	pa: Dictionary,
	attacker: Dictionary,
	atk_move: String,
	intensity_val: float,
	archetype_passed: Dictionary
) -> Dictionary:
	var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
	var ai := AttackInstance.new(atk_move, intensity_val)
	ai.archetype = archetype_passed
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_sv: float = -1.0
	var want_ke: float = 0.0
	if atk_w != null:
		want_sv = WeaponDamageHelper.get_effective_velocity_m_s(atk_w, ai)
		want_sv *= StrikeRealismProfile.velocity_intent_mult_from_pa(
			pa, atk_w, atk_move, float(pa.get("intensity", intensity_val)), archetype_passed
		)
		ai.velocity_m_s = want_sv
		want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
	return {
		"kinematic_delivery": want_kdel,
		"strike_velocity_m_s": want_sv,
		"strike_kinetic_energy_j": want_ke,
	}


## Tier 3.0: partial-parry follow-through — clash **`strike_velocity_m_s`** / **`strike_kinetic_energy_j`** use **`pa["velocity_m_s"]`** after **`DefenseResolutionHandler`** reduction (not pre-parry intent speed).
static func _parry_clash_expected_partial_strike_kinematics(
	pa: Dictionary,
	attacker: Dictionary,
	atk_move: String,
	intensity_val: float,
	archetype_passed: Dictionary
) -> Dictionary:
	var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
	var ai := AttackInstance.new(atk_move, intensity_val)
	ai.archetype = archetype_passed
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_sv: float = float(pa.get("velocity_m_s", -1.0))
	ai.velocity_m_s = want_sv
	var want_ke: float = 0.0
	if atk_w != null:
		want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
	return {
		"kinematic_delivery": want_kdel,
		"strike_velocity_m_s": want_sv,
		"strike_kinetic_energy_j": want_ke,
	}


static func _run_parry_clash_context_calibration_fields(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["guard_line"] = "low"
	var pa_template: Dictionary = {
		"attack_type": "spear_thrust",
		"effective_attack_line": "high",
		"intensity": 0.5,
		"wind_up_duration": 1.0,
		"arc_start_deg": 0.0,
		"arc_end_deg": 180.0,
		"attack_angle_deg": 180.0
	}
	var parry_p_a: float = 5.0
	var parry_c_d: float = 100.0
	var m_a_parry: float = 1.25
	var m_d_parry: float = 2.5
	var m_a_velocity: float = 0.45
	var dc: Dictionary = {
		"defense": "parry",
		"can_parry_in_time": true,
		"parry_p_a": parry_p_a,
		"parry_c_d": parry_c_d,
		"parry_time_to_react": 0.1,
		"parry_readiness": 1.0,
		"is_block_parry": true,
		"m_a_parry": m_a_parry,
		"m_d_parry": m_d_parry,
		"m_a_velocity": m_a_velocity,
		"dodge_chance": 0.0,
		"dodge_eval_part": "",
		"effective_redirect": 1.0,
		"late_parry": false,
		"parry_off_balance": false
	}
	# Tier 3.1 sentinel: no **`strike_measure_ratio`** on **`pa`** → clash carries **-1** (same RNG as main branch after re-seed).
	seed(3312)
	var pa_unstamped: Dictionary = pa_template.duplicate(true)
	var res_unstamped: Variant = _DefenseResolution.resolve(
		pa_unstamped,
		attacker,
		defender,
		dc,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (res_unstamped is Dictionary) or res_unstamped.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context unstamped: expected parry_deflect result")
		_free_manager(mgr)
		return
	var clash_un: Dictionary = res_unstamped.get("parry_clash_context", {})
	if not clash_un.has("strike_measure_ratio") or absf(float(clash_un.get("strike_measure_ratio", 0.0)) - (-1.0)) > 0.001:
		_fail(
			failures,
			"parry_clash_context unstamped: strike_measure_ratio want -1 got %s"
			% str(clash_un.get("strike_measure_ratio", "missing"))
		)
		_free_manager(mgr)
		return
	for _sk_un: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash_un.has(_sk_un):
			_fail(failures, "parry_clash_context unstamped: missing key %s" % _sk_un)
			_free_manager(mgr)
			return
	seed(3312)
	var pa1: Dictionary = pa_template.duplicate(true)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa1)
	var atk_w_for_meas: RefCounted = _EntityAccess.get_weapon(attacker)
	if atk_w_for_meas != null:
		pa1["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr, attacker, defender, atk_w_for_meas, float(pa1.get("effective_pair_eff_dist", -1.0))
		)
		# Match wind-up: fixed blade station so **`velocity_intent_mult_from_pa`** does not draw a second RNG stream vs post-resolve recompute.
		pa1["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa1, atk_w_for_meas, "spear_thrust", 0.5
		)
	var result = _DefenseResolution.resolve(
		pa1,
		attacker,
		defender,
		dc,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (result is Dictionary) or result.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context: expected parry_deflect result")
		_free_manager(mgr)
		return
	var clash: Dictionary = result.get("parry_clash_context", {})
	if clash.is_empty():
		_fail(failures, "parry_clash_context: missing context")
		_free_manager(mgr)
		return
	for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash.has(_sk):
			_fail(failures, "parry_clash_context: missing key %s" % _sk)
			_free_manager(mgr)
			return
	var expected: Dictionary = {
		"parry_p_a": parry_p_a,
		"parry_c_d": parry_c_d,
		"m_a_parry": m_a_parry,
		"m_d_parry": m_d_parry,
		"m_a_velocity": m_a_velocity,
		"parry_time_to_react": float(dc.get("parry_time_to_react", -1.0)),
		"parry_readiness": float(dc.get("parry_readiness", -1.0))
	}
	for key in expected.keys():
		if absf(float(clash.get(key, -999.0)) - float(expected[key])) > 0.001:
			_fail(
				failures,
				"parry_clash_context: %s %.3f want %.3f"
				% [str(key), float(clash.get(key, -999.0)), float(expected[key])]
			)
	if bool(clash.get("late_parry", false)) != bool(dc.get("late_parry", false)):
		_fail(failures, "parry_clash_context: late_parry should match defense choice")
	if bool(clash.get("parry_off_balance", false)) != bool(dc.get("parry_off_balance", false)):
		_fail(failures, "parry_clash_context: parry_off_balance should match defense choice")
	if bool(clash.get("is_block_parry", false)) != bool(dc.get("is_block_parry", false)):
		_fail(failures, "parry_clash_context: is_block_parry should match defense choice")
	var atk_move: String = "spear_thrust"
	if str(clash.get("attack_type", "")) != atk_move:
		_fail(
			failures,
			"parry_clash_context: attack_type want %s got %s" % [atk_move, str(clash.get("attack_type", ""))]
		)
	var want_ct: String = str(WeaponConstants.contact_type_for_move_id(atk_move)).to_lower().strip_edges()
	if str(clash.get("contact_type", "")).to_lower().strip_edges() != want_ct:
		_fail(
			failures,
			"parry_clash_context: contact_type want %s got %s" % [want_ct, str(clash.get("contact_type", ""))]
		)
	var arc_s: float = float(pa_template.get("arc_start_deg", 0.0))
	var arc_e: float = float(pa_template.get("arc_end_deg", pa_template.get("attack_angle_deg", -999.0)))
	var atk_line_for_align: String = str(pa_template.get("effective_attack_line", "high"))
	var def_w0 = _EntityAccess.get_weapon(defender)
	var def_mass: float = (
		float(def_w0.mass)
		if def_w0 != null and (def_w0.get("mass") is float or def_w0.get("mass") is int)
		else WeaponConstants.BASELINE_MASS_KG
	)
	if str(clash.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
		_fail(
			failures,
			"parry_clash_context: effective_attack_line want %s got %s"
			% [str(pa_template.get("effective_attack_line", "")), str(clash.get("effective_attack_line", ""))]
		)
	if str(clash.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
		_fail(
			failures,
			"parry_clash_context: defender_guard_line want %s got %s"
			% [str(defender.get("guard_line", "")), str(clash.get("defender_guard_line", ""))]
		)
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_arch: String = (
		atk_w.get_archetype_id(atk_move) if atk_w != null and atk_w.has_method("get_archetype_id") else ""
	)
	if str(clash.get("archetype_id", "")) != want_arch:
		_fail(
			failures,
			"parry_clash_context: archetype_id want %s got %s" % [want_arch, str(clash.get("archetype_id", ""))]
		)
	var eff_wind: float = float(pa_template.get("wind_up_duration", 0.5)) * (1.0 - CombatConstants.COMMITMENT_FRACTION)
	var parry_prog: float = 1.0
	if not bool(dc.get("late_parry", false)):
		parry_prog = 1.0 - clampf(float(dc.get("parry_time_to_react", 0.0)) / maxf(0.001, eff_wind), 0.0, 1.0)
	var want_atk_deg: float = (
		CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, parry_prog)
		if arc_e >= -900.0
		else CombatConstants.line_to_angle(str(pa_template.get("effective_attack_line", "high")))
	)
	if absf(float(clash.get("attack_angle_deg", -9999.0)) - want_atk_deg) > 0.05:
		_fail(
			failures,
			"parry_clash_context: attack_angle_deg want %.4f got %.4f" % [want_atk_deg, float(clash.get("attack_angle_deg", -9999.0))]
		)
	var wobble: Dictionary = {
		"parry_readiness": float(dc.get("parry_readiness", 1.0)),
		"defender_mass_kg": def_mass,
	}
	var want_guard_deg: float = CombatConstants.get_guard_angle_deg(defender, wobble)
	if absf(float(clash.get("guard_angle_deg", -9999.0)) - want_guard_deg) > 0.25:
		_fail(
			failures,
			"parry_clash_context: guard_angle_deg want %.4f got %.4f"
			% [want_guard_deg, float(clash.get("guard_angle_deg", -9999.0))]
		)
	var align_ctx1: Dictionary = {"attack_angle_deg": want_atk_deg, "guard_angle_deg": want_guard_deg}
	var want_align: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx1)
	if absf(float(clash.get("alignment", -999.0)) - want_align) > 0.02:
		_fail(
			failures,
			"parry_clash_context: alignment want %.4f got %.4f" % [want_align, float(clash.get("alignment", -999.0))]
		)
	var c_d_final: float = float(clash.get("c_d_final", 0.0))
	if c_d_final <= 0.0:
		_fail(failures, "parry_clash_context: c_d_final should be positive")
	var expected_margin: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
	if absf(float(clash.get("margin_ratio", -1.0)) - expected_margin) > 0.001:
		_fail(failures, "parry_clash_context: margin_ratio does not match c_d_final/parry_p_a")
	var want_pc: float = CombatConstants.parry_control_for_bind_deflect(
		c_d_final,
		parry_p_a,
		float(clash.get("alignment", 0.0)),
		float(dc.get("parry_readiness", 1.0)),
		bool(dc.get("parry_off_balance", false)),
		bool(dc.get("late_parry", false)),
		str(clash.get("contact_type", ""))
	)
	if absf(float(clash.get("parry_control", -9.0)) - want_pc) > 0.001:
		_fail(
			failures,
			"parry_clash_context: parry_control %.4f vs CombatConstants.parry_control_for_bind_deflect %.4f"
			% [float(clash.get("parry_control", -9.0)), want_pc]
		)
	var want_sev: float = CombatConstants.parry_deflect_severity_from_margin_ratio(float(clash.get("margin_ratio", 0.0)))
	if absf(float(clash.get("severity", -1.0)) - want_sev) > 0.001:
		_fail(
			failures,
			"parry_clash_context: severity %.4f vs parry_deflect_severity_from_margin_ratio %.4f"
			% [float(clash.get("severity", -1.0)), want_sev]
		)
	var arch_passed: Dictionary = {}
	var exp_sk: Dictionary = _parry_clash_context_expected_strike_kinematics(
		pa1, attacker, atk_move, 0.5, arch_passed
	)
	if str(clash.get("kinematic_delivery", "")) != str(exp_sk.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_clash_context: kinematic_delivery want %s got %s"
			% [str(exp_sk.get("kinematic_delivery", "")), str(clash.get("kinematic_delivery", ""))]
		)
	if absf(float(clash.get("strike_velocity_m_s", -999.0)) - float(exp_sk.get("strike_velocity_m_s", 0.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context: strike_velocity_m_s %.6f want %.6f"
			% [float(clash.get("strike_velocity_m_s", -999.0)), float(exp_sk.get("strike_velocity_m_s", 0.0))]
		)
	if absf(float(clash.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk.get("strike_kinetic_energy_j", 0.0))) > 0.05:
		_fail(
			failures,
			"parry_clash_context: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash.get("strike_kinetic_energy_j", -999.0)), float(exp_sk.get("strike_kinetic_energy_j", 0.0))]
		)
	if absf(float(clash.get("strike_measure_ratio", -999.0)) - float(pa1.get("strike_measure_ratio", -1.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context: strike_measure_ratio %.6f want %.6f"
			% [float(clash.get("strike_measure_ratio", -999.0)), float(pa1.get("strike_measure_ratio", -1.0))]
		)
	# Late / off-balance flags propagate for calibration (same full_stop path).
	var dc_late: Dictionary = dc.duplicate(true)
	dc_late["late_parry"] = true
	dc_late["parry_off_balance"] = true
	dc_late["parry_readiness"] = 0.88
	dc_late["parry_time_to_react"] = 0.02
	seed(3313)
	var pa2: Dictionary = pa_template.duplicate(true)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa2)
	if atk_w_for_meas != null:
		pa2["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr, attacker, defender, atk_w_for_meas, float(pa2.get("effective_pair_eff_dist", -1.0))
		)
		pa2["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa2, atk_w_for_meas, "spear_thrust", 0.5
		)
	var result2 = _DefenseResolution.resolve(
		pa2,
		attacker,
		defender,
		dc_late,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (result2 is Dictionary) or result2.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context late: expected parry_deflect result")
		_free_manager(mgr)
		return
	var clash2: Dictionary = result2.get("parry_clash_context", {})
	if clash2.is_empty():
		_fail(failures, "parry_clash_context late: missing context")
		_free_manager(mgr)
		return
	for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash2.has(_sk):
			_fail(failures, "parry_clash_context late: missing key %s" % _sk)
			_free_manager(mgr)
			return
	if not bool(clash2.get("late_parry", false)) or not bool(clash2.get("parry_off_balance", false)):
		_fail(failures, "parry_clash_context: late/off_balance should be true on second fixture")
	if absf(float(clash2.get("parry_readiness", 0.0)) - 0.88) > 0.001:
		_fail(failures, "parry_clash_context: parry_readiness should echo defense choice (late branch)")
	if absf(float(clash2.get("parry_time_to_react", -1.0)) - 0.02) > 0.001:
		_fail(failures, "parry_clash_context: parry_time_to_react should echo defense choice (late branch)")
	if str(clash2.get("attack_type", "")) != atk_move:
		_fail(
			failures,
			"parry_clash_context late: attack_type want %s got %s" % [atk_move, str(clash2.get("attack_type", ""))]
		)
	if str(clash2.get("contact_type", "")).to_lower().strip_edges() != want_ct:
		_fail(
			failures,
			"parry_clash_context late: contact_type want %s got %s" % [want_ct, str(clash2.get("contact_type", ""))]
		)
	if str(clash2.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
		_fail(
			failures,
			"parry_clash_context late: effective_attack_line want %s got %s"
			% [str(pa_template.get("effective_attack_line", "")), str(clash2.get("effective_attack_line", ""))]
		)
	if str(clash2.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
		_fail(
			failures,
			"parry_clash_context late: defender_guard_line want %s got %s"
			% [str(defender.get("guard_line", "")), str(clash2.get("defender_guard_line", ""))]
		)
	if str(clash2.get("archetype_id", "")) != want_arch:
		_fail(
			failures,
			"parry_clash_context late: archetype_id want %s got %s" % [want_arch, str(clash2.get("archetype_id", ""))]
		)
	var want_atk_deg2: float = CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, 1.0) if arc_e >= -900.0 else want_atk_deg
	if absf(float(clash2.get("attack_angle_deg", -9999.0)) - want_atk_deg2) > 0.05:
		_fail(
			failures,
			"parry_clash_context late: attack_angle_deg want %.4f got %.4f"
			% [want_atk_deg2, float(clash2.get("attack_angle_deg", -9999.0))]
		)
	# Guard wobble uses **`randf_range`** when readiness < 1 — replay alignment from stored clash angles (no second draw).
	var align_ctx2: Dictionary = {
		"attack_angle_deg": float(clash2.get("attack_angle_deg", -9999.0)),
		"guard_angle_deg": float(clash2.get("guard_angle_deg", -9999.0)),
	}
	var want_align2: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx2)
	if absf(float(clash2.get("alignment", -999.0)) - want_align2) > 0.02:
		_fail(
			failures,
			"parry_clash_context late: alignment want %.4f got %.4f" % [want_align2, float(clash2.get("alignment", -999.0))]
		)
	var c_d2: float = float(clash2.get("c_d_final", 0.0))
	var want_pc2: float = CombatConstants.parry_control_for_bind_deflect(
		c_d2,
		parry_p_a,
		float(clash2.get("alignment", 0.0)),
		0.88,
		true,
		true,
		str(clash2.get("contact_type", ""))
	)
	if absf(float(clash2.get("parry_control", -9.0)) - want_pc2) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: parry_control %.4f vs formula %.4f"
			% [float(clash2.get("parry_control", -9.0)), want_pc2]
		)
	var want_sev2: float = CombatConstants.parry_deflect_severity_from_margin_ratio(float(clash2.get("margin_ratio", 0.0)))
	if absf(float(clash2.get("severity", -1.0)) - want_sev2) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: severity %.4f vs formula %.4f"
			% [float(clash2.get("severity", -1.0)), want_sev2]
		)
	var exp_sk2: Dictionary = _parry_clash_context_expected_strike_kinematics(
		pa2, attacker, atk_move, 0.5, arch_passed
	)
	if str(clash2.get("kinematic_delivery", "")) != str(exp_sk2.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_clash_context late: kinematic_delivery want %s got %s"
			% [str(exp_sk2.get("kinematic_delivery", "")), str(clash2.get("kinematic_delivery", ""))]
		)
	if absf(float(clash2.get("strike_velocity_m_s", -999.0)) - float(exp_sk2.get("strike_velocity_m_s", 0.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: strike_velocity_m_s %.6f want %.6f"
			% [float(clash2.get("strike_velocity_m_s", -999.0)), float(exp_sk2.get("strike_velocity_m_s", 0.0))]
		)
	if absf(float(clash2.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk2.get("strike_kinetic_energy_j", 0.0))) > 0.05:
		_fail(
			failures,
			"parry_clash_context late: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash2.get("strike_kinetic_energy_j", -999.0)), float(exp_sk2.get("strike_kinetic_energy_j", 0.0))]
		)
	if absf(float(clash2.get("strike_measure_ratio", -999.0)) - float(pa2.get("strike_measure_ratio", -1.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: strike_measure_ratio %.6f want %.6f"
			% [float(clash2.get("strike_measure_ratio", -999.0)), float(pa2.get("strike_measure_ratio", -1.0))]
		)
	_free_manager(mgr)


## Tier 3.2 + 3.0: **`parry_partial`** — **`parry_clash_context`** mirrors full-stop keys plus **`remaining_ratio`** / **`geometric_leak`**; Tier **3.0** KE uses reduced **`pa["velocity_m_s"]`** (not intent-speed from **`_parry_clash_context_expected_strike_kinematics`**).
static func _run_parry_partial_clash_context_calibration_fields(failures: PackedStringArray) -> void:
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender_p: Dictionary = mgr2.combatants[0]
	var attacker_p: Dictionary = mgr2.combatants[1]
	defender_p["guard_line"] = "low"
	var pa_partial: Dictionary = {
		"attack_type": "spear_thrust",
		"effective_attack_line": "high",
		"intensity": 0.5,
		"wind_up_duration": 1.0,
		"arc_start_deg": 0.0,
		"arc_end_deg": 180.0,
		"attack_angle_deg": 180.0,
	}
	var parry_p_a_p: float = 5.0
	var parry_c_d_p: float = 100.0
	var dc_partial: Dictionary = {
		"defense": "parry",
		"can_parry_in_time": true,
		"parry_p_a": parry_p_a_p,
		"parry_c_d": parry_c_d_p,
		"parry_time_to_react": 0.1,
		"parry_readiness": 1.0,
		"is_block_parry": false,
		"m_a_parry": 1.25,
		"m_d_parry": 2.5,
		"m_a_velocity": 0.45,
		"dodge_chance": 0.0,
		"dodge_eval_part": "",
		"effective_redirect": 1.0,
		"late_parry": false,
		"parry_off_balance": false,
	}
	seed(3312)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr2, attacker_p, defender_p, pa_partial)
	var atk_w_part: RefCounted = _EntityAccess.get_weapon(attacker_p)
	if atk_w_part != null:
		pa_partial["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr2, attacker_p, defender_p, atk_w_part, float(pa_partial.get("effective_pair_eff_dist", -1.0))
		)
		pa_partial["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa_partial, atk_w_part, "spear_thrust", 0.5
		)
	var res_partial: Variant = _DefenseResolution.resolve(
		pa_partial,
		attacker_p,
		defender_p,
		dc_partial,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender_p),
		_EntityAccess.get_display_name(attacker_p),
		_EntityAccess.get_display_name(defender_p)
	)
	if not (res_partial is Dictionary) or str((res_partial as Dictionary).get("action", "")) != "parry_partial":
		_fail(failures, "parry_partial_clash: expected parry_partial result")
		_free_manager(mgr2)
		return
	var clash_partial: Dictionary = (res_partial as Dictionary).get("parry_clash_context", {}) as Dictionary
	if clash_partial.is_empty():
		_fail(failures, "parry_partial_clash: missing parry_clash_context")
		_free_manager(mgr2)
		return
	for _sk_part: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash_partial.has(_sk_part):
			_fail(failures, "parry_partial_clash: missing key %s" % _sk_part)
			_free_manager(mgr2)
			return
	if not clash_partial.has("remaining_ratio") or not clash_partial.has("geometric_leak"):
		_fail(failures, "parry_partial_clash: missing remaining_ratio or geometric_leak")
		_free_manager(mgr2)
		return
	if absf(float(clash_partial.get("remaining_ratio", -1.0)) - float(pa_partial.get("parry_remaining_ratio", -2.0))) > 1e-5:
		_fail(
			failures,
			"parry_partial_clash: remaining_ratio vs pa parry_remaining_ratio mismatch %s vs %s"
			% [str(clash_partial.get("remaining_ratio")), str(pa_partial.get("parry_remaining_ratio"))]
		)
	var mr_part: float = float(clash_partial.get("margin_ratio", 0.0))
	var want_mr_part: float = CombatConstants.parry_deflect_margin_ratio(
		float(clash_partial["c_d_final"]), parry_p_a_p
	)
	if absf(mr_part - want_mr_part) > 1e-4:
		_fail(failures, "parry_partial_clash: margin_ratio mismatch")
	var pc_part: float = float(clash_partial.get("parry_control", 0.0))
	var want_pc_part: float = CombatConstants.parry_control_for_bind_deflect(
		float(clash_partial["c_d_final"]),
		parry_p_a_p,
		float(clash_partial["alignment"]),
		float(clash_partial.get("parry_readiness", 0.0)),
		bool(clash_partial.get("parry_off_balance", false)),
		bool(clash_partial.get("late_parry", false)),
		str(clash_partial.get("contact_type", ""))
	)
	if absf(pc_part - want_pc_part) > 0.002:
		_fail(failures, "parry_partial_clash: parry_control vs formula mismatch")
	var sev_part: float = float(clash_partial.get("severity", -1.0))
	var want_sev_part: float = CombatConstants.parry_deflect_severity_from_margin_ratio(mr_part)
	if absf(sev_part - want_sev_part) > 0.002:
		_fail(failures, "parry_partial_clash: severity vs formula mismatch")
	var exp_part_k: Dictionary = _parry_clash_expected_partial_strike_kinematics(
		pa_partial, attacker_p, "spear_thrust", 0.5, {}
	)
	if str(clash_partial.get("kinematic_delivery", "")) != str(exp_part_k.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_partial_clash: kinematic_delivery want %s got %s"
			% [str(exp_part_k.get("kinematic_delivery", "")), str(clash_partial.get("kinematic_delivery", ""))]
		)
	if absf(float(clash_partial["strike_velocity_m_s"]) - float(exp_part_k["strike_velocity_m_s"])) > 1e-4:
		_fail(
			failures,
			"parry_partial_clash: strike_velocity_m_s %.6f want %.6f"
			% [float(clash_partial["strike_velocity_m_s"]), float(exp_part_k["strike_velocity_m_s"])]
		)
	if absf(float(clash_partial["strike_kinetic_energy_j"]) - float(exp_part_k["strike_kinetic_energy_j"])) > 1e-3:
		_fail(
			failures,
			"parry_partial_clash: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash_partial["strike_kinetic_energy_j"]), float(exp_part_k["strike_kinetic_energy_j"])]
		)
	if absf(float(clash_partial["strike_measure_ratio"]) - float(pa_partial.get("strike_measure_ratio", -99.0))) > 0.001:
		_fail(
			failures,
			"parry_partial_clash: strike_measure_ratio %.6f want %.6f"
			% [float(clash_partial["strike_measure_ratio"]), float(pa_partial.get("strike_measure_ratio", -1.0))]
		)
	_free_manager(mgr2)


## Tier 3.2: **`CombatConstants.parry_control_for_bind_deflect`** pure formula corner cases.
static func _run_parry_control_bind_deflect_formula(failures: PackedStringArray) -> void:
	var hi_cd: float = 100.0
	var pa_m: float = 5.0
	var al: float = 0.9
	var cut_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut")
	if not is_equal_approx(cut_hi, 1.0):
		_fail(failures, "parry_ctrl_formula: high-margin cut want 1.0 got %.4f" % cut_hi)
	var stab_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "stab")
	if not is_equal_approx(stab_hi, 0.85):
		_fail(failures, "parry_ctrl_formula: high-margin stab want 0.85 got %.4f" % stab_hi)
	var blunt_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "BLUNT")
	if not is_equal_approx(blunt_hi, cut_hi):
		_fail(failures, "parry_ctrl_formula: blunt should match cut for thrust mult got %.4f" % blunt_hi)
	var low_cd: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 0.25
	var cut_low: float = CombatConstants.parry_control_for_bind_deflect(low_cd, pa_m, 1.0, 1.0, false, false, "cut")
	if not is_equal_approx(cut_low, 0.5):
		_fail(failures, "parry_ctrl_formula: low-margin cut want 0.5 got %.4f" % cut_low)
	var late_mid: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, 0.65, 1.0, false, true, "cut")
	if not is_equal_approx(late_mid, 0.78):
		_fail(failures, "parry_ctrl_formula: late+align 0.65 cut want 0.78 got %.4f" % late_mid)
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(2.0), 1.0):
		_fail(failures, "parry_severity: margin 2.0 want 1.0")
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(0.5), 0.0):
		_fail(failures, "parry_severity: margin 0.5 want 0.0")
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(1.25), 0.25):
		_fail(failures, "parry_severity: margin 1.25 want 0.25")
	if not is_equal_approx(
		CombatConstants.parry_deflect_margin_ratio(hi_cd, pa_m),
		hi_cd / maxf(pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD, 0.01)
	):
		_fail(failures, "parry_margin_ratio: helper should match explicit formula")


## Tier 3.2: **`GuardLineUpdater.set_guard_deflected`** — when **`severity`** is absent, **`guard_deflect_blend`** matches **`parry_deflect_severity_from_margin_ratio(margin_ratio)`**; explicit **`severity`** wins if both are set.
static func _run_guard_line_deflected_severity_from_margin_ratio(failures: PackedStringArray) -> void:
	var c1: Dictionary = {"guard_line": "high", "combatant_id": 1, "alive": true}
	var clash_margin: Dictionary = {
		"parry_control": 0.3,
		"margin_ratio": 1.5,
		"defender_guard_line": "low",
		"contact_type": "stab",
		"alignment": 0.9,
	}
	_GuardLineUpdater.set_guard_deflected(c1, "spear_thrust", "", "low", clash_margin)
	var want_from_margin: float = CombatConstants.parry_deflect_severity_from_margin_ratio(1.5)
	if not is_equal_approx(float(c1.get("guard_deflect_blend", -1.0)), want_from_margin):
		_fail(
			failures,
			"guard_deflect_blend: margin-only clash want %.4f got %.4f" % [want_from_margin, float(c1.get("guard_deflect_blend", -1.0))]
		)
	var clash_both: Dictionary = clash_margin.duplicate(true)
	clash_both["severity"] = 0.11
	clash_both["margin_ratio"] = 2.0
	var c2: Dictionary = {"guard_line": "high", "combatant_id": 2, "alive": true}
	_GuardLineUpdater.set_guard_deflected(c2, "spear_thrust", "", "low", clash_both)
	if not is_equal_approx(float(c2.get("guard_deflect_blend", -1.0)), 0.11):
		_fail(
			failures,
			"guard_deflect_blend: explicit severity should win when both keys set (want 0.11 got %.4f)" % float(c2.get("guard_deflect_blend", -1.0))
		)


static func _run_parry_pack_flank_effective_spacing(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE] = true
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[0]["file"] = 0
	mgr.combatants[1]["file"] = 1
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var e_adj: Dictionary = mgr.combatants[1]
	var eff_adj: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e_adj)
	if eff_adj + 1e-4 >= float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		_fail(
			failures,
			"parry_pack_flank: adjacent files expected eff spacing < PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_adj
		)
	var m_adj: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if is_equal_approx(m_adj, CombatConstants.FLANK_PARRY_MOD):
		_fail(failures, "parry_pack_flank: adjacent files should not apply flank mod (got %.4f)" % m_adj)
	mgr.combatants[1]["file"] = 2
	mgr._recompute_zoc_and_distance()
	var e_far: Dictionary = mgr.combatants[1]
	var eff_far: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e_far)
	if eff_far + 1e-4 < float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		_fail(
			failures,
			"parry_pack_flank: |Δfile|==2 expected eff spacing >= PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_far
		)
	var m_far: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if not is_equal_approx(m_far, CombatConstants.FLANK_PARRY_MOD):
		_fail(
			failures,
			"parry_pack_flank: |Δfile|==2 with protection circle should apply flank mod (got %.4f want %.4f)"
			% [m_far, CombatConstants.FLANK_PARRY_MOD]
		)
	_free_manager(mgr)


## Tier 1.8 telemetry: illegal crash resolve increments counter (intrusion disabled or wrong mode).
static func _run_combat_telemetry_crash_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_EngagementResolver.resolve_crash_attempt(mgr, p_id, e_id)
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_crash: missing telemetry meta after blocked crash")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_crash_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_crash: expected invalid_crash_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Tier 1.8: weapon wind-up that resolves when `can_melee_threaten` is false (e.g. band drift) aborts + telemetry.
static func _run_telemetry_invalid_melee_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(failures, "telemetry_melee_geom: expected skip when LONG+threaten false got %s" % str(res))
	if float(res.get("recovery_duration", 0.0)) <= 0.0:
		_fail(failures, "telemetry_melee_geom: expected positive recovery on abort")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_melee_geom: missing telemetry meta")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_melee_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_melee_geom: expected invalid_melee_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Tier 1.8: `resolve_close_attempt` when pair band is not LONG (stale vs `attempt_close` listing) increments telemetry.
static func _run_telemetry_invalid_close_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(failures, "telemetry_close: missing telemetry meta after blocked close")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_close_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_close: expected invalid_close_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Failed pressure-vs-evasion close emits `reason: contest_failed` for UI / tooling (not only generic `close_failed`).
static func _run_close_contest_failed_emits_reason(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
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
		_fail(failures, "close_contest: expected action_resolved payload")
		_free_manager(mgr)
		return
	var r: Dictionary = cap[0] as Dictionary
	if str(r.get("outcome", "")) != "close_failed":
		_fail(failures, "close_contest: expected close_failed got %s" % str(r))
	elif str(r.get("reason", "")) != "contest_failed":
		_fail(failures, "close_contest: expected reason contest_failed got %s" % str(r.get("reason", "")))
	var line: String = _CombatLogFormatter.format_action_line(
		"P", "player", "E", "enemy", r
	)
	if not line.contains("measure"):
		_fail(failures, "close_contest: formatter should mention defender measure got %s" % line)
	_free_manager(mgr)


## `resolve_close_attempt` must not run the contest vs an incapacitated defender (stale UI / AI only).
static func _run_resolve_close_no_emit_when_target_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy := _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(en):
		_fail(failures, "close_skip_incap: enemy should be incap for test")
		_free_manager(mgr)
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
		_fail(failures, "close_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0]))
	_free_manager(mgr)


## `resolve_crash_attempt` must not run breach logic vs an incapacitated defender (even if intrusion flag toggles later).
static func _run_resolve_crash_no_emit_when_target_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy := _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(en):
		_fail(failures, "crash_skip_incap: enemy should be incap for test")
		_free_manager(mgr)
		return
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	_EngagementResolver.resolve_crash_attempt(mgr, p_id, e_id)
	if int(fired_box[0]) != 0:
		_fail(failures, "crash_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0]))
	_free_manager(mgr)


## `CombatLogFormatter` — **`parry_deflect`**: non-empty **`parry_clash_context`** does not change the line unless **`COMBAT_DEBUG_CALIBRATION`** (default **false**).
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
		_fail(failures, "parry_fmt: baseline should not include clash suffix got %s" % line0)
	var with_ctx: Dictionary = base_r.duplicate(true)
	with_ctx["parry_clash_context"] = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.2,
		"parry_control": 0.75
	}
	var line_ctx: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_ctx)
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		if not line_ctx.contains("thrust") or not line_ctx.contains("meas=") or not line_ctx.contains("bind="):
			_fail(
				failures,
				"parry_fmt: calibration on expected thrust/meas/bind in %s" % line_ctx
			)
	else:
		if line_ctx != line0:
			_fail(
				failures,
				"parry_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_ctx, line0]
			)
	var empty_ctx: Dictionary = base_r.duplicate(true)
	empty_ctx["parry_clash_context"] = {}
	var line_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_ctx)
	if line_empty != line0:
		_fail(
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
		_fail(failures, "parry_partial_fmt: baseline should not include clash suffix got %s" % line_pp0)
	if not line_pp0.contains("partially parried"):
		_fail(failures, "parry_partial_fmt: baseline should say partially parried got %s" % line_pp0)
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
			_fail(
				failures,
				"parry_partial_fmt: calibration on expected thrust/meas/bind/rem in %s" % line_pp_ctx
			)
	else:
		if line_pp_ctx != line_pp0:
			_fail(
				failures,
				"parry_partial_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_pp_ctx, line_pp0]
			)
	var empty_pp: Dictionary = base_pp.duplicate(true)
	empty_pp["parry_clash_context"] = {}
	var line_pp_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_pp)
	if line_pp_empty != line_pp0:
		_fail(
			failures,
			"parry_partial_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_pp_empty, line_pp0]
		)


## Log contract for `crash_failed` + `reason` (contest `repelled`, intrusion pre-checks, engagement mode) — no live breach harness required.
static func _run_crash_failed_formatter_reason_branches(failures: PackedStringArray) -> void:
	var base: Dictionary = {"outcome": "crash_failed", "dmg": 0, "died": false}
	var cases: Array = [
		["repelled", "line held"],
		["engagement_mode_skirmish", "cannot breach"],
		["light_armor", "not heavy enough"],
		["low_breach_power", "not ready to drive"],
		["intruder_cap", "too many fighters"],
	]
	for row in cases:
		var reason: String = str(row[0])
		var needle: String = str(row[1])
		var r: Dictionary = base.duplicate()
		r["reason"] = reason
		var line: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", r)
		if not line.contains(needle):
			_fail(
				failures,
				"crash_fmt: reason=%s expected substring %s in %s" % [reason, needle, line]
			)


## Tier 1.8: automatic doctrine pinch increments telemetry (Option 4 pilot).
static func _run_telemetry_automatic_doctrine_pinch_record(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	_TacticalCombat.record_automatic_doctrine_pinch(mgr, "enemy")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_auto_doc: missing meta after record")
		_free_manager(mgr)
		return
	var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
	if int(tel.get("automatic_doctrine_pinch_count", 0)) != 1:
		_fail(
			failures,
			"telemetry_auto_doc: expected automatic_doctrine_pinch_count 1 got %s" % str(tel.get("automatic_doctrine_pinch_count", -1))
		)
		_free_manager(mgr)
		return
	var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
	if typeof(lap) != TYPE_DICTIONARY:
		_fail(failures, "telemetry_auto_doc: last_automatic_doctrine_pinch should be a dict")
		_free_manager(mgr)
		return
	if str((lap as Dictionary).get("formation_id", "")) != "enemy":
		_fail(failures, "telemetry_auto_doc: last pinch formation_id mismatch")
	_free_manager(mgr)


## Snapshot rows carry `formation_doctrine` aligned with `CombatManager.get_formation_doctrine`.
static func _run_combatants_snapshot_formation_doctrine_field(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
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
				failures,
				"snapshot_doctrine: player row got %s want hold_lane" % str(rd.get("formation_doctrine", ""))
			)
		break
	if not ok_player:
		_fail(failures, "snapshot_doctrine: no player row in get_combatants")
	_free_manager(mgr)
