class_name CombatCombatantsSnapshot
extends RefCounted

## UI-facing combatant rows: fresh stats from entities, debug fields, status_override for cooldowns / next turn.

const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func build(manager: Node) -> Array:
	var out: Array = []
	var next_ready: Dictionary = _EventScheduler.build_next_action_ready_times(manager)
	for c in manager.combatants:
		var stats = c.stats.duplicate()
		if c.node != null:
			var entity = _EntityAccess.get_entity_from_manager(manager, c)
			if entity != null:
				_StatsSync.sync_from_entity(entity, stats)
		_StatsSync.ensure_defaults(stats)
		var item: Dictionary = {
			"id": c.id,
			"node": c.node,
			"side": c.side,
			"formation_id": str(c.get("formation_id", "")),
			"rank": c.get("rank", 0),
			"file": c.get("file", 0),
			"stats": stats,
			"gauge": c.gauge,
			"stamina": c.get("stamina", CombatConstants.STAMINA_MAX),
			"alive": c.alive,
			"state": c.get("state", CombatConstants.STATE_WAITING),
			"state_timer": c.get("state_timer", 0.0),
			"state_duration": c.get("state_duration", 0.0),
			"tactical_penetration_depth": mini(
				maxi(0, int(c.get("tactical_penetration_depth", 0))),
				CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX
			),
			"engagement_role": str(c.get("engagement_role", CombatConstants.ENGAGEMENT_ROLE_LINE)),
			"intrusion_host_fid": str(c.get("intrusion_host_fid", "")),
			"intrusion_anchor_file": int(c.get("intrusion_anchor_file", -1)),
			"lane_offset": float(c.get("lane_offset", 0.0)),
		}
		if CombatConstants.COMBAT_DEBUG:
			item["guard_line"] = c.get("guard_line", CombatConstants.GUARD_DEFAULT)
			item["guard_angle_deg"] = CombatConstants.get_guard_angle_deg(c)
		var pm_raw: Variant = c.get("pending_medical", {})
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
		elif next_ready.has(c.id):
			var next_at: float = float(next_ready[c.id])
			if next_at > manager.combat_clock:
				item["status_override"] = "Next: %.1fs" % (next_at - manager.combat_clock)
		out.append(item)
	return out
