class_name CombatCombatantsSnapshot
extends RefCounted

## UI-facing combatant rows: fresh stats from entities, debug fields, status_override for cooldowns / next turn.
## Footing exports: **`position_angle_offset_deg`** when PA flag on  -  display via **`CombatUiHints`** /
## **`#battle-ui`**. Does not stamp or clear offset. LIVE_PATHS **`#wf-tier-44-pa`** (UI phase).


## Live combatant keys required by **`BattleUIUpdater`** / **`CombatUiHints`** (not entity stats).
static func _copy_live_ui_fields(item: Dictionary, c: Dictionary) -> void:
    if c.is_empty() or item.is_empty():
        return
    if c.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
        item[CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT] = (c[
            CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT
        ])
    if c.has(CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT):
        item[CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT] = (c[
            CombatConstants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT
        ])
    if c.has(CombatConstants.COMBATANT_KEY_EXHAUSTION):
        item[CombatConstants.COMBATANT_KEY_EXHAUSTION] = c[CombatConstants.COMBATANT_KEY_EXHAUSTION]
    if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        item["guard_line"] = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
    if c.get("combat_absent", false):
        item["combat_absent"] = true
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
    if not pa.is_empty():
        item["pending_attack"] = pa.duplicate(true)
    if CombatFootwork.enabled() and CombatFootwork.offset_visible_for_ui_state(c):
        var off_deg: float = CombatFootwork.get_defender_offset_deg(c)
        if absf(off_deg) >= 0.01:
            item["position_angle_offset_deg"] = off_deg
    if CombatFlurryBind.enabled():
        for key in [CombatFlurryBind.KEY_UNTIL, CombatFlurryBind.KEY_AGAINST, CombatFlurryBind.KEY_EXCHANGES]:
            if c.has(key):
                item[key] = c[key]


static func _counter_tempo_ui_blocks_status_override(manager: Node, c: Dictionary) -> bool:
    var tempo_ui: String = CombatUiHints.counter_tempo_hint_key(c, manager)
    return tempo_ui == "counter_ready" or tempo_ui == "counter_winding"


## Cooldown / next-action line for live **`BattleUIUpdater`** (same rules as snapshot rows).
static func live_status_override_text(manager: Node, c: Dictionary) -> String:
    if manager == null or c.is_empty():
        return ""
    var cid: int = CombatantEntityAccess.id_int(c)
    if cid < 0:
        return ""
    var next_ready: Dictionary = CombatEventScheduler.build_next_action_ready_times(manager)
    return _status_override_text(manager, c, cid, next_ready)


static func _status_override_text(manager: Node, c: Dictionary, combatant_id: int, next_ready: Dictionary) -> String:
    if _counter_tempo_ui_blocks_status_override(manager, c):
        return ""
    var close_left: float = CombatantEntityAccess.cooldown_remaining_s(
        manager, c.get("action_cooldown_until", 0.0), 0.0
    )
    if close_left > 0.0:
        return "Closing %.1fs" % close_left
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if next_ready.has(combatant_id):
        var next_at: float = float(next_ready[combatant_id])
        if next_at > clock:
            return "Next: %.1fs" % (next_at - clock)
    return ""


static func build(manager: Node) -> Array:
    var out: Array = []
    var next_ready: Dictionary = CombatEventScheduler.build_next_action_ready_times(manager)
    for c in manager.combatants:
        var cid_snap: int = CombatantEntityAccess.id_int(c)
        var sn: Node = CombatantEntityAccess.scene_node(c)
        var stats: Dictionary = CombatantEntityAccess.stats_dict(c).duplicate()
        if sn != null:
            var entity = CombatantEntityAccess.get_entity_from_manager(manager, c)
            if entity != null:
                CombatantStatsSync.sync_from_entity(entity, stats)
        CombatantStatsSync.ensure_defaults(stats)
        var fid_snap: String = CombatantEntityAccess.formation_id_str(c)
        var item: Dictionary = {
            "id": cid_snap,
            "node": sn,
            "side": CombatantEntityAccess.side_str(c),
            "formation_id": fid_snap,
            "zone_geometry_fid": ZoneOfControl.zone_geometry_fid_str(manager, c),
            "formation_doctrine":
            (
                manager.get_formation_doctrine(fid_snap)
                if manager.has_method("get_formation_doctrine")
                else CombatConstants.DOCTRINE_DEFAULT
            ),
            "rank": CombatantEntityAccess.rank_int(c),
            "file": CombatantEntityAccess.file_int(c),
            "stats": stats,
            "gauge": CombatantEntityAccess.gauge_float(c),
            "stamina": CombatantEntityAccess.stamina_float(c),
            "alive": CombatantEntityAccess.alive_bool(c),
            "state": CombatantEntityAccess.state_str(c, CombatConstants.STATE_WAITING),
            "state_timer": c.get("state_timer", 0.0),
            "state_duration": c.get("state_duration", 0.0),
            "engagement_role": str(c.get("engagement_role", CombatConstants.ENGAGEMENT_ROLE_LINE)),
            "lane_offset": CombatantEntityAccess.lane_offset_float(c),
        }
        CombatUiHints.stamp_snapshot_hint_fields(item, c, manager)
        _copy_live_ui_fields(item, c)
        if CombatConstants.combat_debug_active():
            item["guard_angle_deg"] = (
                CombatFootwork.guard_angle_deg(c, {})
                if CombatFootwork.enabled()
                else CombatConstants.get_guard_angle_deg(c)
            )
        if CombatantEntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
            var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
            if pa.get(CombatConstants.PA_KEY_COUNTER_TEMPO, false):
                item["is_counter_tempo_wind_up"] = true
        var pm_raw: Variant = c.get("pending_medical", null)
        if pm_raw is Dictionary:
            item["pending_medical"] = (pm_raw as Dictionary).duplicate(true)
        else:
            item["pending_medical"] = {}
        var status_override: String = _status_override_text(manager, c, cid_snap, next_ready)
        if not status_override.is_empty():
            item["status_override"] = status_override
        out.append(item)
    return out
