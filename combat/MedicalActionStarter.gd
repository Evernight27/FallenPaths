class_name MedicalActionStarter
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Starts a medical action: direct pressure (instant or during wind-up), bandage/tourniquet/pack wind-up.
## Manager must have: _get_by_id, _get_entity, emit_signal.

static func start(manager: Node, combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String) -> void:
	var c = manager._get_by_id(combatant_id)
	var target_node = manager._get_by_id(target_combatant_id)
	if c == null or target_node == null or target_node.node == null:
		return
	# Clear pending_retry when starting a different action (e.g. helping another ally)
	var pr = c.get("pending_retry", {})
	if not pr.is_empty() and (pr.get("target_id", -1) != target_combatant_id or pr.get("part", "") != target_part):
		c.pending_retry = {}
	var who_name: String = c.node.name if (c.node != null) else "id:%d" % combatant_id
	# Bandage/tourniquet: performer stops holding direct pressure on anyone (new action)
	if medical_id == "bandage_self" or medical_id == "pack_wound" or medical_id == "apply_tourniquet":
		if c.node != null and c.node.has_method("clear_direct_pressure"):
			c.node.clear_direct_pressure()
		# Apply direct pressure to the part being bandaged/tourniqueted during wind-up (reduces bleeding while preparing)
		if not target_part.is_empty():
			var tgt_entity = manager._get_entity(target_node.node)
			var performer_entity = manager._get_entity(c.node)
			if tgt_entity != null and tgt_entity.has_method("get_wounds") and tgt_entity.get_wounds().has(target_part):
				if target_combatant_id == combatant_id:
					if tgt_entity.has_method("apply_direct_pressure") and tgt_entity.apply_direct_pressure(target_part):
						print("[Combat] Medical: %s applying direct pressure on %s during %s wind-up" % [who_name, target_part, medical_id])
				else:
					if tgt_entity.has_method("apply_direct_pressure_from_ally") and tgt_entity.apply_direct_pressure_from_ally(target_part, performer_entity):
						if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
							performer_entity.direct_pressure_on_ally = {"node": tgt_entity, "part": target_part}
						print("[Combat] Medical: %s applying direct pressure on ally's %s during %s wind-up" % [who_name, target_part, medical_id])
	var duration: float = 0.0
	if medical_id == "apply_direct_pressure":
		# Instant: apply now, then short recovery (scaled by pain/consciousness)
		var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
		var med_perf: float = 1.0
		if c.node != null and c.node.has_method("get_performance_modifier"):
			med_perf = c.node.get_performance_modifier()
		if med_perf > 0.0:
			med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
		var applied: bool = false
		if target_combatant_id == combatant_id:
			# Self
			if target_node.node.has_method("apply_direct_pressure") and target_node.node.apply_direct_pressure(target_part):
				applied = true
		else:
			# Ally: performer applies to target
			var tgt_ent = manager._get_entity(target_node.node)
			var performer_entity = manager._get_entity(c.node)
			if tgt_ent != null and tgt_ent.has_method("apply_direct_pressure_from_ally") and tgt_ent.apply_direct_pressure_from_ally(target_part, performer_entity):
				applied = true
				if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
					performer_entity.direct_pressure_on_ally = {"node": tgt_ent, "part": target_part}
		if applied:
			print("[Combat] Medical: %s applied direct_pressure on %s (instant) => recovery %.1fs" % [who_name, target_part, med_rec_dur])
			manager.emit_signal("action_resolved", combatant_id, target_combatant_id, {"outcome": "direct_pressure", "part": target_part, "dmg": 0, "died": false})
		c.gauge = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		c.state = CombatConstants.STATE_RECOVERING
		c.state_timer = 0.0
		c.state_duration = med_rec_dur
		return
	var wind_up_cfg = CombatConstants.MEDICAL_WIND_UP_CONFIG.get(medical_id, {})
	var dur_method: String = wind_up_cfg.get("duration_method", "")
	var dur_takes_part: bool = wind_up_cfg.get("duration_takes_part", false)
	var target_entity = manager._get_entity(target_node.node)
	if not dur_method.is_empty() and target_entity != null and target_entity.has_method(dur_method):
		if dur_takes_part and not target_part.is_empty():
			duration = target_entity.call(dur_method, target_part)
		else:
			duration = target_entity.call(dur_method)
	if duration <= 0.0 and not wind_up_cfg.is_empty():
		duration = 4.0  # fallback for custom entities
	# Pain/consciousness: wounded entities take longer to apply medical actions
	var perf_mod: float = 1.0
	if c.node != null and c.node.has_method("get_performance_modifier"):
		perf_mod = c.node.get_performance_modifier()
	if perf_mod > 0.0:
		duration /= maxf(CombatConstants.PERF_MOD_MIN, perf_mod)
	# Intelligence (medical effectiveness): higher INT shortens medical wind-up
	var perf_entity = manager._get_entity(c.node)
	var med_eff: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
	if med_eff > 0.0:
		duration /= maxf(0.5, med_eff)
	print("[Combat] Medical: %s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration])
	c.gauge = 0.0
	c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	c.state = CombatConstants.STATE_MEDICAL_WIND_UP
	c.state_timer = 0.0
	c.state_duration = duration
	c.pending_medical = {"medical_id": medical_id, "target_part": target_part, "target_combatant_id": target_combatant_id}
	# Target (ally) enters receiving_medical_attention: gauge full, cannot act until care finishes
	if target_combatant_id != combatant_id:
		target_node.receiving_medical_count = target_node.get("receiving_medical_count", 0) + 1
		target_node.state = CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		target_node.gauge = 100.0
