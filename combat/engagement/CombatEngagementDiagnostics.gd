class_name CombatEngagementDiagnostics
extends RefCounted

## F5 / play-session lines (grep **`engagement_debug`**)  -  opposition map, distance bands, non-strike picks.
## Off under headless harness quiet; on with **`OperationalLog.begin_play_session`**.

static var _fight_start_logged: bool = false


static func reset_session() -> void:
    _fight_start_logged = false


static func diagnostics_active() -> bool:
    return OperationalLog.is_play_session_active() and CombatConstants.play_session_diagnostic_active()


static func log_fight_start_summary(manager: Node) -> void:
    if not diagnostics_active() or manager == null or _fight_start_logged:
        return
    if not manager.has_meta(EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
        return
    _fight_start_logged = true
    var forms: Dictionary = manager.get("formations") as Dictionary
    var pf: int = int((forms.get("player", {}) as Dictionary).get(DataKeys.FORMATION_FILES, 1))
    var ef: int = int((forms.get("enemy", {}) as Dictionary).get(DataKeys.FORMATION_FILES, 1))
    var off_p: int = EngagementOpposition.opposition_file_offset(manager, "player")
    var off_e: int = EngagementOpposition.opposition_file_offset(manager, "enemy")
    var line_gap_p: bool = CombatFormationFlow.formation_line_has_rank0_gap(manager, "player")
    var line_gap_e: bool = CombatFormationFlow.formation_line_has_rank0_gap(manager, "enemy")
    (
        OperationalLog
        . play_combat(
            (
                (
                    "engagement_debug fight_start offset_player=%d offset_enemy=%d files=%d/%d "
                    + "skirmish_rotate_player=%s skirmish_rotate_enemy=%s line_gap_player=%s line_gap_enemy=%s"
                )
                % [
                    off_p,
                    off_e,
                    pf,
                    ef,
                    str(CombatEngagementMode.allow_rotate_file_for_formation(manager, "player")).to_lower(),
                    str(CombatEngagementMode.allow_rotate_file_for_formation(manager, "enemy")).to_lower(),
                    str(line_gap_p).to_lower(),
                    str(line_gap_e).to_lower(),
                ]
            )
        )
    )
    var pairs: PackedStringArray = _rank0_opposition_pair_lines(manager)
    for line in pairs:
        OperationalLog.play_combat("engagement_debug rank0_map %s" % line)
    OperationalLog.play_combat(
        (
            "engagement_debug hint grep engagement_debug turn  -  reach=gap/eff/reach/band/"
            + "threaten/in_swing; bind_close=true outer wing must close not rotate; "
            + "reserve_only+LONG=no strikes; in-swing at LONG lists strikes not close; "
            + "rotate needs skirmish outnumber; rotate_suppress=true sparse/mop-up/CLOSE-band/"
            + "bind_close; sparse_line=true post-flee fight-first; fight_finish=true L4b/"
            + "trusted-close tail; sparse_prefer_finish=true finish-over-shuffle; "
            + "wing_lack=true enables L4 close; mop_up=true suppresses rotate without melee; "
            + "mop_up combat tail want strikes_listed/strikes>0 not close-only stall (3e); "
            + "line_plug=false when sparse_line unless line_plug_pick=1; line_plug_pick=1 "
            + "on rank-0 gap swap/rotate or incap plug-forward swap; sparse rank-0 CLOSE/"
            + "MID omits redundant attempt_close when melee listed"
        )
    )


static func maybe_log_turn_pick(manager: Node, combatant_id: int, actions: Array, choice: Dictionary) -> void:
    if not diagnostics_active() or manager == null or choice.is_empty():
        return
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not CombatantEntityAccess.is_player_side(c):
        return
    var mid: String = str(choice.get(DataKeys.ACTION_MOVE_ID, "")).strip_edges()
    if mid.is_empty():
        return
    if not _should_log_pick(mid, actions, c, manager):
        return
    var layer: String = str(c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).strip_edges()
    var menu: String = _menu_kind(actions)
    var opposed: String = _nearest_opposed_label(manager, c)
    var reach_hint: String = _reach_hint_for_nearest_opposed(manager, c)
    var wing_lack: bool = EngagementOpposition.wing_lacks_mapped_opposition(manager, c)
    var bind_close: bool = EngagementOpposition.rank0_needs_bind_close_at_long(manager, c)
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    var mop_up: bool = CombatDoctrine.envelop_mop_up_active(manager, fid)
    var rotate_suppress: bool = CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, actions)
    var sparse_line: bool = CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
    var fight_finish: bool = CombatDoctrine.fight_finish_tail_active(manager, c, actions, combatant_id)
    var sparse_prefer_finish: bool = CombatDoctrine.sparse_line_prefer_finish_over_shuffle(
        manager, c, actions, combatant_id
    )
    var line_plug_pick: bool = (
        layer == CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
        or CombatFormationMoveListing.listed_action_is_formation_plug_pick(manager, c, choice, actions, combatant_id)
    )
    var line_plug_logged: bool = line_plug_logged_for_pick(manager, c, combatant_id, actions, choice, layer)
    var bands: String = _distance_band_summary(c)
    var counts: String = _action_menu_counts(actions)
    (
        OperationalLog
        . play_combat(
            (
                (
                    "engagement_debug turn id=%d %s file=%d rank=%d menu=%s bands=%s opposed=%s reach=%s "
                    + "mapped_opp=%s wing_lack=%s bind_close=%s mop_up=%s rotate_suppress=%s sparse_line=%s fight_finis"
                    + "h=%s sparse_prefer_finish=%s line_plug=%s %s pick=%s%s%s"
                )
                % [
                    combatant_id,
                    CombatantEntityAccess.get_display_name(c, combatant_id),
                    CombatantEntityAccess.file_int(c),
                    CombatantEntityAccess.rank_int(c),
                    menu,
                    bands,
                    opposed,
                    reach_hint,
                    str(not wing_lack).to_lower(),
                    str(wing_lack).to_lower(),
                    str(bind_close).to_lower(),
                    str(mop_up).to_lower(),
                    str(rotate_suppress).to_lower(),
                    str(sparse_line).to_lower(),
                    str(fight_finish).to_lower(),
                    str(sparse_prefer_finish).to_lower(),
                    str(line_plug_logged).to_lower(),
                    counts,
                    mid,
                    (" layer=" + layer) if not layer.is_empty() else "",
                    " line_plug_pick=1" if line_plug_pick else "",
                ]
            )
        )
    )


## Harness / F5: whether **`line_plug=true`** should appear on the turn line (sparse -> plug pick only).
## Canonical: **`listed_action_is_formation_plug_pick`** (`CombatFormationMoveListing`) . MS-L5 **`FORMATION_PLUG`**
## layer.
static func line_plug_logged_for_pick(
    manager: Node, c: Dictionary, combatant_id: int, actions: Array, choice: Dictionary, layer: String = ""
) -> bool:
    if manager == null or c.is_empty() or choice.is_empty():
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    var sparse_line: bool = CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
    var line_plug: bool = CombatFormationFlow.formation_line_has_rank0_gap(manager, fid)
    var layer_s: String = layer
    if layer_s.is_empty():
        layer_s = str(c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")).strip_edges()
    var line_plug_pick: bool = (
        layer_s == CombatConstants.MENTAL_STACK_LAYER_FORMATION_PLUG
        or CombatFormationMoveListing.listed_action_is_formation_plug_pick(manager, c, choice, actions, combatant_id)
    )
    if sparse_line:
        return line_plug_pick
    return line_plug or line_plug_pick


## F5 engagement_debug: posture / formation / close picks (not ordinary strikes).
static func _is_engagement_pick_trace_move(move_id: String) -> bool:
    var mid: String = move_id
    return (
        mid == CombatConstants.MOVE_ID_WAIT
        or mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
        or CombatConstants.is_formation_movement_move(mid)
    )


static func _should_log_pick(move_id: String, actions: Array, c: Dictionary, manager: Node) -> bool:
    if manager != null:
        var cid: int = CombatantEntityAccess.id_int(c)
        var fid: String = CombatantEntityAccess.formation_id_str(c)
        if (
            CombatDoctrine.envelop_mop_up_active(manager, fid)
            and CombatListedActions.action_list_has_hostile_melee_strike(actions, cid)
        ):
            return true
        if CombatDoctrine.fight_finish_tail_active(manager, c, actions, cid):
            return true
    if CombatListedActions.action_list_is_reserve_posture_only(actions):
        return true
    if _is_engagement_pick_trace_move(move_id):
        return true
    if not c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "").is_empty():
        return true
    return false


static func _menu_kind(actions: Array) -> String:
    if CombatListedActions.action_list_is_reserve_posture_only(actions):
        return "reserve_only"
    if CombatListedActions.action_list_is_hold_line_only(actions):
        return "hold_only"
    return "strikes_listed"


static func _action_menu_counts(actions: Array) -> String:
    var strikes: int = 0
    var close_n: int = 0
    var rotate_n: int = 0
    var wait_n: int = 0
    for raw in actions:
        if raw is not Dictionary:
            continue
        var mid: String = str((raw as Dictionary).get(DataKeys.ACTION_MOVE_ID, ""))
        match mid:
            CombatConstants.MOVE_ID_WAIT:
                wait_n += 1
            CombatConstants.MOVE_ID_ROTATE_FILE:
                rotate_n += 1
            CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
                close_n += 1
            CombatConstants.MOVE_ID_SWAP_RANK, CombatConstants.MOVE_ID_DRAG_BACK:
                pass
            CombatConstants.MOVE_ID_FALL_BACK, CombatConstants.MOVE_ID_FLEE:
                pass
            CombatConstants.MOVE_ID_PLUG_FORWARD:
                pass
            _:
                if not mid.begins_with("focus_") and not mid.is_empty():
                    strikes += 1
    return "strikes=%d close=%d rotate=%d wait=%d" % [strikes, close_n, rotate_n, wait_n]


static func _distance_band_summary(c: Dictionary) -> String:
    var d_to: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, DataKeys.COMBATANT_DISTANCE_TO)
    if d_to.is_empty():
        return "(none)"
    var parts: PackedStringArray = PackedStringArray()
    for oid in d_to.keys():
        var band: String = str(d_to[oid])
        parts.append("e%d:%s" % [int(oid), band])
    parts.sort()
    return ", ".join(parts) if not parts.is_empty() else "(none)"


static func _nearest_opposed_label(manager: Node, actor: Dictionary) -> String:
    if manager == null or actor.is_empty():
        return " - "
    var side: String = CombatantEntityAccess.side_str(actor)
    var offset: int = EngagementOpposition.opposition_file_offset(manager, side)
    var actor_file: int = CombatantEntityAccess.file_int(actor)
    var best_dist: int = 999999
    var best: Dictionary = {}
    var mapping: String = "none"
    for opp in manager.combatants:
        if not CombatantEntityAccess.is_living_hostile_to(actor, opp):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        if not CombatMeleeRankTargeting.opp_matches_melee_rank_target(manager, actor, opp, 0):
            continue
        var opp_file: int = CombatantEntityAccess.file_int(opp)
        var dist: int = absi(actor_file - (opp_file + offset))
        if dist < best_dist:
            best_dist = dist
            best = opp
            mapping = ("strict" if actor_file == opp_file + offset else ("nearest@%d" % dist))
    if best.is_empty():
        return "none"
    return (
        "%s@f%d(%s)"
        % [
            CombatantEntityAccess.get_display_name(best, CombatantEntityAccess.id_int(best)),
            CombatantEntityAccess.file_int(best),
            mapping,
        ]
    )


static func _reach_hint_for_nearest_opposed(manager: Node, actor: Dictionary) -> String:
    if manager == null or actor.is_empty():
        return " - "
    var side: String = CombatantEntityAccess.side_str(actor)
    var offset: int = EngagementOpposition.opposition_file_offset(manager, side)
    var actor_file: int = CombatantEntityAccess.file_int(actor)
    var best_dist: int = 999999
    var best: Dictionary = {}
    for opp in manager.combatants:
        if not CombatantEntityAccess.is_living_hostile_to(actor, opp):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        if not CombatMeleeRankTargeting.opp_matches_melee_rank_target(manager, actor, opp, 0):
            continue
        if not EngagementOpposition.is_mapped_file_opposed(manager, actor, opp):
            continue
        var opp_file: int = CombatantEntityAccess.file_int(opp)
        var map_d: int = absi(actor_file - (opp_file + offset))
        if map_d < best_dist:
            best_dist = map_d
            best = opp
    if best.is_empty():
        return "none"
    var oid: int = CombatantEntityAccess.id_int(best)
    var ctx: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, actor)
    var fo: Dictionary = ZoneOfControl.opponent_formation_for_listing(manager, actor, best, {}, ctx)
    var fc: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx)
    var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, actor, best, fc, fo)
    var eff: float = CombatPairGeometry.cached_eff_dist(pair_geom)
    var reach: float = CombatMeleeListing.melee_weapon_reach(actor)
    var band: String = CombatantEntityAccess.distance_to_opponent_band(actor, oid, "")
    var gap: int = EngagementOpposition.mapped_opposition_file_distance(manager, actor, best)
    var in_swing: bool = CombatPairGeometry.melee_reach_covers_eff_dist(reach, eff)
    var threaten: bool = CombatMeleeListing.can_melee_threaten(manager, actor, best, pair_geom)
    return (
        "gap=%d eff=%.2f reach=%.2f band=%s threaten=%s in_swing=%s"
        % [gap, eff, reach, band, str(threaten).to_lower(), str(in_swing).to_lower()]
    )


static func _rank0_opposition_pair_lines(manager: Node) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    var players: Array = []
    for c in manager.combatants:
        if (
            CombatantEntityAccess.is_player_side(c)
            and CombatantEntityAccess.rank_int(c) == 0
            and CombatantEntityAccess.alive_bool(c)
        ):
            players.append(c)
    players.sort_custom(func(a, b): return CombatantEntityAccess.file_int(a) < CombatantEntityAccess.file_int(b))
    for p in players:
        var pf: int = CombatantEntityAccess.file_int(p)
        var label: String = _nearest_opposed_label(manager, p)
        var reach: String = _reach_hint_for_nearest_opposed(manager, p)
        out.append("p_f%d->%s %s" % [pf, label, reach])
    return out
