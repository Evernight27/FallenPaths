class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## Footing: **`GuardLineUpdater`** on hit stagger (**`low`**), dodge guard, move finish — L3 drift; **`CombatFootwork.clear_on_exchange_end`** on exchange end. LIVE_PATHS **`#wf-guard-writers`** · **`#wf-tier-44-pa`** (clear).
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
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _LogFormatter := preload("res://ui/CombatLogFormatter.gd")

static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
	if CombatConstants.combat_debug_active():
		CombatDebug.log("outcome %s atk=%d tgt=%d" % [action, atk_id, tgt_id])


## F5 soak (**II-2b**): grep `parry_deflect` / `parry_bind` / `parry_partial` without **`COMBAT_DEBUG`**.
static func _log_fp_parry_outcome(
	atk: Dictionary,
	tgt: Dictionary,
	atk_id: int,
	tgt_id: int,
	outcome: String,
	clash: Dictionary
) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var atk_n: String = _EntityAccess.get_display_name(atk, atk_id)
	var tgt_n: String = _EntityAccess.get_display_name(tgt, tgt_id)
	var ctrl: float = float(clash.get("parry_control", 0.0))
	var reason: String = _LogFormatter.damage_resolve_note({"outcome": outcome})
	var interpose_suffix: String = ""
	var interpose_boost: float = float(clash.get("arm_interpose_boost", 0.0))
	if interpose_boost > 0.0:
		interpose_suffix = " arm_interpose_arm=%s arm_interpose_boost=%.3f" % [
			str(clash.get("arm_interpose_arm", "")),
			interpose_boost,
		]
	if outcome == "parry_deflect":
		var tag: String = "parry_bind" if bool(tgt.get("parry_was_bind", false)) else "parry_deflect"
		CombatDebug.combat_session(
			"%s %s vs %s ctrl=%.2f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, reason, interpose_suffix]
		)
	elif outcome == "parry_partial":
		var rem: float = float(clash.get("remaining_ratio", clash.get("geometric_leak", 0.0)))
		var bind: bool = bool(tgt.get("parry_was_bind", false))
		var tag: String = "parry_bind" if bind else "parry_partial"
		CombatDebug.combat_session(
			"%s %s vs %s ctrl=%.2f rem=%.2f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, rem, reason, interpose_suffix]
		)

static func _consume_stamina(manager: Node, c: Dictionary, amount: float) -> void:
	if c == null:
		return
	var s: float = _EntityAccess.stamina_float(c)
	c["stamina"] = maxf(0.0, s - amount)
	_Exhaustion.apply_exertion_from_stamina_spend(manager, c, amount)


static func _stamina_parry_cost_for_defender(atk: Dictionary, incoming_intensity: float = -1.0) -> float:
	var i: float = incoming_intensity
	if i < 0.0:
		i = 0.5
		if not atk.is_empty():
			i = float(_pending_attack_read(atk).get("intensity", 0.5))
	return CombatConstants.stamina_parry_cost_from_intensity(i)


static func _stamina_attack_cost_for_attacker(
	manager: Node, atk: Dictionary, target_id: int
) -> float:
	if atk.is_empty():
		return CombatConstants.stamina_attack_cost_from_intensity(1.0)
	var cost: float = CombatConstants.stamina_attack_cost_from_intensity(
		float(_pending_attack_read(atk).get("intensity", 1.0))
	)
	if manager != null and target_id >= 0:
		var clk: float = _EntityAccess.combat_clock_float(manager)
		cost *= _FlurryBind.stamina_attack_cost_mult(atk, target_id, clk)
	return cost


static func _pending_attack_read(atk: Dictionary) -> Dictionary:
	return _EntityAccess.nested_dictionary_read(atk, "pending_attack")


static func _clear_attacker_pending_attack(atk: Dictionary, manager: Node) -> void:
	if atk.is_empty():
		return
	var pa0: Dictionary = _pending_attack_read(atk)
	_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa0)
	_Footwork.clear_on_exchange_end(atk)
	atk.pending_attack = {}


static func _react_attacking_arm_loss_after_wound(manager: Node, c: Variant) -> void:
	if manager == null or c == null or not (c is Dictionary):
		return
	var cd: Dictionary = c as Dictionary
	if cd.is_empty():
		return
	_EntityAccess.react_attacking_arm_lost_if_needed(manager, cd)


static func _clear_defender_footwork(tgt: Dictionary) -> void:
	if not tgt.is_empty():
		_Footwork.clear_on_exchange_end(tgt)


static func _abort_incoming_wind_up_if_target_died(manager: Node, target_id: int) -> void:
	if manager == null or target_id < 0:
		return
	var tgt: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or _EntityAccess.alive_bool(tgt):
		return
	_CounterTempo.abort_attacker_wind_up(manager, target_id)


## Parry outcomes default the defender to waiting. Paired formation moves (`swap_rank` / drag / fall_back_pair)
## keep both partners in motion state until resolve — do not clobber that here.
static func _defender_set_idle_after_parry(tgt: Dictionary) -> void:
	if tgt.is_empty():
		return
	if _EntityAccess.state_str(tgt) in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK]:
		return
	_clear_defender_footwork(tgt)
	_Footwork.return_to_waiting(tgt)
	tgt.state_timer = 0.0
	tgt.state_duration = 0.0


static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
	var action: String = result.get("action", "skip")
	var target_id: int = result.get("target_id", -1)
	var atk: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if _MedicalPhase.combat_resolution_blocked(manager):
		return
	var tgt: Dictionary = _EntityAccess.manager_get_combatant_optional(manager, target_id)
	var tgt_scene: Node = _EntityAccess.scene_node(tgt)
	var empty_result: Dictionary = {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0}

	if action == "skip":
		if not atk.is_empty():
			if result.get("recovery_duration", 0.0) > 0.0:
				empty_result["outcome"] = "skip"
				manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
				var pa_skip: Dictionary = _pending_attack_read(atk)
				atk["last_move_id"] = pa_skip.get("attack_type", "")
				atk["effective_attack_line"] = pa_skip.get("effective_attack_line", "")
				atk["recovery_cause"] = "skip"
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.recovery_duration
				_clear_attacker_pending_attack(atk, manager)
				_react_attacking_arm_loss_after_wound(manager, atk)
			else:
				_Footwork.return_to_waiting(atk)
				atk.gauge = 0.0
				_clear_attacker_pending_attack(atk, manager)
				_react_attacking_arm_loss_after_wound(manager, atk)
		return
	if action == "defeated":
		if not tgt.is_empty():
			tgt.alive = false
			_Footwork.clear_on_death(tgt)
			tgt.state = CombatConstants.STATE_DEAD
			_StateHandlers.cancel_events_for_dead_combatant(manager, tgt)
		if not atk.is_empty():
			# Resolver abort (e.g. no targetable parts): do not leave attacker stuck in WIND_UP with stale `pending_attack`.
			_clear_attacker_pending_attack(atk, manager)
			_Footwork.return_to_waiting(atk)
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
		var pa_miss_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
		if not tgt.is_empty() and not pa_miss_log.is_empty():
			_record_resolved_exchange_yomi(tgt, attacker_id, pa_miss_log, true)
		var miss_part: String = str(pa_miss_log.get("target_part", ""))
		if not miss_part.is_empty():
			empty_result["part"] = miss_part
		_F5SoakTrace.note_strike_avoided(
			attacker_id,
			target_id,
			atk,
			tgt,
			"miss",
			miss_part
		)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if not atk.is_empty():
			var pa_miss: Dictionary = _pending_attack_read(atk)
			atk["last_move_id"] = pa_miss.get("attack_type", "")
			atk["effective_attack_line"] = pa_miss.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
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
		var pa_dodge_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
		if not tgt.is_empty() and not pa_dodge_log.is_empty():
			_record_resolved_exchange_yomi(tgt, attacker_id, pa_dodge_log, true)
		var dodge_part: String = str(
			pa_dodge_log.get("partial_dodge_part", pa_dodge_log.get("target_part", ""))
		)
		if not dodge_part.is_empty():
			empty_result["part"] = dodge_part
		_F5SoakTrace.note_strike_avoided(
			attacker_id,
			target_id,
			atk,
			tgt,
			"dodge",
			dodge_part
		)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		if not atk.is_empty():
			var pa_dodge_atk: Dictionary = _pending_attack_read(atk)
			atk["last_move_id"] = pa_dodge_atk.get("attack_type", "")
			atk["effective_attack_line"] = pa_dodge_atk.get("effective_attack_line", "")
			atk["recovery_cause"] = "attack_miss"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		if not tgt.is_empty():
			# Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
			# Use effective_attack_line for diagonal moves (actual trajectory).
			var pa: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
			var move_id: String = pa.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
			var atk_line: String = pa.get("effective_attack_line", move_def.get("attack_line", "high"))
			var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(atk_line, tgt.get("guard_line", CombatConstants.GUARD_DEFAULT))
			_GuardUpdater.set_guard_from_line(tgt, dodge_guard)
			if CombatConstants.combat_debug_active():
				CombatDebug.log("guard_line %s: -> %s (dodged %s)" % ["id:%d" % _EntityAccess.id_int(tgt), dodge_guard, atk_line])
		if not atk.is_empty():
			_clear_attacker_pending_attack(atk, manager)
		_clear_defender_footwork(tgt)
		return
	if action == "parry_deflect":
		var incoming_parry_intensity: float = 0.5
		if not atk.is_empty():
			var pa_deflect: Dictionary = _pending_attack_read(atk)
			if not tgt.is_empty() and not pa_deflect.is_empty():
				_record_resolved_exchange_yomi(tgt, attacker_id, pa_deflect, true)
			incoming_parry_intensity = float(pa_deflect.get("intensity", 0.5))
			atk["last_move_id"] = pa_deflect.get("attack_type", "")
			atk["effective_attack_line"] = pa_deflect.get("effective_attack_line", "")
			# HEMA: store defender's guard and parry_clash_context for bind vs deflect.
			atk["defender_guard_line_at_parry"] = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if not tgt.is_empty() else ""
			var atk_clash_raw: Variant = result.get("parry_clash_context", null)
			atk["parry_clash_context"] = atk_clash_raw if atk_clash_raw is Dictionary else {}
			_clear_attacker_pending_attack(atk, manager)
			atk["recovery_cause"] = "attack_deflect"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = CombatTiming.now_seconds() + CombatConstants.OFF_BALANCE_DURATION_S
		if not tgt.is_empty():
			_consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_parry_intensity))
			# Weapon position: defender's blade met attacker's; blade ends in attack line.
			# Use effective_attack_line for diagonal moves (actual contact line).
			var move_id: String = atk.get("last_move_id", "") if not atk.is_empty() else ""
			var eff_line: String = atk.get("effective_attack_line", "") if not atk.is_empty() else ""
			_GuardUpdater.set_guard_from_move(tgt, move_id, eff_line)
			tgt["parry_bonus_until"] = CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
			if not _MobilityRetreat.cannot_commit_melee(tgt):
				_CounterTempo.grant_riposte_chain(manager, tgt, attacker_id)
				var clash_raw: Variant = result.get("parry_clash_context", null)
				var clash: Dictionary = clash_raw if clash_raw is Dictionary else {}
				var arch_id: String = clash.get("archetype_id", "")
				var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
				tgt["parry_was_bind"] = (
					can_bind
					and CombatConstants.parry_bind_control_reached(float(clash.get("parry_control", 0.0)))
				)
				tgt["parry_against_id"] = attacker_id
				if bool(tgt.get("parry_was_bind", false)):
					CombatConstants.apply_parry_bind_riposte_gauge_bonus(tgt)
					_FlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
			else:
				tgt.erase("parry_was_bind")
				tgt.erase("parry_against_id")
				_CounterTempo.clear_riposte_chain(tgt)
			_defender_set_idle_after_parry(tgt)
		empty_result["outcome"] = "parry_deflect"
		var clash_emit: Variant = result.get("parry_clash_context", null)
		if clash_emit is Dictionary:
			empty_result["parry_clash_context"] = clash_emit
		_log_outcome("parry_deflect", attacker_id, target_id)
		var clash_log: Dictionary = (
			result.get("parry_clash_context", {}) if result.get("parry_clash_context") is Dictionary else {}
		)
		_log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_deflect", clash_log)
		if not atk.is_empty():
			_AIPicker.record_opp_parry_deflect_for_feint_listing(manager, atk, target_id)
		if not tgt.is_empty():
			_Attention.record_parry_deflect_on_attacker_memory(tgt, attacker_id)
		manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
		return
	if action == "parry_partial":
		var incoming_partial_intensity: float = 0.5
		if not atk.is_empty():
			var pa_partial_int: Dictionary = _pending_attack_read(atk)
			incoming_partial_intensity = float(pa_partial_int.get("intensity", 0.5))
			var partial_clash_raw: Variant = result.get("parry_clash_context", null)
			atk["parry_clash_context"] = partial_clash_raw if partial_clash_raw is Dictionary else {}
			atk["defender_guard_line_at_parry"] = tgt.get("guard_line", CombatConstants.GUARD_DEFAULT) if not tgt.is_empty() else ""
		if not tgt.is_empty():
			_consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_partial_intensity))
			# Weapon position: only update when alignment was good (blade properly met attack).
			# Use effective_attack_line for diagonal moves (actual contact line).
			var pa_partial: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
			if not pa_partial.is_empty():
				_record_resolved_exchange_yomi(tgt, attacker_id, pa_partial, true)
			var move_id: String = pa_partial.get("attack_type", "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id)
			var atk_line: String = pa_partial.get("effective_attack_line", move_def.get("attack_line", "high"))
			var align_ctx: Dictionary = {}
			if pa_partial.get("attack_angle_deg", -999.0) >= 0.0:
				var read: float = _PassiveParry.get_passive_parry_readiness(tgt)
				var def_w = _EntityAccess.get_weapon(tgt)
				var wob: Dictionary = _EntityAccess.parry_wobble_context(def_w, read)
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
					and CombatConstants.parry_bind_control_reached(float(clash_bind.get("parry_control", 0.0)))
				)
				tgt["parry_was_bind"] = is_bind
				if is_bind:
					tgt["parry_against_id"] = attacker_id
					tgt["parry_bonus_until"] = (
						CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
					)
					_FlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
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
		var clash_partial: Dictionary = pcl_emit if pcl_emit is Dictionary else {}
		_log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_partial", clash_partial)
		manager.emit_signal("action_resolved", target_id, attacker_id, partial_emit)
		manager._execute_attack(attacker_id)
		return
	if action == "hit":
		_FlurryBind.clear_pair(manager, attacker_id, target_id)
		# Follow-through after **`parry_partial`**: strip calibration carry so **`attack_hit`** recovery does not see stale clash dict.
		if not atk.is_empty():
			atk.erase("parry_clash_context")
			atk.erase("defender_guard_line_at_parry")
			_AIPicker.clear_feint_listing_opp_parry_deflect_for_target(atk, target_id)
		if not tgt.is_empty():
			_Attention.clear_yomi_for_attacker(tgt, attacker_id)
		var rd_raw: Variant = result.get("result_dict", null)
		var result_dict: Dictionary = rd_raw if rd_raw is Dictionary else {}
		var intensity: float = result.get("intensity", 0.5)
		var winner: String = ""
		if result_dict.get("died", false):
			_abort_incoming_wind_up_if_target_died(manager, target_id)
			_F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			winner = manager._check_for_winner()
			if not winner.is_empty():
				manager._end_combat_phase(winner, tgt_scene)
			# Attacker still needs recovery (killing blow); otherwise they stay in WIND_UP and never get another turn.
			if atk != null and _EntityAccess.alive_bool(atk):
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk["effective_attack_line"] = atk.get("effective_attack_line", "")
				atk["recovery_cause"] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get("recovery_duration", 0.5)
				_set_post_strike_stamp(manager, atk, attacker_id, target_id)
			return
		winner = manager._check_for_winner()
		if not winner.is_empty():
			if tgt != null and _EntityAccess.is_incapacitated(tgt):
				var reason: String = "consciousness < 10%%"
				if _EntityAccess.is_cowering(tgt):
					reason = "cowering (no functional arms)"
				if not (
					_OperationalLog.is_play_session_active()
					and CombatConstants.combat_hit_summary_active()
				):
					CombatDebug.combat_session(
						"INCAPACITATED %s (%s)" % [_EntityAccess.get_display_name(tgt, target_id), reason]
					)
			_F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			# Attacker still needs recovery; otherwise they stay in WIND_UP
			if atk != null and _EntityAccess.alive_bool(atk):
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk["effective_attack_line"] = atk.get("effective_attack_line", "")
				atk["recovery_cause"] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get("recovery_duration", 0.5)
				_set_post_strike_stamp(manager, atk, attacker_id, target_id)
			manager._end_combat_phase(winner, tgt_scene)
			return
		if not _MedicalPhase.combat_resolution_blocked(manager):
			_Afterblow.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
		# last_move_id set in AttackResolver before clearing pending_attack
		_log_outcome("hit", attacker_id, target_id)
		_F5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
		manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
		if atk != null and _EntityAccess.alive_bool(atk):
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk["effective_attack_line"] = atk.get("effective_attack_line", "")  # Set in AttackResolver before clear
			atk["recovery_cause"] = "attack_hit"
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			_set_post_strike_stamp(manager, atk, attacker_id, target_id)
		if tgt != null and _EntityAccess.alive_bool(tgt):
			# Defender was hit; stagger/dropped guard — blade ends low. Sync guard_zone.
			_GuardUpdater.set_guard_from_line(tgt, "low")
			_EntityAccess.manager_apply_formation_hit_reaction_if_needed(manager, target_id, intensity)
		_react_attacking_arm_loss_after_wound(manager, atk)
		_react_attacking_arm_loss_after_wound(manager, tgt)
		_clear_defender_footwork(tgt)
		return


## WF-2a: tally resolved move id (+ feint withdrawal) on defender yomi without duplicating wind-up line counts.
static func _record_resolved_exchange_yomi(
	defender: Dictionary, attacker_id: int, pa: Dictionary, count_feint_if_feint: bool
) -> void:
	if defender.is_empty() or pa.is_empty() or attacker_id < 0:
		return
	var move_id: String = str(pa.get("attack_type", "")).strip_edges()
	if not move_id.is_empty():
		_Attention.record_resolved_strike_toward_defender(defender, attacker_id, move_id)
	if count_feint_if_feint and not move_id.is_empty():
		var md: Dictionary = WeaponConstants.get_move(move_id)
		if md.get("is_feint", false) or WeaponConstants.is_feint_move(move_id):
			_Attention.record_feint_resolved_toward_defender(defender, attacker_id)


## MS-L8: stamp the attacker's dict with the combat clock so MS-L8 post-strike momentum fires next turn.
static func _set_post_strike_stamp(manager: Node, atk: Dictionary, attacker_id: int, struck_target_id: int = -1) -> void:
	if not CombatConstants.is_feature_ms_post_strike_enabled():
		return
	if atk.is_empty() or manager == null:
		return
	var atk_read: Dictionary = _EntityAccess.manager_get_combatant(manager, attacker_id)
	if not atk_read.is_empty():
		atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
		if struck_target_id >= 0:
			atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = struck_target_id
