class_name CombatDebug
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")

## Log tiers: `COMBAT_EVENT_DEBUG` alone --'' ' `flow_log_turn` lists actions + pick. With `COMBAT_EVENT_DEBUG_VERBOSE`,
## `get_available_actions` logs the action list once; `flow_log_turn` logs pick + count only (no duplicate list).
## `flow_log`: skip_turn, afterblow, close contest, incursion, formation rejects, resolve edge cases.
## `COMBAT_DEBUG` --'' ' per-hit / armor / wind-up (`CombatDebug.log`, EntityDamage traces).
## Unconditional `[Combat]` lines stay for phase boundaries, deaths, and UI-adjacent events (see grep print("[Combat")).
## Play session (editor F5): **`combat_session`** / **`world_session`** --'' ' `FP_COMBAT` / `FP_WORLD` on stdout (copy Godot Output).
## Invariant / logic faults: **`operational_error`** / **`operational_warn`** (`FP_ERROR` / `FP_WARN`; always on).
## Conditional combat logging. Only logs when CombatConstants.COMBAT_DEBUG is true.
## calibration_log: logs when COMBAT_DEBUG_CALIBRATION is true (alignment, parry_c_d, variance, etc.).
## flow_log: verbose pipeline; use `dedupe_key` on poll-heavy paths (see `COMBAT_FLOW_LOG_SUPPRESS_REPEATED`). `clear_flow_log_dedup` on combat start/stop.
## flow_log_turn: logs turn pick line when COMBAT_EVENT_DEBUG alone is true.

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")


## Always emitted (grep `FP_ERROR`). Use for should-never-happen combat invariants.
static func operational_error(msg: String) -> void:
    _OperationalLog.error(msg)


## Always emitted (grep `FP_WARN`). Use for suspicious but non-fatal state.
static func operational_warn(msg: String) -> void:
    _OperationalLog.warn(msg)


## `[Combat.Flow]` when `COMBAT_EVENT_DEBUG` is on (turn picks use the same tier).
static func flow_log_event(msg: String, dedupe_key: String = "") -> void:
    if not CombatConstants.combat_event_debug_active():
        return
    if CombatConstants.COMBAT_FLOW_LOG_SUPPRESS_REPEATED and not dedupe_key.is_empty():
        var prev: Variant = _flow_log_event_last_by_key.get(dedupe_key, null)
        if prev != null and str(prev) == msg:
            return
        _flow_log_event_last_by_key[dedupe_key] = msg
    print("[Combat.Flow] ", msg)


## Stale/blocked picks: flow log + **`skip_turn`**. Pass **`operational=true`** for invariant faults (grep **`FP_WARN`**).
static func resolve_action_rejected(
    manager: Node, attacker_id: int, move_id: String, reason: String, operational: bool = false
) -> void:
    var mid: String = move_id if not move_id.is_empty() else "?"
    flow_log_event(
        "resolve_rejected id=%d move=%s -- %s" % [attacker_id, mid, reason],
        "resolve_reject:%d:%s" % [attacker_id, reason]
    )
    if operational:
        operational_warn("resolve_rejected id=%d move=%s -- %s" % [attacker_id, mid, reason])
    if manager != null and manager.has_method("skip_turn"):
        manager.skip_turn(attacker_id, CombatConstants.SKIP_TURN_LOG_REJECT, reason)


## After instant actions (focus line): clear gauge and schedule the next **`EVENT_ACTION_READY`**.
static func finish_instant_turn_and_schedule_ready(manager: Node, combatant: Dictionary) -> void:
    if manager == null or combatant.is_empty():
        return
    combatant.gauge = 0.0
    _EventScheduler.schedule_action_ready_for_combatant(manager, combatant)


## Milestone combat lines during editor play (`FP_COMBAT`); falls back to `[Combat]` elsewhere.
static func combat_session(msg: String) -> void:
    if msg == _last_combat_session_line:
        return
    _last_combat_session_line = msg
    if _OperationalLog.is_play_session_active():
        _OperationalLog.play_combat(msg)
    else:
        print("[Combat] ", msg)


## Hemostasis / pressure / dressings --" always `FP_COMBAT` in play session (grep `medical` or `FP_COMBAT`).
static func medical_session(msg: String) -> void:
    var line: String = msg.strip_edges()
    if _OperationalLog.is_play_session_active() and line == _last_medical_session_line:
        return
    _last_medical_session_line = line
    combat_session(line)


## Overworld / encounter lines during editor play (`FP_WORLD`).
static func world_session(msg: String) -> void:
    if _OperationalLog.is_play_session_active():
        _OperationalLog.play_world(msg)
    else:
        print("[World] ", msg)


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
static var _flow_log_event_last_by_key: Dictionary = {}
static var _last_medical_session_line: String = ""
static var _last_combat_session_line: String = ""


static func clear_flow_log_dedup() -> void:
    _flow_log_last_by_key.clear()
    _flow_log_event_last_by_key.clear()
    _last_medical_session_line = ""
    _last_combat_session_line = ""


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
        var mid: String = a.get("move_id", "")
        var tid: int = a.get("target_id", -1)
        var part: String = a.get("target_part", "")
        var dur_s: String = ""
        var dur_hint: String = a.get("formation_move_duration_hint", "").strip_edges()
        if not dur_hint.is_empty():
            dur_s = " {%s}" % _FormationMoveDuration.duration_hint_for_turn_display(dur_hint)
        var close_hint: String = a.get(CombatConstants.ACTION_KEY_CLOSE_LIST_HINT, "").strip_edges()
        if not close_hint.is_empty():
            dur_s = " {vs %s}" % close_hint if dur_s.is_empty() else dur_s + " vs " + close_hint
        if part.is_empty():
            parts.append("%s@%d%s" % [mid, tid, dur_s])
        else:
            parts.append("%s@%d:%s%s" % [mid, tid, part, dur_s])
    return ", ".join(parts)


static func _medical_turn_vitals_suffix(manager: Node, choice: Dictionary) -> String:
    if manager == null or not bool(manager.get("medical_phase")):
        return ""
    if not manager.has_method("_is_medical_move"):
        return ""
    var mid: String = choice.get("move_id", "")
    if not CombatConstants.is_medical_move(mid):
        return ""
    var tid: int = choice.get("target_id", -1)
    var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, tid)
    if tgt.is_empty():
        return ""
    var ent: Node = _EntityAccess.get_entity_from_manager(manager, tgt)
    if ent == null:
        return ""
    var part: String = choice.get("target_part", "")
    var bleed: float = (
        _EntityAccess.entity_bleeding_rate_for_part(manager, tgt, part)
        if not part.is_empty()
        else _EntityAccess.get_total_bleeding_rate_from_node(ent)
    )
    var bv: float = _EntityAccess.get_blood_volume_from_node(ent)
    var pressure: String = ""
    if not part.is_empty() and _EntityAccess.entity_has_direct_pressure_on_part(manager, tgt, part):
        pressure = " pressure=held"
    return " tgt_bv=%.1f tgt_bleed=%.3f%s" % [bv, bleed, pressure]


static func _is_non_damage_turn_pick(move_id: String) -> bool:
    if move_id.is_empty():
        return false
    if move_id == CombatConstants.MOVE_ID_WAIT or move_id == "pass":
        return true
    if move_id.begins_with("focus_"):
        return true
    if move_id.begins_with(CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        return true
    return false


## Short suffix for battle row gauge (non-damaging picks).
static func turn_pick_kind_suffix(move_id: String) -> String:
    if move_id.begins_with("focus_"):
        return " . Focus"
    if move_id == CombatConstants.MOVE_ID_WAIT or move_id == "pass":
        return " . Hold"
    if move_id.begins_with(CombatConstants.MOVE_ID_ATTEMPT_CLOSE):
        return " . Close"
    return ""


static func flow_log_turn(
    side: String, combatant_id: int, actions: Array, choice: Dictionary, manager: Node = null
) -> void:
    if not CombatConstants.combat_event_debug_active():
        return
    var mid: String = choice.get("move_id", "")
    var tid: int = choice.get("target_id", -1)
    var part: String = choice.get("target_part", "")
    var feint: String = choice.get("feint_part", "")
    var part_s: String = (" part=%s" % part) if not part.is_empty() else ""
    var feint_s: String = (" feint=%s" % feint) if not feint.is_empty() else ""
    var med_s: String = _medical_turn_vitals_suffix(manager, choice)
    if _is_non_damage_turn_pick(mid):
        print(
            (
                "[Combat.Flow] turn side=%s id=%d pick move_id=%s target_id=%d%s (non-damage)"
                % [side, combatant_id, mid, tid, med_s]
            )
        )
        return
    if flow_verbose_enabled():
        # Full action list is logged once in `get_available_actions`; avoid repeating it here.
        print(
            (
                "[Combat.Flow] turn side=%s id=%d pick move_id=%s target_id=%d%s%s%s (actions=%d)"
                % [side, combatant_id, mid, tid, part_s, feint_s, med_s, actions.size()]
            )
        )
    else:
        var act_str: String = format_actions_compact(actions)
        print(
            (
                "[Combat.Flow] turn side=%s id=%d actions=[%s] => pick move_id=%s target_id=%d%s%s%s"
                % [side, combatant_id, act_str, mid, tid, part_s, feint_s, med_s]
            )
        )


## lane_stress_by_file or similar: file index -> float
static func format_lane_stress(by_file: Dictionary) -> String:
    if by_file.is_empty():
        return ""
    var parts: PackedStringArray = []
    for k in by_file.keys():
        parts.append("f%s=%.2f" % [str(k), float(by_file[k])])
    return ", ".join(parts)


## Verbose `get_available_actions` summary + optional listing diagnostic (`COMBAT_EVENT_DEBUG_VERBOSE`).
static func log_available_actions_build(
    manager: Node,
    combatant_id: int,
    c: Dictionary,
    result_actions: Array,
    actions_before_counter_filter: Array,
    counter_tempo: bool,
    medical_phase: bool,
    log_fid: String,
    combatants: Array
) -> void:
    if not flow_verbose_enabled() or c.is_empty():
        return
    var medical_count: int = 0
    for a in result_actions:
        var mid: String = a.get("move_id", "")
        if CombatConstants.is_medical_move(mid):
            medical_count += 1
    var polearm_extra: String = ""
    if not medical_phase:
        var rpv: int = _EntityAccess.rank_int(c)
        if rpv > 0 and not _EntityAccess.get_attacking_arm(c).is_empty():
            var w_pv: Variant = _EntityAccess.get_weapon(c)
            if w_pv is Weapon and (w_pv as Weapon).depth_melee_eligible:
                polearm_extra = _format_depth_polearm_melee_context_debug(manager, c, w_pv as Weapon, combatants)
    var counter_filter_note: String = ""
    if counter_tempo and result_actions.size() != actions_before_counter_filter.size():
        counter_filter_note = " counter_tempo=%d->%d" % [actions_before_counter_filter.size(), result_actions.size()]
    flow_log(
        (
            (
                "get_available_actions id=%d side=%s state=%s rank=%d file=%d fid=%s med_phase=%s "
                + "=> %d actions (medical=%d) [%s]%s%s"
            )
            % [
                combatant_id,
                _EntityAccess.side_str(c),
                _EntityAccess.state_str(c),
                _EntityAccess.rank_int(c),
                _EntityAccess.file_int(c),
                log_fid,
                medical_phase,
                result_actions.size(),
                medical_count,
                format_actions_compact(result_actions),
                polearm_extra,
                counter_filter_note
            ]
        ),
        "get_available_actions:%d" % combatant_id
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
        var threaten: bool = reach_ok and line_ok and _MeleeListing.can_melee_threaten(manager, c, opp, pair_geom)
        return (
            "opp%d eff=%.2f dist=%s reach_ok=%s line_ok=%s threaten=%s" % [oid, eff, dist, reach_ok, line_ok, threaten]
        )
    return "opp%d eff=%.2f dist=%s reach_ok=%s (no spear lane -- geometry only)" % [oid, eff, dist, reach_ok]


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
        var fo: Dictionary = _ZoneOfControl.opponent_formation_for_listing(manager, c, opp, opp_zone, fd_ctx)
        bits.append(_depth_polearm_opp_debug_line(manager, c, opp, melee_range, fid_ctx, lane_open, fd_ctx, fo, true))
    if bits.is_empty():
        for opp in combatants:
            if not _EntityAccess.is_living_hostile_to(c, opp):
                continue
            if _EntityAccess.rank_int(opp) != 0:
                continue
            var fo: Dictionary = _ZoneOfControl.opponent_formation_for_listing(manager, c, opp, opp_zone, fd_ctx)
            bits.append(
                _depth_polearm_opp_debug_line(manager, c, opp, melee_range, fid_ctx, lane_open, fd_ctx, fo, false)
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
