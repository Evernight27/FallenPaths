class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## Manager must have: emit_signal, _get_by_id, _check_for_winner, _end_combat_phase, _execute_attack.
## Updates guard_line (weapon position) whenever weapon is used: attack, parry.

const _Afterblow := preload("res://combat/AfterblowHandler.gd")
const _GuardUpdater := preload("res://combat/GuardLineUpdater.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
	if CombatConstants.COMBAT_DEBUG:
		CombatDebug.log("outcome %s atk=%d tgt=%d" % [action, atk_id, tgt_id])

static func _consume_stamina(c: Dictionary, amount: float) -> void:
	if c == null:
		return
	var s: float = c.get("stamina", CombatConstants.STAMINA_MAX)
	c["stamina"] = maxf(0.0, s - amount)

static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
	var action: String = result.get("action", "skip")
	var target_id: int = result.get("target_id", -1)
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id) if target_id >= 0 else null
	var empty_result: Dictionary = {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0}

	if action == "skip":
		if atk != null:
			if result.get("recovery_duration", 0.0) > 0.0:
				empty_result["outcome"] = "skip"
				manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
				atk["last_move_id"] = atk.pending_attack.get("attack_type", "")
				atk["effective_attack_line"] = atk.pending_attack.get("effective_attack_line", "")
				atk["recovery_cause"] = "skip"
				_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.recovery_duration
			else:
				atk.state = CombatConstants.STATE_WAITING
				atk.gauge = 0.0
		return
	if action == "defeated":
		if tgt != null:
			tgt.alive = false
			tgt.state = CombatConstants.STATE_DEAD
		empty_result["outcome"] = "defeated"
		empty_result["died"] = true
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		var winner: String = manager._check_for_winner()
		if not winner.is_empty():
			manager._end_combat_phase(winner, tgt.node if tgt != null else null)
		return
	if action == "miss":
		empty_result["outcome"] = "miss"
		_log_outcome("miss", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if atk != null:
			atk["last_move_id"] = atk.pending_attack.get("attack_type", "")
			atk["effective_attack_line"] = atk.pending_attack.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + CombatConstants.OFF_BALANCE_DURATION_S
		return
	if action == "dodge":
		empty_result["outcome"] = "dodge"
		_log_outcome("dodge", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if atk != null:
			atk["last_move_id"] = atk.pending_attack.get("attack_type", "")
			atk["effective_attack_line"] = atk.pending_attack.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		if tgt != null:
			# Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
			# Use effective_attack_line for diagonal moves (actual trajectory).
			var pa: Dictionary = atk.pending_attack if atk != null else {}
			var move_id: String = pa.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
			var atk_line: String = pa.get("effective_attack_line", move_def.get("attack_line", "high"))
			var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(atk_line, tgt.get("guard_line", "high"))
			_GuardUpdater.set_guard_from_line(tgt, dodge_guard)
			if CombatConstants.COMBAT_DEBUG:
				CombatDebug.log("guard_line %s: -> %s (dodged %s)" % ["id:%d" % tgt.get("id", -1), dodge_guard, atk_line])
		return
	if action == "parry_deflect":
		if atk != null:
			var pa_deflect: Dictionary = atk.pending_attack
			atk["last_move_id"] = pa_deflect.get("attack_type", "")
			atk["effective_attack_line"] = pa_deflect.get("effective_attack_line", "")
			# HEMA: store defender's guard and parry_clash_context for bind vs deflect.
			atk["defender_guard_line_at_parry"] = tgt.get("guard_line", "high") if tgt != null else ""
			atk["parry_clash_context"] = result.get("parry_clash_context", {})
			atk.pending_attack = {}
			atk["recovery_cause"] = "attack_deflect"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + CombatConstants.OFF_BALANCE_DURATION_S
		if tgt != null:
			_consume_stamina(tgt, CombatConstants.STAMINA_PARRY_COST)
			# Weapon position: defender's blade met attacker's; blade ends in attack line.
			# Use effective_attack_line for diagonal moves (actual contact line).
			var move_id: String = atk.get("last_move_id", "")
			var eff_line: String = atk.get("effective_attack_line", "")
			_GuardUpdater.set_guard_from_move(tgt, move_id, eff_line)
			tgt["parry_bonus_until"] = Time.get_ticks_msec() / 1000.0 + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
			var clash: Dictionary = result.get("parry_clash_context", {})
			var arch_id: String = clash.get("archetype_id", "")
			var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
			tgt["parry_was_bind"] = can_bind and clash.get("parry_control", 0.0) >= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
			tgt["parry_against_id"] = attacker_id
			tgt.state = CombatConstants.STATE_WAITING
			tgt.state_timer = 0.0
			tgt.state_duration = 0.0
		empty_result["outcome"] = "parry_deflect"
		_log_outcome("parry_deflect", attacker_id, target_id)
		manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
		return
	if action == "parry_partial":
		if tgt != null:
			_consume_stamina(tgt, CombatConstants.STAMINA_PARRY_COST)
			# Weapon position: only update when alignment was good (blade properly met attack).
			# Use effective_attack_line for diagonal moves (actual contact line).
			var pa_partial: Dictionary = atk.pending_attack if atk != null else {}
			var move_id: String = pa_partial.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id)
			var atk_line: String = pa_partial.get("effective_attack_line", move_def.get("attack_line", "high"))
			var align_ctx: Dictionary = {}
			if pa_partial.get("attack_angle_deg", -999.0) >= 0.0:
				var read: float = _PassiveParry.get_passive_parry_readiness(tgt)
				var def_w = _EntityAccess.get_weapon(tgt)
				var def_mass_partial: float = float(def_w.mass) if def_w != null and (def_w.get("mass") is float or def_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
				var wob: Dictionary = {"parry_readiness": read, "defender_mass_kg": def_mass_partial}
				align_ctx = {"attack_angle_deg": pa_partial["attack_angle_deg"], "guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt, wob)}
			var align: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
			if align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
				_GuardUpdater.set_guard_from_move(tgt, move_id, atk_line)
			tgt.state = CombatConstants.STATE_WAITING
			tgt.state_timer = 0.0
			tgt.state_duration = 0.0
		_log_outcome("parry_partial", attacker_id, target_id)
		manager._execute_attack(attacker_id)
		return
	if action == "hit":
		var result_dict: Dictionary = result.get("result_dict", {})
		var intensity: float = result.get("intensity", 0.5)
		var winner: String = ""
		if result_dict.get("died", false):
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			winner = manager._check_for_winner()
			if not winner.is_empty():
				manager._end_combat_phase(winner, tgt.node if tgt != null else null)
			return
		winner = manager._check_for_winner()
		if not winner.is_empty():
			if tgt != null and tgt.node != null and tgt.node.has_method("is_incapacitated") and tgt.node.is_incapacitated():
				var reason: String = "consciousness < 10%%"
				if tgt.node.has_method("is_cowering") and tgt.node.is_cowering():
					reason = "cowering (no functional arms)"
				print("[Combat] INCAPACITATED: %s (%s)" % [tgt.node.name if tgt.node != null else target_id, reason])
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			manager._end_combat_phase(winner, tgt.node if tgt != null else null)
			return
		_Afterblow.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
		# last_move_id set in AttackResolver before clearing pending_attack
		_log_outcome("hit", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
		if atk != null and atk.alive:
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk["effective_attack_line"] = atk.get("effective_attack_line", "")  # Set in AttackResolver before clear
			atk["recovery_cause"] = "attack_hit"
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		if tgt != null and tgt.alive:
			# Defender was hit; stagger/dropped guard — blade ends low. Sync guard_zone.
			_GuardUpdater.set_guard_from_line(tgt, "low")
		return
