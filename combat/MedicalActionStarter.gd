class_name MedicalActionStarter
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")

## Starts a medical action: direct pressure (instant or during wind-up), bandage/tourniquet/pack wind-up.
## **Read order:** wind-up pressure helper → `start` (coord gate → instant pressure → wind-up schedule).
## Canonical: **`CombatMedicalCoordination.medical_action_allowed`** · log: **`CombatDebug.medical_session`**.
## Manager must have: **`CombatantEntityAccess.manager_get_combatant`**, `get_health_entity`, `emit_signal`.

static func _try_windup_pressure_while_preparing(
	manager: Node,
	performer: Dictionary,
	target: Dictionary,
	target_part: String,
	medical_id: String,
	self_target: bool
) -> void:
	if target_part.is_empty() or not _EntityAccess.entity_has_wound_part(manager, target, target_part):
		return
	var who_name: String = _EntityAccess.get_display_name(performer)
	if self_target:
		var tgt_entity_self: Node = _EntityAccess.get_entity_from_manager(manager, target)
		if (
			tgt_entity_self != null
			and tgt_entity_self.get("direct_pressure_part") == target_part
			and tgt_entity_self.get("direct_pressure_held_by") != null
		):
			var perf_entity_self: Node = _EntityAccess.get_entity_from_manager(manager, performer)
			if (
				perf_entity_self != null
				and _EntityAccess.entity_stack_assist_pressure_during_ally_treatment(
					manager, target, performer, target_part
				)
			):
				_CombatDebug.medical_session(
					"%s assisting existing pressure on %s during %s wind-up"
					% [who_name, target_part, medical_id]
				)
				return
		if _EntityAccess.entity_apply_direct_pressure(manager, target, target_part):
			_CombatDebug.medical_session(
				"%s applying direct pressure on %s during %s wind-up"
				% [who_name, target_part, medical_id]
			)
		return
	if _EntityAccess.entity_stack_assist_pressure_during_ally_treatment(
		manager, target, performer, target_part
	):
		_CombatDebug.medical_session(
			"%s assisting pressure on ally's %s during %s wind-up (helper still holding)"
			% [who_name, target_part, medical_id]
		)
		return
	if _EntityAccess.entity_apply_direct_pressure_from_ally(manager, target, performer, target_part):
		var tgt_entity: Node = _EntityAccess.get_entity_from_manager(manager, target)
		_EntityAccess.link_performer_direct_pressure_on_ally(manager, performer, tgt_entity, target_part)
		_CombatDebug.medical_session(
			"%s applying direct pressure on ally's %s during %s wind-up"
			% [who_name, target_part, medical_id]
		)


static func start(manager: Node, combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String) -> void:
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	var target_node: Dictionary = _EntityAccess.manager_get_combatant(manager, target_combatant_id)
	if c.is_empty() or target_node.is_empty() or _EntityAccess.scene_node(target_node) == null:
		return
	if manager.medical_phase and _MedicalPhase.is_losing_side(manager, c):
		return
	if not _MedicalCoord.medical_action_allowed(
		manager, combatant_id, target_combatant_id, target_part, medical_id
	):
		return
	# Clear pending_retry when starting a different action (e.g. helping another ally)
	var pr_raw: Variant = c.get("pending_retry", null)
	if typeof(pr_raw) == TYPE_DICTIONARY:
		var pr: Dictionary = pr_raw as Dictionary
		if not pr.is_empty() and (pr.get("target_id", -1) != target_combatant_id or pr.get("part", "") != target_part):
			c["pending_retry"] = {}
	var who_name: String = _EntityAccess.get_display_name(c, combatant_id)
	# Bandage/pack/tourniquet: free treater's other holds; keep compression on the wound being dressed.
	if CombatConstants.is_wind_up_medical_move(medical_id):
		_EntityAccess.prepare_for_medical_windup_scene(manager, c, target_node, target_part)
		_try_windup_pressure_while_preparing(
			manager, c, target_node, target_part, medical_id, target_combatant_id == combatant_id
		)
	var duration: float = 0.0
	if CombatConstants.is_direct_pressure_move(medical_id):
		# Instant: apply now, then short recovery (scaled by pain/consciousness)
		var med_rec_dur: float = CombatConstants.RECOVERY_AFTER_MEDICAL_S
		var med_perf: float = _EntityAccess.get_performance_modifier(c)
		if med_perf > 0.0:
			med_rec_dur /= maxf(CombatConstants.PERF_MOD_MIN, med_perf)
		var applied: bool = false
		if target_combatant_id == combatant_id:
			applied = _EntityAccess.scene_apply_direct_pressure(target_node, target_part)
		elif _MedicalCoord.can_stack_assist_pressure(
			manager, combatant_id, target_combatant_id, target_part
		):
			if _EntityAccess.entity_stack_assist_pressure_during_ally_treatment(
				manager, target_node, c, target_part
			):
				applied = true
				_CombatDebug.medical_session(
					"%s treatment-assist pressure on ally's %s" % [who_name, target_part]
				)
		elif _EntityAccess.entity_apply_direct_pressure_from_ally(manager, target_node, c, target_part):
			applied = true
			_EntityAccess.link_performer_direct_pressure_on_ally(
				manager,
				c,
				_EntityAccess.get_entity_from_manager(manager, target_node),
				target_part
			)
		if applied:
			if not _OperationalLog.is_play_session_active():
				_CombatDebug.medical_session(
					"%s applied direct_pressure on %s (instant) => recovery %.1fs"
					% [who_name, target_part, med_rec_dur]
				)
			manager.emit_signal("action_resolved", combatant_id, target_combatant_id, {"outcome": "direct_pressure", "part": target_part, "dmg": 0, "died": false})
		c.gauge = 0.0
		c["guard"] = CombatConstants.GUARD_AFTER_ATTACK
		c.state = CombatConstants.STATE_RECOVERING
		c.state_timer = 0.0
		c.state_duration = med_rec_dur
		return
	var wind_raw: Variant = CombatConstants.MEDICAL_WIND_UP_CONFIG.get(medical_id, {})
	var wind_up_cfg: Dictionary = wind_raw if wind_raw is Dictionary else {}
	var dur_method: String = wind_up_cfg.get("duration_method", "")
	var dur_takes_part: bool = wind_up_cfg.get("duration_takes_part", false)
	var target_entity = _EntityAccess.get_entity_from_manager(manager, target_node)
	if not dur_method.is_empty() and target_entity != null and target_entity.has_method(dur_method):
		if dur_takes_part and not target_part.is_empty():
			duration = target_entity.call(dur_method, target_part)
		else:
			duration = target_entity.call(dur_method)
	if duration <= 0.0 and not wind_up_cfg.is_empty():
		duration = 4.0  # fallback for custom entities
	var speed_mod: float = _EntityAccess.get_medical_windup_speed_modifier(manager, c, target_node)
	if speed_mod > 0.0:
		duration /= speed_mod
	var assist_div: float = _EntityAccess.get_medical_windup_assist_duration_divisor(
		manager, target_node, target_part
	)
	if assist_div > 1.0:
		duration /= assist_div
	if not _OperationalLog.is_play_session_active():
		_CombatDebug.medical_session(
			"%s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration]
		)
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
