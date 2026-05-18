class_name CombatDebug
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _CrashActions := preload("res://combat/CombatCrashActions.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")

## Log tiers: `COMBAT_EVENT_DEBUG` alone → `flow_log_turn` lists actions + pick. With `COMBAT_EVENT_DEBUG_VERBOSE`,
## `get_available_actions` logs the action list once; `flow_log_turn` logs pick + count only (no duplicate list).
## `flow_log`: skip_turn, afterblow, close/crash contest, incursion, formation rejects, resolve edge cases.
## `COMBAT_DEBUG` → per-hit / armor / wind-up (`CombatDebug.log`, EntityDamage traces).
## Unconditional `[Combat]` lines stay for phase boundaries, deaths, and UI-adjacent events (see grep print("[Combat")).
## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).
## flow_log: verbose pipeline; use `dedupe_key` on poll-heavy paths (see `COMBAT_FLOW_LOG_SUPPRESS_REPEATED`). `clear_flow_log_dedup` on combat start/stop.
## flow_log_turn: logs turn pick line when COMBAT_EVENT_DEBUG alone is true.

static func log(msg: String) -> void:
	if CombatConstants.combat_debug_active():
		print("[Combat.Debug] ", msg)

## Calibration logs: alignment, parry_c_d, variance, remaining_ratio. Only when COMBAT_DEBUG_CALIBRATION.
static func calibration_log(msg: String) -> void:
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		print("[Combat.Cal] ", msg)

## True when `flow_log` prints (both event-debug toggles on). Use to skip expensive log prep work.
static func flow_verbose_enabled() -> bool:
	return CombatConstants.combat_event_debug_verbose_active()


## Last message per dedupe key for `COMBAT_FLOW_LOG_SUPPRESS_REPEATED` (cleared on combat start/stop).
static var _flow_log_last_by_key: Dictionary = {}


static func clear_flow_log_dedup() -> void:
	_flow_log_last_by_key.clear()


## Verbose flow. Pass `dedupe_key` for lines that may repeat unchanged every frame (e.g. `get_available_actions`, incursion snapshot); identical consecutive lines for that key are dropped when `COMBAT_FLOW_LOG_SUPPRESS_REPEATED` is on.
static func flow_log(msg: String, dedupe_key: String = "") -> void:
	if not flow_verbose_enabled():
		return
	if CombatConstants.COMBAT_FLOW_LOG_SUPPRESS_REPEATED and not dedupe_key.is_empty():
		var prev: Variant = _flow_log_last_by_key.get(dedupe_key, null)
		if prev != null and str(prev) == msg:
			return
		_flow_log_last_by_key[dedupe_key] = msg
	print("[Combat.Flow] ", msg)


## Vacancy plug / rank-0 reconcile. Toggle `CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG`.
static func formation_vacancy_log(msg: String) -> void:
	if CombatConstants.COMBAT_FORMATION_VACANCY_DEBUG:
		print("[Combat.Formation] ", msg)

## One-line summary of build() output for logs (move_id@target_id[:part]).
static func format_actions_compact(actions: Array) -> String:
	var parts: PackedStringArray = []
	for a in actions:
		var mid: String = str(a.get("move_id", ""))
		var tid: int = a.get("target_id", -1)
		var part: String = str(a.get("target_part", ""))
		var dur_s: String = ""
		var dur_hint: String = str(a.get("formation_move_duration_hint", "")).strip_edges()
		if not dur_hint.is_empty():
			dur_s = " {%s}" % dur_hint.replace("Formation move: ", "")
		if part.is_empty():
			parts.append("%s@%d%s" % [mid, tid, dur_s])
		else:
			parts.append("%s@%d:%s%s" % [mid, tid, part, dur_s])
	return ", ".join(parts)

static func flow_log_turn(side: String, combatant_id: int, actions: Array, choice: Dictionary) -> void:
	if not CombatConstants.combat_event_debug_active():
		return
	var mid: String = str(choice.get("move_id", ""))
	var tid: int = choice.get("target_id", -1)
	var part: String = str(choice.get("target_part", ""))
	var feint: String = str(choice.get("feint_part", ""))
	var part_s: String = (" part=%s" % part) if not part.is_empty() else ""
	var feint_s: String = (" feint=%s" % feint) if not feint.is_empty() else ""
	if flow_verbose_enabled():
		# Full action list is logged once in `get_available_actions`; avoid repeating it here.
		print(
			"[Combat.Flow] turn side=%s id=%d pick move_id=%s target_id=%d%s%s (actions=%d)"
			% [side, combatant_id, mid, tid, part_s, feint_s, actions.size()]
		)
	else:
		var act_str: String = format_actions_compact(actions)
		print(
			"[Combat.Flow] turn side=%s id=%d actions=[%s] => pick move_id=%s target_id=%d%s%s"
			% [side, combatant_id, act_str, mid, tid, part_s, feint_s]
		)


## breached_files keys may be int or String from serialization paths; values 0..1
static func format_breached_files(bf: Dictionary) -> String:
	if bf.is_empty():
		return ""
	var parts: PackedStringArray = []
	for k in bf.keys():
		parts.append("%s:%.2f" % [str(k), float(bf[k])])
	return "; ".join(parts)


## lane_stress_by_file or similar: file index -> float
static func format_lane_stress(by_file: Dictionary) -> String:
	if by_file.is_empty():
		return ""
	var parts: PackedStringArray = []
	for k in by_file.keys():
		parts.append("f%s=%.2f" % [str(k), float(by_file[k])])
	return ", ".join(parts)


## Verbose `get_available_actions` summary + optional crash-not-listed diagnostic (`COMBAT_EVENT_DEBUG_VERBOSE`).
static func log_available_actions_build(
	manager: Node,
	combatant_id: int,
	c: Dictionary,
	result_actions: Array,
	actions_before_counter_filter: Array,
	counter_tempo: bool,
	medical_phase: bool,
	log_fid: String,
	log_breach_blocks_moves: bool,
	combatants: Array
) -> void:
	if not flow_verbose_enabled() or c.is_empty():
		return
	var crash_count: int = 0
	var medical_count: int = 0
	for a in result_actions:
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_CRASH:
			crash_count += 1
		if mid in CombatConstants.MEDICAL_MOVE_IDS:
			medical_count += 1
	var polearm_extra: String = ""
	if not medical_phase:
		var rpv: int = _EntityAccess.rank_int(c)
		var intrv: bool = _ZoneOfControl.is_intruded(c)
		if rpv > 0 and not intrv and not _EntityAccess.get_attacking_arm(c).is_empty():
			var w_pv: Variant = _EntityAccess.get_weapon(c)
			if w_pv is Weapon and (w_pv as Weapon).depth_melee_eligible:
				polearm_extra = _format_depth_polearm_melee_context_debug(
					manager, c, w_pv as Weapon, combatants
				)
	var counter_filter_note: String = ""
	if counter_tempo and result_actions.size() != actions_before_counter_filter.size():
		counter_filter_note = " counter_tempo=%d->%d" % [
			actions_before_counter_filter.size(), result_actions.size()
		]
	flow_log(
		(
			"get_available_actions id=%d side=%s state=%s rank=%d file=%d fid=%s breach_blocks_moves=%s med_phase=%s "
			+ "crash_viab=%.3f => %d actions (medical=%d crash=%d) [%s]%s%s"
		)
		% [
			combatant_id,
			_EntityAccess.side_str(c),
			_EntityAccess.state_str(c),
			_EntityAccess.rank_int(c),
			_EntityAccess.file_int(c),
			log_fid,
			log_breach_blocks_moves,
			medical_phase,
			CombatConstants.crash_breach_viability(c),
			result_actions.size(),
			medical_count,
			crash_count,
			format_actions_compact(result_actions),
			polearm_extra,
			counter_filter_note
		],
		"get_available_actions:%d" % combatant_id
	)
	var dbg_intruded: bool = _ZoneOfControl.is_intruded(c)
	if (
		not medical_phase
		and (_EntityAccess.rank_int(c) == 0 or dbg_intruded)
		and not _EntityAccess.get_attacking_arm(c).is_empty()
		and crash_count == 0
		and CombatConstants.crash_breach_viability(c) >= CombatConstants.CRASH_BREACH_VIABILITY_MIN
	):
		var crash_cd_left: float = _EntityAccess.cooldown_remaining_s(
			manager, float(c.get("crash_cooldown_until", 0.0)), 0.0
		)
		flow_log(
			(
				"crash_not_in_action_list id=%d reason=%s viability=%.3f depth=%d max_depth=%d stamina=%.1f cost=%.1f "
				+ "crash_cd_left=%.2f breach_blocks_moves=%s skirmish=%s"
			)
			% [
				combatant_id,
				_CrashActions.crash_absent_primary_reason(manager, c),
				CombatConstants.crash_breach_viability(c),
				_EntityAccess.tactical_penetration_depth_int(c),
				CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX,
				_EntityAccess.stamina_float(c, 0.0),
				CombatConstants.CRASH_STAMINA_COST,
				crash_cd_left,
				log_breach_blocks_moves,
				_FormationBreachRules.is_skirmish_line_engagement(manager)
			],
			"crash_not_in_list:%d" % combatant_id
		)


static func _depth_polearm_opp_debug_line(
	manager: Node,
	c: Dictionary,
	opp: Dictionary,
	melee_range: float,
	fid_ctx: String,
	lane_open: bool,
	formation_attacker_cache: Dictionary,
	formation_opponent_cache: Dictionary,
	include_threaten: bool
) -> String:
	var oid: int = _EntityAccess.id_int(opp)
	var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(
		manager, c, opp, formation_attacker_cache, formation_opponent_cache
	)
	var eff: float = _PairGeometry.cached_eff_dist(pair_geom)
	var dist: String = _EntityAccess.distance_to_opponent_band(c, oid)
	var reach_ok: bool = _PairGeometry.melee_reach_covers_eff_dist(melee_range, eff)
	if include_threaten:
		var line_ok: bool = _DepthPolearm.depth_polearm_valid_line_threat(manager, c, opp, fid_ctx, lane_open)
		var threaten: bool = (
			reach_ok
			and line_ok
			and _MeleeListing.can_melee_threaten(manager, c, opp, pair_geom)
		)
		return "opp%d eff=%.2f dist=%s reach_ok=%s line_ok=%s threaten=%s" % [
			oid, eff, dist, reach_ok, line_ok, threaten
		]
	return "opp%d eff=%.2f dist=%s reach_ok=%s (no spear lane — geometry only)" % [oid, eff, dist, reach_ok]


static func _format_depth_polearm_melee_context_debug(
	manager: Node, c: Dictionary, wpn: Weapon, combatants: Array
) -> String:
	var ctx_actor: Dictionary = _ZoneOfControl.zone_geometry_line_context(manager, c)
	var fid_ctx: String = _ZoneOfControl.zone_geometry_fid_from_pack(ctx_actor)
	var lane_open: bool = _DepthPolearm.depth_polearm_lane_open(manager, c, fid_ctx)
	var front: Dictionary = _DepthPolearm.same_file_living_rank0_ally(manager, c, fid_ctx)
	var front_id: int = _EntityAccess.id_int(front) if not front.is_empty() else -1
	var fd_ctx: Dictionary = _ZoneOfControl.zone_geometry_formation_from_pack(ctx_actor)
	var dens: String = str(fd_ctx.get("density", "normal")) if not fd_ctx.is_empty() else "normal"
	var melee_range: float = float(wpn.melee_range)
	var opp_zone: Dictionary = _ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
	var bits: PackedStringArray = []
	for opp in _TargetScoring.ordered_melee_opponents(manager, c, combatants, 0, ctx_actor):
		var oid: int = _EntityAccess.id_int(opp)
		var opp_pack: Variant = opp_zone.get(oid, null)
		var fo: Dictionary = (
			_ZoneOfControl.zone_geometry_formation_from_pack(opp_pack)
			if opp_pack is Dictionary
			else {}
		)
		if fo.is_empty():
			var pair_zg: Dictionary = _ZoneOfControl.zone_geometry_for_pair(manager, c, opp)
			fo = _ZoneOfControl.zone_geometry_formation_b_from_pair_pack(pair_zg)
		bits.append(
			_depth_polearm_opp_debug_line(
				manager, c, opp, melee_range, fid_ctx, lane_open, fd_ctx, fo, true
			)
		)
	if bits.is_empty():
		for opp in combatants:
			if not _EntityAccess.is_living_hostile_to(c, opp):
				continue
			if _EntityAccess.rank_int(opp) != 0:
				continue
			var oid0: int = _EntityAccess.id_int(opp)
			var opp_pack0: Variant = opp_zone.get(oid0, null)
			var fo: Dictionary = (
				_ZoneOfControl.zone_geometry_formation_from_pack(opp_pack0)
				if opp_pack0 is Dictionary
				else {}
			)
			if fo.is_empty():
				var pair_zg0: Dictionary = _ZoneOfControl.zone_geometry_for_pair(manager, c, opp)
				fo = _ZoneOfControl.zone_geometry_formation_b_from_pair_pack(pair_zg0)
			bits.append(
				_depth_polearm_opp_debug_line(
					manager, c, opp, melee_range, fid_ctx, lane_open, fd_ctx, fo, false
				)
			)
		if bits.is_empty():
			bits.append("(no enemy rank-0)")
	return (
		" | polearm id=%d %s rank=%d file=%d reach_m=%.2f lane_open=%s front_ally=%d dens=%s || %s"
		% [
			_EntityAccess.id_int(c),
			wpn.display_name,
			_EntityAccess.rank_int(c),
			_EntityAccess.file_int(c),
			melee_range,
			lane_open,
			front_id,
			dens,
			" ; ".join(bits)
		]
	)
