class_name CombatCombatantsSnapshot
extends RefCounted

## UI-facing combatant rows: fresh stats from entities, debug fields, status_override for cooldowns / next turn.

const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")


static func _counter_tempo_ui_blocks_status_override(manager: Node, c: Dictionary) -> bool:
	var tempo_ui: String = _UiHints.counter_tempo_hint_key(c, manager)
	return tempo_ui == "counter_ready" or tempo_ui == "counter_winding"


## Cooldown / next-action line for live **`BattleUIUpdater`** (same rules as snapshot rows).
static func live_status_override_text(manager: Node, c: Dictionary) -> String:
	if manager == null or c.is_empty():
		return ""
	var cid: int = _EntityAccess.id_int(c)
	if cid < 0:
		return ""
	var next_ready: Dictionary = _EventScheduler.build_next_action_ready_times(manager)
	return _status_override_text(manager, c, cid, next_ready)


static func _status_override_text(manager: Node, c: Dictionary, combatant_id: int, next_ready: Dictionary) -> String:
	if _counter_tempo_ui_blocks_status_override(manager, c):
		return ""
	var crash_left: float = _EntityAccess.cooldown_remaining_s(
		manager, float(c.get("crash_cooldown_until", 0.0)), 0.0
	)
	if crash_left > 0.0:
		return "Crash CD %.1fs" % crash_left
	var close_left: float = _EntityAccess.cooldown_remaining_s(
		manager, float(c.get("action_cooldown_until", 0.0)), 0.0
	)
	if close_left > 0.0:
		return "Closing %.1fs" % close_left
	var clock: float = _EntityAccess.combat_clock_float(manager)
	if next_ready.has(combatant_id):
		var next_at: float = float(next_ready[combatant_id])
		if next_at > clock:
			return "Next: %.1fs" % (next_at - clock)
	return ""


static func build(manager: Node) -> Array:
	var out: Array = []
	var next_ready: Dictionary = _EventScheduler.build_next_action_ready_times(manager)
	for c in manager.combatants:
		var cid_snap: int = _EntityAccess.id_int(c)
		var sn: Node = _EntityAccess.scene_node(c)
		var stats: Dictionary = _EntityAccess.stats_dict(c).duplicate()
		if sn != null:
			var entity = _EntityAccess.get_entity_from_manager(manager, c)
			if entity != null:
				_StatsSync.sync_from_entity(entity, stats)
		_StatsSync.ensure_defaults(stats)
		var fid_snap: String = _EntityAccess.formation_id_str(c)
		var item: Dictionary = {
			"id": cid_snap,
			"node": sn,
			"side": _EntityAccess.side_str(c),
			"formation_id": fid_snap,
			"zone_geometry_fid": _ZoneOfControl.zone_geometry_fid_str(manager, c),
			"formation_doctrine": (
				manager.get_formation_doctrine(fid_snap)
				if manager.has_method("get_formation_doctrine")
				else CombatConstants.DOCTRINE_DEFAULT
			),
			"rank": _EntityAccess.rank_int(c),
			"file": _EntityAccess.file_int(c),
			"stats": stats,
			"gauge": _EntityAccess.gauge_float(c),
			"stamina": _EntityAccess.stamina_float(c),
			"alive": _EntityAccess.alive_bool(c),
			"state": _EntityAccess.state_str(c, CombatConstants.STATE_WAITING),
			"state_timer": c.get("state_timer", 0.0),
			"state_duration": c.get("state_duration", 0.0),
			"tactical_penetration_depth": mini(
				maxi(0, _EntityAccess.tactical_penetration_depth_int(c)),
				CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
			),
			"engagement_role": str(c.get("engagement_role", CombatConstants.ENGAGEMENT_ROLE_LINE)),
			"intrusion_host_fid": _ZoneOfControl.intrusion_host_fid(c),
			"intrusion_anchor_file": _EntityAccess.intrusion_anchor_file_raw_int(c),
			"lane_offset": _EntityAccess.lane_offset_float(c),
		}
		if CombatConstants.combat_debug_active():
			item["guard_line"] = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
			item["guard_angle_deg"] = CombatConstants.get_guard_angle_deg(c)
		_UiHints.stamp_snapshot_hint_fields(item, c, manager)
		if _EntityAccess.state_str(c) == CombatConstants.STATE_WIND_UP:
			var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
			if bool(pa.get(CombatConstants.PA_KEY_COUNTER_TEMPO, false)):
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
