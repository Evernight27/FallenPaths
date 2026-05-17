class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## **`parry_deflect`**: records **`CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`** on **`attacker`** for Tier **4.2** feint listing pressure vs **`target_id`**; **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload ( **`parry_clash_context`** copied when resolver supplied a dict — **`BattleScene`** parameter names follow slot order).
## **`parry_partial`**: **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload (**defender**, **attacker**, same slot order as **`parry_deflect`**); then **`_execute_attack`** continues the strike. Resolver **`parry_clash_context`** is copied onto the **attacker** dict and onto the emitted payload when present. When the defender meets the same blade-alignment gate used for guard updates and clash **`parry_control`** crosses the bind threshold (**`PARRY_BIND_CONTROL_THRESHOLD`**), set **`parry_was_bind`**, **`parry_against_id`**, **`parry_bonus_until`** on the defender like **`parry_deflect`** so bind-riposte wind-up can apply; aligned but sub-threshold control sets **`parry_was_bind`** false; misaligned partial **`erase`**s those keys (clears stale bind state).
## Manager must have: emit_signal, _get_by_id, _check_for_winner, _end_combat_phase, _execute_attack.
## **`hit`**: clears **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the attacker (stale partial-parry calibration after follow-through); clears Tier **4.2** feint listing parry-deflect memory for **`target_id`**.

const _Afterblow := preload("res://combat/AfterblowHandler.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _GuardUpdater := preload("res://combat/GuardLineUpdater.gd")
const _PassiveParry := preload("res://combat/PassiveParryContext.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")

static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
	if CombatConstants.COMBAT_DEBUG:
		CombatDebug.log("outcome %s atk=%d tgt=%d" % [action, atk_id, tgt_id])

static func _consume_stamina(c: Dictionary, amount: float) -> void:
	if c == null:
		return
	var s: float = _EntityAccess.stamina_float(c)
	c["stamina"] = maxf(0.0, s - amount)


static func _pending_attack_read(atk: Dictionary) -> Dictionary:
	return _EntityAccess.nested_dictionary_read(atk, "pending_attack")


static func _clear_attacker_pending_attack(atk: Dictionary, manager: Node) -> void:
	if atk == null:
		return
	var pa0: Dictionary = _pending_attack_read(atk)
	_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa0)
	_Footwork.clear_position_offset(atk)
	atk.pending_attack = {}


static func _clear_defender_footwork(tgt: Dictionary) -> void:
	if tgt != null:
		_Footwork.clear_position_offset(tgt)


static func _abort_incoming_wind_up_if_target_died(manager: Node, target_id: int) -> void:
	if manager == null or target_id < 0:
		return
	var tgt: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(target_id))
	if tgt.is_empty() or _EntityAccess.alive_bool(tgt):
		return
	_CounterTempo.abort_attacker_wind_up(manager, target_id)


## Parry outcomes default the defender to waiting. Paired formation moves (`swap_rank` / drag / fall_back_pair)
## keep both partners in motion state until resolve — do not clobber that here.
static func _defender_set_idle_after_parry(tgt: Dictionary) -> void:
	if tgt == null:
		return
	if _EntityAccess.state_str(tgt) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
		return
	tgt.state = CombatConstants.STATE_WAITING
	tgt.state_timer = 0.0
	tgt.state_duration = 0.0


static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
	var action: String = result.get("action", "skip")
	var target_id: int = result.get("target_id", -1)
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id) if target_id >= 0 else null
	var tgt_scene: Node = _EntityAccess.scene_node(tgt) if tgt != null else null
	var empty_result: Dictionary = {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0}

	if action == "skip":
		if atk != null:
			if result.get("recovery_duration", 0.0) > 0.0:
				empty_result["outcome"] = "skip"
				manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
				var pa_skip: Dictionary = _pending_attack_read(atk)
				atk["last_move_id"] = pa_skip.get("attack_type", "")
				atk["effective_attack_line"] = pa_skip.get("effective_attack_line", "")
				atk["recovery_cause"] = "skip"
				_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.recovery_duration
				_clear_attacker_pending_attack(atk, manager)
			else:
				atk.state = CombatConstants.STATE_WAITING
				atk.gauge = 0.0
				_clear_attacker_pending_attack(atk, manager)
		return
	if action == "defeated":
		if tgt != null:
			tgt.alive = false
			tgt.state = CombatConstants.STATE_DEAD
			_clear_defender_footwork(tgt)
		if atk != null:
			# Resolver abort (e.g. no targetable parts): do not leave attacker stuck in WIND_UP with stale `pending_attack`.
			_clear_attacker_pending_attack(atk, manager)
			atk.state = CombatConstants.STATE_WAITING
			atk.gauge = 0.0
			atk.state_timer = 0.0
			atk.state_duration = 0.0
		empty_result["outcome"] = "defeated"
		empty_result["died"] = true
		_abort_incoming_wind_up_if_target_died(manager, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		var winner: String = manager._check_for_winner()
		if not winner.is_empty():
			manager._end_combat_phase(winner, tgt_scene)
		return
	if action == "miss":
		empty_result["outcome"] = "miss"
		_log_outcome("miss", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if atk != null:
			var pa_miss: Dictionary = _pending_attack_read(atk)
			atk["last_move_id"] = pa_miss.get("attack_type", "")
			atk["effective_attack_line"] = pa_miss.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
			_clear_attacker_pending_attack(atk, manager)
		_clear_defender_footwork(tgt)
		return
	if action == "dodge":
		empty_result["outcome"] = "dodge"
		_log_outcome("dodge", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if atk != null:
			var pa_dodge_atk: Dictionary = _pending_attack_read(atk)
			atk["last_move_id"] = pa_dodge_atk.get("attack_type", "")
			atk["effective_attack_line"] = pa_dodge_atk.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		if tgt != null:
			# Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
			# Use effective_attack_line for diagonal moves (actual trajectory).
			var pa: Dictionary = _pending_attack_read(atk) if atk != null else {}
			var move_id: String = pa.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
			var atk_line: String = pa.get("effective_attack_line", move_def.get("attack_line", "high"))
			var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(atk_line, tgt.get("guard_line", CombatConstants.GUARD_DEFAULT))
			_GuardUpdater.set_guard_from_line(tgt, dodge_guard)
			if CombatConstants.COMBAT_DEBUG:
				CombatDebug.log("guard_line %s: -> %s (dodged %s)" % ["id:%d" % _EntityAccess.id_int(tgt), dodge_guard, atk_line])
		if atk != null:
			_clear_attacker_pending_attack(atk, manager)
		_clear_defender_footwork(tgt)
		return
	if action == "parry_deflect":
		if atk != null:
			var pa_deflect: Dictionary = _pending_attack_read(atk)
			atk["last_move_id"] = pa_deflect.get("attack_type", "")
			atk["effective_attack_line"] = pa_deflect.get("effective_attack_line", "")
			# HEMA: store defender's guard and parry_clash_context for bind vs deflect.
			atk["defender_guard_line_at_parry"] = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if tgt != null else ""
			var atk_clash_raw: Variant = result.get("parry_clash_context", null)
			atk["parry_clash_context"] = atk_clash_raw if atk_clash_raw is Dictionary else {}
			_clear_attacker_pending_attack(atk, manager)
			atk["recovery_cause"] = "attack_deflect"
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
		if tgt != null:
			_consume_stamina(tgt, CombatConstants.STAMINA_PARRY_COST)
			# Weapon position: defender's blade met attacker's; blade ends in attack line.
			# Use effective_attack_line for diagonal moves (actual contact line).
			var move_id: String = atk.get("last_move_id", "") if atk != null else ""
			var eff_line: String = atk.get("effective_attack_line", "") if atk != null else ""
			_GuardUpdater.set_guard_from_move(tgt, move_id, eff_line)
			tgt["parry_bonus_until"] = CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
			_CounterTempo.grant_riposte_chain(manager, tgt, attacker_id)
			var clash_raw: Variant = result.get("parry_clash_context", null)
			var clash: Dictionary = clash_raw if clash_raw is Dictionary else {}
			var arch_id: String = clash.get("archetype_id", "")
			var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
			tgt["parry_was_bind"] = can_bind and clash.get("parry_control", 0.0) >= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
			tgt["parry_against_id"] = attacker_id
			_defender_set_idle_after_parry(tgt)
		empty_result["outcome"] = "parry_deflect"
		var clash_emit: Variant = result.get("parry_clash_context", null)
		if clash_emit is Dictionary:
			empty_result["parry_clash_context"] = clash_emit
		_log_outcome("parry_deflect", attacker_id, target_id)
		if atk != null:
			_AIPicker.record_opp_parry_deflect_for_feint_listing(manager, atk, target_id)
		if tgt != null:
			_Attention.record_parry_deflect_on_attacker_memory(tgt, attacker_id)
		_clear_defender_footwork(tgt)
		manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
		return
	if action == "parry_partial":
		if atk != null:
			var partial_clash_raw: Variant = result.get("parry_clash_context", null)
			atk["parry_clash_context"] = partial_clash_raw if partial_clash_raw is Dictionary else {}
			atk["defender_guard_line_at_parry"] = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if tgt != null else ""
		if tgt != null:
			_consume_stamina(tgt, CombatConstants.STAMINA_PARRY_COST)
			# Weapon position: only update when alignment was good (blade properly met attack).
			# Use effective_attack_line for diagonal moves (actual contact line).
			var pa_partial: Dictionary = _pending_attack_read(atk) if atk != null else {}
			var move_id: String = pa_partial.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id)
			var atk_line: String = pa_partial.get("effective_attack_line", move_def.get("attack_line", "high"))
			var align_ctx: Dictionary = {}
			if pa_partial.get("attack_angle_deg", -999.0) >= 0.0:
				var read: float = _PassiveParry.get_passive_parry_readiness(tgt)
				var def_w = _EntityAccess.get_weapon(tgt)
				var def_mass_partial: float = float(def_w.mass) if def_w != null and (def_w.get("mass") is float or def_w.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
				var wob: Dictionary = {"parry_readiness": read, "defender_mass_kg": def_mass_partial}
				align_ctx = {
					"attack_angle_deg": pa_partial["attack_angle_deg"],
					"guard_angle_deg": _Footwork.guard_angle_deg(tgt, wob),
				}
			var align: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
			if align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
				_GuardUpdater.set_guard_from_move(tgt, move_id, atk_line)
				var pcl_bind: Variant = result.get("parry_clash_context", null)
				var clash_bind: Dictionary = pcl_bind if pcl_bind is Dictionary else {}
				var arch_bind: String = clash_bind.get("archetype_id", "")
				var can_bind_partial: bool = (
					arch_bind.is_empty() or arch_bind not in CombatConstants.ARCHETYPES_NEVER_BIND
				)
				var is_bind: bool = (
					can_bind_partial
					and float(clash_bind.get("parry_control", 0.0))
					>= CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
				)
				tgt["parry_was_bind"] = is_bind
				if is_bind:
					tgt["parry_against_id"] = attacker_id
					tgt["parry_bonus_until"] = (
						CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
					)
				else:
					tgt.erase("parry_against_id")
					tgt.erase("parry_bonus_until")
			else:
				tgt.erase("parry_was_bind")
				tgt.erase("parry_against_id")
				tgt.erase("parry_bonus_until")
			_defender_set_idle_after_parry(tgt)
		var partial_emit: Dictionary = {"outcome": "parry_partial", "dmg": 0, "died": false}
		var pcl_emit: Variant = result.get("parry_clash_context", null)
		if pcl_emit is Dictionary:
			partial_emit["parry_clash_context"] = pcl_emit
		_log_outcome("parry_partial", attacker_id, target_id)
		manager.emit_signal("action_resolved", target_id, attacker_id, partial_emit)
		manager._execute_attack(attacker_id)
		return
	if action == "hit":
		# Follow-through after **`parry_partial`**: strip calibration carry so **`attack_hit`** recovery does not see stale clash dict.
		if atk != null:
			atk.erase("parry_clash_context")
			atk.erase("defender_guard_line_at_parry")
			_AIPicker.clear_feint_listing_opp_parry_deflect_for_target(atk, target_id)
		if tgt != null:
			_Attention.clear_yomi_for_attacker(tgt, attacker_id)
		var rd_raw: Variant = result.get("result_dict", null)
		var result_dict: Dictionary = rd_raw if rd_raw is Dictionary else {}
		var intensity: float = result.get("intensity", 0.5)
		var winner: String = ""
		if result_dict.get("died", false):
			_abort_incoming_wind_up_if_target_died(manager, target_id)
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			winner = manager._check_for_winner()
			if not winner.is_empty():
				manager._end_combat_phase(winner, tgt_scene)
			# Attacker still needs recovery (killing blow); otherwise they stay in WIND_UP and never get another turn.
			if atk != null and _EntityAccess.alive_bool(atk):
				_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
				atk["effective_attack_line"] = atk.get("effective_attack_line", "")
				atk["recovery_cause"] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get("recovery_duration", 0.5)
			return
		winner = manager._check_for_winner()
		if not winner.is_empty():
			if tgt != null and tgt_scene != null and tgt_scene.has_method("is_incapacitated") and tgt_scene.is_incapacitated():
				var reason: String = "consciousness < 10%%"
				if tgt_scene.has_method("is_cowering") and tgt_scene.is_cowering():
					reason = "cowering (no functional arms)"
				print("[Combat] INCAPACITATED: %s (%s)" % [_EntityAccess.get_display_name(tgt, target_id), reason])
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			# Attacker still needs recovery; otherwise they stay in WIND_UP
			if atk != null and _EntityAccess.alive_bool(atk):
				_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
				atk["effective_attack_line"] = atk.get("effective_attack_line", "")
				atk["recovery_cause"] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get("recovery_duration", 0.5)
			manager._end_combat_phase(winner, tgt_scene)
			return
		_Afterblow.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
		# last_move_id set in AttackResolver before clearing pending_attack
		_log_outcome("hit", attacker_id, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
		if atk != null and _EntityAccess.alive_bool(atk):
			_consume_stamina(atk, CombatConstants.STAMINA_ATTACK_COST_BASE)
			atk["effective_attack_line"] = atk.get("effective_attack_line", "")  # Set in AttackResolver before clear
			atk["recovery_cause"] = "attack_hit"
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		if tgt != null and _EntityAccess.alive_bool(tgt):
			# Defender was hit; stagger/dropped guard — blade ends low. Sync guard_zone.
			_GuardUpdater.set_guard_from_line(tgt, "low")
			if manager.has_method("apply_formation_hit_reaction_if_needed"):
				manager.apply_formation_hit_reaction_if_needed(target_id, intensity)
		_clear_defender_footwork(tgt)
		return
