class_name CombatCombatantsSnapshot
extends RefCounted

## UI-facing combatant rows: fresh stats from entities, debug fields, status_override for cooldowns / next turn.

const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")


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
			"lane_offset": float(c.get("lane_offset", 0.0)),
		}
		if CombatConstants.COMBAT_DEBUG:
			item["guard_line"] = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
			item["guard_angle_deg"] = CombatConstants.get_guard_angle_deg(c)
		if _Footwork.enabled():
			var off_deg: float = _Footwork.get_defender_offset_deg(c)
			if absf(off_deg) >= 0.01:
				item["position_angle_offset_deg"] = off_deg
			var fw_hint: String = str(
				c.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT, "")
			).strip_edges()
			if not fw_hint.is_empty():
				item["position_angle_ui_hint"] = fw_hint
		var pm_raw: Variant = c.get("pending_medical", null)
		if pm_raw is Dictionary:
			item["pending_medical"] = (pm_raw as Dictionary).duplicate(true)
		else:
			item["pending_medical"] = {}
		var crash_cd_until: float = float(c.get("crash_cooldown_until", 0.0))
		var action_cd_until: float = float(c.get("action_cooldown_until", 0.0))
		if crash_cd_until > manager.combat_clock:
			item["status_override"] = "Crash CD %.1fs" % (crash_cd_until - manager.combat_clock)
		elif action_cd_until > manager.combat_clock:
			item["status_override"] = "Closing %.1fs" % (action_cd_until - manager.combat_clock)
		elif next_ready.has(cid_snap):
			var next_at: float = float(next_ready[cid_snap])
			if next_at > manager.combat_clock:
				item["status_override"] = "Next: %.1fs" % (next_at - manager.combat_clock)
		out.append(item)
	return out
