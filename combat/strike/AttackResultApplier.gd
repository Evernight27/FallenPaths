class_name AttackResultApplier
extends RefCounted

## Applies AttackResolver result to combatant state: skip, defeated, miss, dodge, parry_deflect, parry_partial, hit.
## Footing: **`GuardLineUpdater`** on hit stagger (**`low`**), dodge guard, move finish - L3 drift;
## **`CombatFootwork.clear_on_exchange_end`** on exchange end. LIVE_PATHS **`#wf-guard-writers`** - **`#wf-tier-44-pa`**
## (clear).
## **`parry_deflect`**: records **`CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK`** on
## **`attacker`** for Tier **4.2** feint listing pressure vs **`target_id`**; **`action_resolved`** emits
## **`target_id`**, **`attacker_id`**, then payload ( **`parry_clash_context`** copied when resolver supplied a dict -
## **`BattleScene`** parameter names follow slot order).
## **`parry_partial`**: **`action_resolved`** emits **`target_id`**, **`attacker_id`**, then payload (**defender**,
## **attacker**, same slot order as **`parry_deflect`**); then **`_execute_attack`** continues the strike. Resolver
## **`parry_clash_context`** is copied onto the **attacker** dict and onto the emitted payload when present. When the
## defender meets the same blade-alignment gate used for guard updates and clash **`parry_control`** crosses the bind
## threshold (**`PARRY_BIND_CONTROL_THRESHOLD`**), set **`parry_was_bind`**, **`parry_against_id`**,
## **`parry_bonus_until`** on the defender like **`parry_deflect`** so bind-riposte wind-up can apply; the bind also
## grants the riposte counterstrike window (**`CounterTempo.grant_riposte_chain`**, `FEATURE_PARRY_COUNTERSTRIKE_WINDOW`)
## like a full deflect; aligned but
## sub-threshold control sets **`parry_was_bind`** false; misaligned partial **`erase`**s those keys (clears stale bind
## state).
## Manager must have: emit_signal, _get_by_id, _check_for_winner, _end_combat_phase, _execute_attack.
## **`hit`**: clears **`parry_clash_context`** / **`defender_guard_line_at_parry`** / **`defender_form_at_parry`** on the attacker (stale partial-parry
## calibration after follow-through); clears Tier **4.2** feint listing parry-deflect memory for **`target_id`**.


static func _log_outcome(action: String, atk_id: int, tgt_id: int) -> void:
	if CombatConstants.combat_debug_active():
		CombatDebug.log("%s atk=%d tgt=%d" % [action, atk_id, tgt_id])


## F5 soak (**II-2b**): grep `parry_deflect` / `parry_bind` / `parry_partial` without **`COMBAT_DEBUG`**.
static func _log_fp_parry_outcome(
	atk: Dictionary, tgt: Dictionary, atk_id: int, tgt_id: int, outcome: String, clash: Dictionary
) -> void:
	if not OperationalLog.is_play_session_active():
		return
	var atk_n: String = CombatantEntityAccess.get_display_name(atk, atk_id)
	var tgt_n: String = CombatantEntityAccess.get_display_name(tgt, tgt_id)
	var ctrl: float = clash.get(DataKeys.RESULT_PARRY_CONTROL, 0.0)
	var reason: String = CombatLogFormatter.damage_resolve_note({"outcome": outcome})
	var interpose_suffix: String = ""
	var interpose_boost: float = clash.get(DataKeys.RESULT_ARM_INTERPOSE_BOOST, 0.0)
	if interpose_boost > 0.0:
		interpose_suffix = (
            " arm_interpose_arm=%s arm_interpose_boost=%.3f"
			% [
				clash.get(DataKeys.RESULT_ARM_INTERPOSE_ARM, ""),
				interpose_boost,
			]
		)
	# This F5-soak tracer is the authoritative applier record and the ONLY source of the
	# `parry_deflect`/`parry_bind`/`parry_partial` tokens that feed the soak's `parry_stats` counter.
	# Emit during a real play session so parry coverage is never silently zero (matches the UI parry
	# detail gate in CombatLogFormatter), or under the calibration trace. Headless harness (quiet) and
	# non-play runs keep it suppressed to stay dense.
	if not (CombatConstants.play_session_diagnostic_active() or CombatDebug.dc_trace_active()):
		return
	if outcome == "parry_deflect":
		var tag: String = "parry_bind" if tgt.get(DataKeys.PA_PARRY_WAS_BIND, false) else "parry_deflect"
		CombatDebug.combat_session(
			"%s %s vs %s ctrl=%.3f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, reason, interpose_suffix]
		)
		if OperationalLog.is_play_session_active():
			OperationalLog.play_combat("%s %s vs %s ctrl=%.3f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, reason, interpose_suffix])
	elif outcome == "parry_partial":
		var rem: float = 0.0
		if clash.has(DataKeys.RESULT_REMAINING_RATIO):
			rem = float(clash[DataKeys.RESULT_REMAINING_RATIO])
		var bind: bool = tgt.get(DataKeys.PA_PARRY_WAS_BIND, false)
		var tag: String = "parry_bind" if bind else "parry_partial"
		CombatDebug.combat_session(
			(
                "%s %s vs %s ctrl=%.3f remaining_ratio=%.2f reason=%s%s"
				% [tag, tgt_n, atk_n, ctrl, rem, reason, interpose_suffix]
			)
		)
		if OperationalLog.is_play_session_active():
			OperationalLog.play_combat("%s %s vs %s ctrl=%.3f remaining_ratio=%.2f reason=%s%s" % [tag, tgt_n, atk_n, ctrl, rem, reason, interpose_suffix])


static func _consume_stamina(manager: Node, c: Dictionary, amount: float) -> void:
	if c == null:
		return
	var s: float = CombatantEntityAccess.stamina_float(c)
	c[DataKeys.COMBATANT_STAMINA] = maxf(0.0, s - amount)
	CombatExhaustion.apply_exertion_from_stamina_spend(manager, c, amount)


## Stance stamina cost: a braced defensive stance absorbs actions cheaper; a committed aggressive
## stance costs more per action. Reads the combatant's live weapon form (WF) — distinct from the
## consecutive/flurry multipliers already applied by callers.
static func _form_stamina_cost_mult(c: Dictionary) -> float:
	if c.is_empty():
		return 1.0
	return CombatWeaponForm.stamina_cost_mult(
		CombatantEntityAccess.form_str(c), CombatantEntityAccess.get_weapon(c)
	)


static func _stamina_parry_cost_for_defender(atk: Dictionary, incoming_intensity: float = -1.0, consecutive_parry_count: int = 1, def: Dictionary = {}) -> float:
	var i: float = incoming_intensity
	if i < 0.0:
		i = 0.5
		if not atk.is_empty():
			i = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
	var base_cost: float = CombatConstants.stamina_parry_cost_from_intensity(i)
	# Consecutive parry fatigue: repeated parrying without full recovery compounds stamina drain.
	if consecutive_parry_count > 1:
		base_cost *= CombatConstants.consecutive_parry_stamina_mult(consecutive_parry_count)
	base_cost *= _form_stamina_cost_mult(def)
	return base_cost

static func _stamina_dodge_cost_for_defender(atk: Dictionary, intensity: float = -1.0, def: Dictionary = {}) -> float:
	var i: float = intensity
	if i < 0.0:
		i = 0.5
		if not atk.is_empty():
			i = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
	return CombatConstants.stamina_dodge_cost_from_intensity(i) * _form_stamina_cost_mult(def)


static func _stamina_attack_cost_for_attacker(manager: Node, atk: Dictionary, target_id: int) -> float:
	if atk.is_empty():
		return CombatConstants.stamina_attack_cost_from_intensity(1.0)
	var cost: float = CombatConstants.stamina_attack_cost_from_intensity(
		_pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 1.0)
	)
	if manager != null and target_id >= 0:
		var clk: float = CombatantEntityAccess.combat_clock_float(manager)
		cost *= CombatFlurryBind.stamina_attack_cost_mult(atk, target_id, clk)
	cost *= _consecutive_action_stamina_mult_for_combatant(atk)
	cost *= _form_stamina_cost_mult(atk)
	# Technique economy (TOPIC 8c): a green fighter spends more metabolic energy (and accrues more exhaustion)
	# per nominal-intensity swing than a veteran would. Untracked fighters / sim-off return economy 1.0.
	var swing_tier: float = EntityProficiency.swing_proficiency_tier(
		CombatantEntityAccess.scene_entity(atk),
		CombatantEntityAccess.weapon_type_id(atk),
		CombatantEntityAccess.form_str(atk)
	)
	cost *= EntityProficiency.swing_stamina_economy(swing_tier)
	# Sepsis (CAMP-INF-1): a septic member burns stamina faster per action (tachycardia/shock).
	var atk_scene: Node = CombatantEntityAccess.scene_entity(atk)
	if atk_scene != null and "is_septic" in atk_scene and bool(atk_scene.get("is_septic")):
		cost *= BleedingConstants.SEPSIS_COMBAT_STAMINA_DRAIN_MULT
	return cost


static func _consecutive_action_stamina_mult_for_combatant(c: Dictionary) -> float:
	var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0)
	return CombatConstantsStamina.consecutive_action_stamina_mult(count)


static func _track_consecutive_action_start(c: Dictionary) -> void:
	if c.is_empty():
		return
	var state: String = c.get(DataKeys.COMBATANT_STATE, "")
	if state == CombatConstants.STATE_RECOVERING:
		c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = 1
		return
	var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0) + 1
	c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = count


static func _track_consecutive_parry_for_defender(tgt: Dictionary, manager: Node = null) -> int:
	if tgt.is_empty():
		return 1
	var state: String = tgt.get(DataKeys.COMBATANT_STATE, "")
	# If defender is in recovery, parry streak resets.
	if state == CombatConstants.STATE_RECOVERING:
		tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = 1
		_stamp_last_parry_clock(tgt, manager)
		return 1
	# HEMA: parry fatigue decays with rest. If the gap since the last parry exceeds the reset window,
	# the defender has recovered enough that the streak resets — the fatigue compounds only for
	# back-to-back parries, not for parries separated by a long rest.
	var count: int = 1
	if manager != null:
		var now: float = CombatantEntityAccess.combat_clock_float(manager)
		var last: float = float(tgt.get(DataKeys.PA_LAST_PARRY_CLOCK, -1.0))
		if last >= 0.0 and (now - last) <= CombatConstants.PARRY_FATIGUE_RESET_S:
			count = int(tgt.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES, 0)) + 1
	tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = count
	_stamp_last_parry_clock(tgt, manager)
	return count


static func _stamp_last_parry_clock(tgt: Dictionary, manager: Node) -> void:
	if tgt.is_empty() or manager == null:
		return
	tgt[DataKeys.PA_LAST_PARRY_CLOCK] = CombatantEntityAccess.combat_clock_float(manager)


static func _pending_attack_read(atk: Dictionary) -> Dictionary:
	return CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")


static func _tuning_follow_through_extras(atk: Dictionary) -> Dictionary:
	if atk.is_empty() or not atk.has(DataKeys.PA_TUNING_FT_PARENT_STRIKE):
		return {}
	return {
		"parent_exchange_index": int(atk[DataKeys.PA_TUNING_FT_PARENT_STRIKE]),
		"note": "follow_through_from_parry",
	}


static func _clear_tuning_follow_through_marker(atk: Dictionary) -> void:
	if not atk.is_empty():
		atk.erase(DataKeys.PA_TUNING_FT_PARENT_STRIKE)


static func _tuning_parry_parent_strike_index(manager: Node) -> int:
	if manager == null:
		return -1
	return int(manager.get_meta("tuning_strike_count", 0)) + 1


static func _hit_tuning_extras(
	atk: Dictionary, intensity: float, recovery_duration: float, ft_extras: Dictionary
) -> Dictionary:
	var extras: Dictionary = {
		"intensity": intensity,
		"recovery_s": recovery_duration,
		"move_id": atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")) if not atk.is_empty() else "",
		"attack_line": atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else "",
	}
	extras.merge(ft_extras)
	return extras


static func _tuning_context_enabled(manager: Node) -> bool:
	return manager != null and bool(manager.get_meta("tuning_expose_strike_context", false))


## Tuning scene: stamp wind-up / guard / parry context on `action_resolved` payloads.
static func _enrich_payload_for_tuning(
	manager: Node, payload: Dictionary, atk: Dictionary, tgt: Dictionary, pa: Dictionary, extras: Dictionary = {}
) -> void:
	if not _tuning_context_enabled(manager):
		return
	if not pa.is_empty():
		payload[DataKeys.RESULT_MOVE_ID] = str(pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
		payload[DataKeys.ATTACK_INTENSITY] = float(pa.get(DataKeys.ATTACK_INTENSITY, 0.0))
		payload[DataKeys.RESULT_POWER] = float(pa.get(DataKeys.ATTACK_POWER, 0.0))
		payload[DataKeys.RESULT_FOLLOW_THROUGH] = float(pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, 0.0))
		payload["wind_up_s"] = float(pa.get(DataKeys.PA_WIND_UP_DURATION, 0.0))
		payload[DataKeys.RESULT_ATTACK_LINE] = str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
		if pa.has(DataKeys.PA_GAUGE_ATK_PRE):
			payload[DataKeys.PA_GAUGE_ATK_PRE] = float(pa[DataKeys.PA_GAUGE_ATK_PRE])
			payload["gauge_def_pre"] = float(pa.get(DataKeys.RESOLVE_GAUGE_DEF_PRE, -1.0))
	if not atk.is_empty():
		if str(payload.get(DataKeys.ACTION_MOVE_ID, "")).is_empty():
			payload[DataKeys.RESULT_MOVE_ID] = str(atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")))
		if not payload.has(DataKeys.PA_GAUGE_ATK_PRE) and atk.has(DataKeys.PA_GAUGE_ATK_PRE):
			# Hit path: pending_attack was already cleared, but AttackResolver preserves the wind-up
			# gauge context on the combatant dict alongside last_move_id — read it from there.
			payload[DataKeys.PA_GAUGE_ATK_PRE] = float(atk[DataKeys.PA_GAUGE_ATK_PRE])
			payload["gauge_def_pre"] = float(atk.get(DataKeys.PA_GAUGE_DEF_PRE, -1.0))
		payload["atk_guard"] = str(atk.get(DataKeys.ATTACK_GUARD_LINE, ""))
		payload["atk_form"] = str(atk.get(DataKeys.PA_WEAPON_FORM, atk.get(DataKeys.COMBATANT_FORM_STR, "")))
		if CombatantEntityAccess.has_weapon(atk):
			var w = CombatantEntityAccess.get_weapon(atk)
			if w is Dictionary:
				payload[DataKeys.RESULT_WEAPON_ID] = str((w as Dictionary).get("id", ""))
			elif w != null and w.get("id") != null:
				payload[DataKeys.RESULT_WEAPON_ID] = str(w.id)
	if not tgt.is_empty():
		payload["def_guard"] = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, ""))
	for k in extras:
		payload[k] = extras[k]
	if str(payload.get(DataKeys.WD_KINEMATIC_DELIVERY, "")).is_empty() and not pa.is_empty():
		var arch: Variant = pa.get(DataKeys.WD_ARCHETYPE, null)
		if arch is Dictionary:
			var arch_delivery: String = str((arch as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
			if not arch_delivery.is_empty():
				payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = arch_delivery
	var outcome: String = str(payload.get(DataKeys.RESULT_OUTCOME, ""))
	if outcome in ["parry_deflect", "parry_partial"]:
		var clash: Variant = payload.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
		if clash is Dictionary:
			payload["parry_bind"] = bool(tgt.get(DataKeys.PA_PARRY_WAS_BIND, false)) if not tgt.is_empty() else false
			payload[DataKeys.RESULT_PARRY_CONTROL] = float((clash as Dictionary).get(CombatConstants.CLASH_KEY_PARRY_CONTROL, 0.0))
			if (clash as Dictionary).has(DataKeys.RESULT_REMAINING_RATIO):
				payload["follow_through_rem"] = float((clash as Dictionary)[DataKeys.RESULT_REMAINING_RATIO])
			var delivery: String = str((clash as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
			if not delivery.is_empty():
				payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = delivery


static func _clear_attacker_pending_attack(atk: Dictionary, manager: Node) -> void:
	if atk.is_empty():
		return
	var pa0: Dictionary = _pending_attack_read(atk)
	AttackWindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa0)
	CombatFootwork.clear_on_exchange_end(atk)
	atk.pending_attack = {}


static func _react_attacking_arm_loss_after_wound(manager: Node, c: Variant) -> void:
	if manager == null or c == null or not (c is Dictionary):
		return
	var cd: Dictionary = c as Dictionary
	if cd.is_empty():
		return
	CombatantEntityAccess.react_attacking_arm_lost_if_needed(manager, cd)


static func _clear_defender_footwork(tgt: Dictionary) -> void:
	if not tgt.is_empty():
		CombatFootwork.clear_on_exchange_end(tgt)


static func _abort_incoming_wind_up_if_target_died(manager: Node, target_id: int) -> void:
	if manager == null or target_id < 0:
		return
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
	if tgt.is_empty() or CombatantEntityAccess.alive_bool(tgt):
		return
	CounterTempo.abort_attacker_wind_up(manager, target_id)


## Parry outcomes default the defender to waiting. Paired formation moves (`swap_rank` / drag / fall_back_pair)
## keep both partners in motion state until resolve - do not clobber that here.
static func _defender_set_idle_after_parry(tgt: Dictionary) -> void:
	if tgt.is_empty():
		return
	if (
		CombatantEntityAccess.state_str(tgt)
		in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
	):
		return
	_clear_defender_footwork(tgt)
	CombatFootwork.return_to_waiting(tgt)
	tgt.state_timer = 0.0
	tgt.state_duration = 0.0


static func apply_result(manager: Node, attacker_id: int, result: Dictionary) -> void:
	var action: String = result.get(DataKeys.RESULT_ACTION, "skip")
	var target_id: int = result.get(DataKeys.ACTION_TARGET_ID, -1)
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if MedicalPhaseController.combat_resolution_blocked(manager):
		return
	_track_consecutive_action_start(atk)
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
	var tgt_scene: Node = CombatantEntityAccess.scene_node(tgt)
	var empty_result: Dictionary = {
		"dmg": 0,
		"died": false,
		"part": "",
		"damage_type": "",
		"outcome": "",
		"health_before": 0,
		"health_after": 0,
		"final_cut": 0,
		"final_blunt": 0
	}

	if action == "skip":
		if not atk.is_empty():
			if result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0) > 0.0:
				empty_result[DataKeys.RESULT_OUTCOME] = "skip"
				manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
				var pa_skip: Dictionary = _pending_attack_read(atk)
				atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_skip.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
				atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
				atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_skip.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
				atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "skip"
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
				_clear_attacker_pending_attack(atk, manager)
				_react_attacking_arm_loss_after_wound(manager, atk)
			else:
				CombatFootwork.return_to_waiting(atk)
				atk.gauge = 0.0
				atk.erase(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS)
				_clear_attacker_pending_attack(atk, manager)
				_react_attacking_arm_loss_after_wound(manager, atk)
		return
	if action == "defeated":
		if not tgt.is_empty():
			tgt.alive = false
			CombatFootwork.clear_on_death(tgt)
			tgt.state = CombatConstants.STATE_DEAD
			CombatStateHandlers.cancel_events_for_dead_combatant(manager, tgt)
		if not atk.is_empty():
			# Resolver abort (e.g. no targetable parts): do not leave attacker stuck in WIND_UP with stale
			# `pending_attack`. Clear consecutive counter since we never enter RECOVERING.
			atk.erase(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS)
			_clear_attacker_pending_attack(atk, manager)
			CombatFootwork.return_to_waiting(atk)
			atk.gauge = 0.0
			atk.state_timer = 0.0
			atk.state_duration = 0.0
		empty_result[DataKeys.RESULT_OUTCOME] = "defeated"
		empty_result[DataKeys.RESULT_DIED] = true
		_abort_incoming_wind_up_if_target_died(manager, target_id)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		var winner: String = manager._check_for_winner()
		if not winner.is_empty():
			manager._end_combat_phase(winner, tgt_scene)
		return
	if action == "miss":
		empty_result[DataKeys.RESULT_OUTCOME] = "miss"
		_log_outcome("miss", attacker_id, target_id)
		var pa_miss_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
		if not tgt.is_empty() and not pa_miss_log.is_empty():
			_record_resolved_exchange_yomi(tgt, attacker_id, pa_miss_log, true)
			_evaluate_counter_read_outcome(manager, attacker_id, target_id, CombatantEntityAccess.form_str(tgt))
		var miss_part: String = pa_miss_log.get(DataKeys.ACTION_TARGET_PART, "")
		if not miss_part.is_empty():
			empty_result[DataKeys.RESULT_PART] = miss_part
		CombatF5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "miss", miss_part)
		_enrich_payload_for_tuning(
			manager, empty_result, atk, tgt, pa_miss_log, {"recovery_s": float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0))}
		)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		# XCamp-4: proficiency gains on miss (wind-up completion).
		notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "miss", empty_result)
		if not atk.is_empty():
			var pa_miss: Dictionary = _pending_attack_read(atk)
			atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_miss.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
			atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_miss.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
			_record_line_outcome(manager, atk, true)
			atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_miss"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
			# Off-balance scales with commitment: a heavy committed swing that whiffs overextends
			# the fighter more than a light probe, leaving them vulnerable longer.
			var miss_intensity: float = float(pa_miss.get(CombatConstants.PA_KEY_INTENSITY, 0.5))
			var miss_off: float = CombatConstants.miss_off_balance_duration(miss_intensity)
			# HEMA: a failed feint leaves the attacker more committed than a failed direct strike —
			# the deceptive path (extra wind-up, body rotation, blade on a different arc) makes recovery
			# slower. Adds a bounded extra to the off-balance window.
			var miss_move_id: String = pa_miss.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			if WeaponConstants.is_feint_move(miss_move_id):
				miss_off += CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
			# HEMA: a whiffed thrust/lunge commits the body forward, making recovery slower than a cut.
			if not WeaponConstants.is_feint_move(miss_move_id) and \
			   WeaponConstants.contact_type_for_move_id(miss_move_id) == WeaponConstants.ATTACK_TYPE_STAB:
				miss_off += CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
			atk[DataKeys.PA_OFF_BALANCE_UNTIL] = CombatTiming.now_seconds() + miss_off
			# HEMA: a whiffed strike leaves the attacker's blade committed off-line — stamp the
			# attacker's open line so the defender can capitalize with a riposte/press.
			var miss_atk_line: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
			if not miss_atk_line.is_empty():
				CombatGuardLines.stamp_open_line(
					atk, miss_atk_line,
					CombatGuardLines.open_line_duration_s(miss_intensity, false),
					CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT
				)
			_clear_attacker_pending_attack(atk, manager)
		_clear_defender_footwork(tgt)
		return
	if action == "dodge":
		empty_result[DataKeys.RESULT_OUTCOME] = "dodge"
		_log_outcome("dodge", attacker_id, target_id)
		var pa_dodge_log: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
		if not tgt.is_empty() and not pa_dodge_log.is_empty():
			_record_resolved_exchange_yomi(tgt, attacker_id, pa_dodge_log, true)
		var dodge_part: String = str(pa_dodge_log.get(DataKeys.ATTACK_PARTIAL_DODGE_PART, pa_dodge_log.get(DataKeys.ACTION_TARGET_PART, "")))
		if not tgt.is_empty() and not pa_dodge_log.is_empty():
			_evaluate_counter_read_outcome(manager, attacker_id, target_id, CombatantEntityAccess.form_str(tgt))
		if not dodge_part.is_empty():
			empty_result[DataKeys.RESULT_PART] = dodge_part
		CombatF5SoakTrace.note_strike_avoided(attacker_id, target_id, atk, tgt, "dodge", dodge_part)
		_enrich_payload_for_tuning(
			manager, empty_result, atk, tgt, pa_dodge_log, {"recovery_s": float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0))}
		)
		manager.emit_signal("action_resolved", attacker_id, target_id, empty_result)
		# XCamp-4: proficiency gains on dodge (AGI for defender, STR wind-up for attacker).
		notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "dodge", empty_result)
		if not atk.is_empty():
			var pa_dodge_atk: Dictionary = _pending_attack_read(atk)
			atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_dodge_atk.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
			atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_dodge_atk.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
			_record_line_outcome(manager, atk, true)
			atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_miss"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
			# HEMA: a dodged strike leaves the attacker's blade committed off-line — stamp
			# the attacker's open line so the defender can capitalize with a riposte/press.
			var dodge_atk_line: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
			if not dodge_atk_line.is_empty():
				CombatGuardLines.stamp_open_line(
					atk, dodge_atk_line,
					CombatGuardLines.open_line_duration_s(
						float(pa_dodge_atk.get(CombatConstants.PA_KEY_INTENSITY, 0.5)),
						WeaponConstants.is_circumscription_move(str(pa_dodge_atk.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")))
					),
					CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT
				)
		if not tgt.is_empty():
			var dodge_intensity: float = _pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5) if not atk.is_empty() else 0.5
			_consume_stamina(manager, tgt, _stamina_dodge_cost_for_defender(atk, dodge_intensity, tgt))
			# Defender moved to avoid; blade/body ends in dodge position (e.g. duck high attack -> low guard).
			# Use effective_attack_line for diagonal moves (actual trajectory).
			var pa: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
			var move_id: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id) if not move_id.is_empty() else {}
			var atk_line: String = pa.get(
				DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high")
			)
			var dodge_guard: String = CombatConstants.DODGE_END_GUARD_FROM_ATTACK.get(
				atk_line, tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
			)
			GuardLineUpdater.set_guard_from_line(tgt, dodge_guard)
			# Positional feint: a dodged feint commits the defender's body OFF the feint line
			# (high feint dodged -> low guard, etc.), so that line is briefly open to a follow-up.
			# Mirrors the hit-feint open-line stamp: the dodge's guard shift just moved the blade
			# off `atk_line`, so the opened line is exactly the line that was dodged.
			if move_id != "" and WeaponConstants.is_feint_move(move_id):
				var dodged_open_line: String = str(atk_line)
				if not dodged_open_line.is_empty():
					CombatGuardLines.stamp_open_line(
						tgt, dodged_open_line,
						CombatGuardLines.open_line_duration_s(dodge_intensity, WeaponConstants.is_circumscription_move(move_id)),
						CombatConstants.FEINT_OPEN_LINE_PARRY_MULT
					)
			# HEMA: dodging a press into the defender's live open line re-commits the body off that
			# line — the opening deepens, so re-stamp it. stamp_open_line's no-shorten rule makes this
			# an extend-or-no-op: a lighter dodge cannot close a heavier opening. Feints already stamp
			# above, so only plain moves are handled here.
			if move_id != "" and not WeaponConstants.is_feint_move(move_id) and CombatGuardLines.has_live_open_line(tgt, atk_line):
				CombatGuardLines.stamp_open_line(
					tgt, atk_line,
					CombatGuardLines.open_line_duration_s(dodge_intensity, WeaponConstants.is_circumscription_move(move_id)),
					CombatConstants.FEINT_OPEN_LINE_PARRY_MULT
				)
			if CombatConstants.combat_debug_active():
				CombatDebug.log(
					(
                        "guard_line %s: -> %s (dodged %s)"
						% ["id:%d" % CombatantEntityAccess.id_int(tgt), dodge_guard, atk_line]
					)
				)
		if not atk.is_empty():
			_clear_attacker_pending_attack(atk, manager)
		_clear_defender_footwork(tgt)
		return
	if action == "parry_deflect":
		var incoming_parry_intensity: float = 0.5
		var pa_deflect: Dictionary = {}
		if not atk.is_empty():
			pa_deflect = _pending_attack_read(atk)
			if not tgt.is_empty() and not pa_deflect.is_empty():
				_record_resolved_exchange_yomi(tgt, attacker_id, pa_deflect, true)
			incoming_parry_intensity = float(
				pa_deflect.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
			)
			atk[DataKeys.ATTACK_LAST_MOVE_ID] = pa_deflect.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			atk[DataKeys.PA_LAST_MOVE_ID] = atk[DataKeys.ATTACK_LAST_MOVE_ID]
			atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = pa_deflect.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, "")
			# A parry is the defender covering the line — a true "read" the feint re-feint damp keys on.
			_record_line_outcome(manager, atk, true, true)
			# HEMA: store defender's guard and parry_clash_context for bind vs deflect.
			if not tgt.is_empty():
				atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
				atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = CombatantEntityAccess.form_str(tgt)
			else:
				atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = ""
				atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = ""
			var atk_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
			atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = atk_clash_raw if atk_clash_raw is Dictionary else {}
			_clear_attacker_pending_attack(atk, manager)
			atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_deflect"
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
			# HEMA: parry-deflect off-balance scales with intensity — heavier deflection = more disorientation.
			var deflect_ob_duration: float = CombatConstants.off_balance_deflect_duration(
				pa_deflect.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY)
			)
			# HEMA: a parried feint leaves the attacker more committed than a parried direct strike —
			# the deceptive commitment is harder to recover from. Bounded extra off-balance window.
			var deflect_move_id: String = pa_deflect.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			if WeaponConstants.is_feint_move(deflect_move_id):
				deflect_ob_duration += CombatConstants.FEINT_COMMIT_OFF_BALANCE_EXTRA_S
			# HEMA: a parried thrust commits forward; recovery is slower than a cut.
			elif not WeaponConstants.is_feint_move(deflect_move_id) and \
				 WeaponConstants.contact_type_for_move_id(deflect_move_id) == WeaponConstants.ATTACK_TYPE_STAB:
				deflect_ob_duration += CombatConstants.THRUST_COMMIT_OFF_BALANCE_EXTRA_S
			atk[DataKeys.PA_OFF_BALANCE_UNTIL] = CombatTiming.now_seconds() + deflect_ob_duration
			# HEMA: blade displacement is immediate — deflection is a physical event, not deferred to recovery end.
			var atk_move_disp: String = atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, ""))
			var atk_eff_disp: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
			var atk_def_guard_disp: String = atk.get(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY, "")
			var atk_clash_disp: Dictionary = atk.get(DataKeys.PA_PARRY_CLASH_CONTEXT, {})
			GuardLineUpdater.set_guard_deflected(atk, atk_move_disp, atk_eff_disp, atk_def_guard_disp, atk_clash_disp)
			# HEMA: the parried blade is committed on the line it was struck — a riposte into that
			# line finds the attacker's sword already displaced off it and their center off-balance,
			# so they cannot re-cover. Stamps the open-line payoff on the committed line (matches the
			# nach line-aim), distinct from the general off-balance surcharge above.
			if not atk_eff_disp.is_empty():
				CombatGuardLines.stamp_open_line(
					atk, atk_eff_disp,
					CombatGuardLines.open_line_duration_s(incoming_parry_intensity, false),
					CombatConstants.DEFLECT_OPEN_LINE_PARRY_MULT
				)
		if not tgt.is_empty():
			var consec_parries: int = _track_consecutive_parry_for_defender(tgt, manager)
			_consume_stamina(manager, tgt, _stamina_parry_cost_for_defender(atk, incoming_parry_intensity, consec_parries, tgt))
			# Parry recoil: a full parry is a momentum exchange — even a perfect parry transmits a fraction of the
			# incoming blow's momentum into the defender's braced arm (impulse-momentum). A well-braced parry
			# (high parry_control) catches more of the blow and transmits more to the arm. Mirrors the partial-parry
			# deflection model; the >0.5 gate keeps light (sword) parries effectively free.
			var recoil_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
			var recoil_clash: Dictionary = recoil_clash_raw if recoil_clash_raw is Dictionary else {}
			var recoil_momentum: float = recoil_clash.get("strike_momentum_kg_ms", 0.0)
			if recoil_momentum > 0.0:
				var parry_ctrl: float = float(
					recoil_clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL)
				)
				var recoil_node: Node = CombatantEntityAccess.scene_node(tgt)
				var recoil_def_weapon = CombatantEntityAccess.get_weapon(tgt)
				# HEMA: a heavier parrying weapon absorbs more of the impact, reducing the
				# recoil transmitted to the arm. Scale by the mass ratio (m_a / m_d) — equal masses (D001
				# SWORD mirror) yield 1.0, so the behavior is unchanged for the soak.
				var recoil_mass_scale: float = CombatConstants.parry_recoil_mass_scale(
					recoil_clash.get("m_a_parry", 0.0), recoil_clash.get("m_d_parry", 0.0)
				)
				# HEMA: a two-handed grip braces the weapon into the torso, distributing the impact
				# across both arms and the core, so less recoil reaches any single arm. One-handed
				# (SWORD/DAGGER/MACE/AXE) is neutral 1.0 — D001 SWORD soak unaffected.
				var recoil_two_handed_mult: float = CombatConstants.parry_two_handed_recoil_mult(
					WeaponConstants.weapon_is_two_handed(recoil_def_weapon)
				)
				# HEMA: a square-on catch (high alignment) drives the full force of the blow straight
				# into the blade and arm; a glancing catch (low alignment) deflects the force along the
				# blade, so less reaches the wrist. Alignment is already in the clash context.
				var recoil_alignment_mult: float = CombatConstants.parry_recoil_alignment_mult(
					float(recoil_clash.get("alignment", 0.5))
				)
				# HEMA: a flexible (slender) blade flexes on impact, spreading the impulse over a longer
				# contact time (lower peak force) so less recoil reaches the arm; a stiff (wide) blade
				# transmits a sharper impulse so more recoil. The flex factor is 1.0 at the SWORD
				# reference slenderness, so the D001 SWORD soak is neutral.
				var recoil_flex_mult: float = CombatConstants.parry_recoil_flex_mult(
					CombatConstants.flex_factor_for_slenderness(
						recoil_def_weapon.get_blade_slenderness() if recoil_def_weapon != null else 0.0
					)
				)
				# HEMA: a well-timed parry meets the blade early (near the forte/handle), a short lever
				# arm so less recoil reaches the wrist; a late parry meets it late (near the schwach/tip),
				# a long lever arm so more recoil. Driven by parry progress (weapon-independent).
				var recoil_progress_mult: float = CombatConstants.parry_recoil_progress_mult(
					float(recoil_clash.get("parry_progress", 0.5))
				)
				# HEMA: a heavier, well-rooted defender has more inertia (Newtonian), so the same
				# impulse produces less acceleration and less arm shock. Scales as
				# reference_mass / body_mass. D001 entities carry no species (null) -> neutral 1.0.
				var recoil_body_mass: float = 0.0
				if recoil_node != null and "species" in recoil_node and recoil_node.species != null:
					var recoil_species = recoil_node.species
					if recoil_species.has_method("resolved_reference_mass_kg"):
						recoil_body_mass = recoil_species.resolved_reference_mass_kg()
				var recoil_body_mass_scale: float = CombatConstants.parry_recoil_body_mass_scale(recoil_body_mass)
				var recoil_transfer: float = recoil_momentum * WeaponConstants.PARRY_DEFLECTION_MOMENTUM_FRACTION * parry_ctrl * recoil_mass_scale * recoil_two_handed_mult * recoil_alignment_mult * recoil_flex_mult * recoil_progress_mult * recoil_body_mass_scale
				var base_recoil: float = recoil_transfer * WeaponConstants.IMPULSE_DAMAGE_SCALE
				if recoil_node != null and recoil_node.has_method("_get_vital_parts"):
					var right_pain: float = EntityPainConsciousness._get_effective_pain_for_region(recoil_node, BodyPartConstants.PART_RIGHT_ARM)
					var left_pain: float = EntityPainConsciousness._get_effective_pain_for_region(recoil_node, BodyPartConstants.PART_LEFT_ARM)
					var arm_shock_mult: float = (
						PainConsciousnessConstants.get_pain_performance_modifier(right_pain)
						+ PainConsciousnessConstants.get_pain_performance_modifier(left_pain)
					) * 0.5
					base_recoil *= maxf(arm_shock_mult, CombatConstants.PERF_MOD_MIN)
				var recoil_part: String = BodyPartConstants.PART_CHEST
				var weapon_side: String = CombatantEntityAccess.get_attacking_arm(tgt)
				if weapon_side in [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM]:
					recoil_part = weapon_side
				var applied_recoil: float = base_recoil * WeaponConstants.PARRY_DEFLECTION_SHOCK_TRANSFER
				if applied_recoil > 0.5 and recoil_node != null:
					_apply_parry_deflection_blunt(manager, tgt, target_id, applied_recoil, recoil_part)
			# Weapon position: defender's blade met attacker's; blade ends in attack line.
			# Use effective_attack_line for diagonal moves (actual contact line).
			var move_id: String = atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")) if not atk.is_empty() else ""
			var eff_line: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else ""
			GuardLineUpdater.set_guard_from_move(tgt, move_id, eff_line)
			# HEMA: a successful parry onto the defender's own open line is demonstrated re-coverage —
			# the "you're open here" state is empirically resolved, so close it immediately.
			CombatGuardLines.close_open_line_on_recover(tgt, eff_line)
			# HEMA: parry bonus scales with parry quality — a clean catch gives a bigger tempo advantage.
			var _bonus_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
			var _bonus_clash: Dictionary = _bonus_clash_raw if _bonus_clash_raw is Dictionary else {}
			var _bonus_ctrl: float = float(_bonus_clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL))
			tgt[DataKeys.PA_PARRY_BONUS_UNTIL] = CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
			tgt[DataKeys.PA_PARRY_BONUS_MULT] = CombatConstants.parry_bonus_mult(_bonus_ctrl)
			if not CombatMobilityRetreat.cannot_commit_melee(tgt):
				# HEMA nach: record the attacker's committed line so the riposte aims at the opening
				# the parry created (attacker over-extended on this line and had their blade displaced off it).
				var nach_line: String = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else ""
				CounterTempo.grant_riposte_chain(manager, tgt, attacker_id, nach_line)
				var clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
				var clash: Dictionary = clash_raw if clash_raw is Dictionary else {}
				var arch_id: String = clash.get(DataKeys.PA_ARCHETYPE_ID, "")
				var can_bind: bool = arch_id.is_empty() or arch_id not in CombatConstants.ARCHETYPES_NEVER_BIND
				tgt[DataKeys.PA_PARRY_WAS_BIND] = (
					can_bind
					and CombatConstants.parry_bind_control_reached(
						float(clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL))
					)
				)
				tgt[DataKeys.PA_PARRY_AGAINST_ID] = attacker_id
				if tgt.get(DataKeys.PA_PARRY_WAS_BIND, false):
					CombatConstants.apply_parry_bind_riposte_gauge_bonus(tgt)
					CombatBindPressure.set_after_parry_bind(tgt, manager, attacker_id, float(clash.get(CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL)))
					CombatFlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
			else:
				tgt.erase(DataKeys.PA_PARRY_WAS_BIND)
				tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
				CounterTempo.clear_riposte_chain(tgt)
			_defender_set_idle_after_parry(tgt)
		empty_result[DataKeys.RESULT_OUTCOME] = "parry_deflect"
		var clash_emit: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
		if clash_emit is Dictionary:
			empty_result[DataKeys.PA_PARRY_CLASH_CONTEXT] = clash_emit
		_log_outcome("parry_deflect", attacker_id, target_id)
		var clash_log: Dictionary = (
			result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, {}) if result.get(DataKeys.PA_PARRY_CLASH_CONTEXT) is Dictionary else {}
		)
		_log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_deflect", clash_log)
		# XCamp-4: proficiency gains on parry_deflect (partial STR for both).
		notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_deflect", empty_result)
		if not atk.is_empty():
			CombatAIActionPicker.record_opp_parry_deflect_for_feint_listing(manager, atk, target_id)
		if not tgt.is_empty():
			CombatAttention.record_parry_deflect_on_attacker_memory(tgt, attacker_id)
			_evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
			## Phase 2: apply overcommit penalty — reduce parry readiness when wrong counter-read was just confirmed.
			if CombatWeaponForm.is_counter_read_committed(atk, manager.combat_clock):
				var recent_wrong: int = CombatWeaponForm.count_recent_wrong_readings(atk)
				if recent_wrong > 0:
					atk[DataKeys.PA_OVERCOMMIT_PARRY_MULT] = CombatConstantsEncounter.OVERCOMMIT_PARRY_DEFLECT_PENALTY
		_enrich_payload_for_tuning(manager, empty_result, atk, tgt, pa_deflect)
		manager.emit_signal("action_resolved", target_id, attacker_id, empty_result)
		return
	if action == "parry_partial":
		var incoming_partial_intensity: float = 0.5
		var pa_partial_emit: Dictionary = {}
		var partial_clash_raw: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
		if not atk.is_empty():
			var pa_partial_int: Dictionary = _pending_attack_read(atk)
			pa_partial_emit = pa_partial_int
			incoming_partial_intensity = pa_partial_int.get(DataKeys.ATTACK_INTENSITY, 0.5)
			atk[DataKeys.PA_PARRY_CLASH_CONTEXT] = partial_clash_raw if partial_clash_raw is Dictionary else {}
			if not tgt.is_empty():
				atk[DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY] = tgt.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)
				atk[DataKeys.PA_DEFENDER_FORM_AT_PARRY] = CombatantEntityAccess.form_str(tgt)
		if not tgt.is_empty():
			var consec_parries_partial: int = _track_consecutive_parry_for_defender(tgt, manager)
			# HEMA: a partial parry absorbs only a fraction of the incoming momentum — a light deflect
			# is a smaller isometric demand than a full braced stop. Scale cost by absorption (1 - remaining).
			var partial_remaining: float = pa_partial_emit.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
			var partial_absorption: float = 1.0 - clampf(partial_remaining, 0.0, 1.0)
			var partial_base_cost: float = _stamina_parry_cost_for_defender(atk, incoming_partial_intensity, consec_parries_partial, tgt)
			_consume_stamina(manager, tgt, partial_base_cost * CombatConstants.partial_parry_stamina_mult(partial_absorption))
			var pa_partial: Dictionary = _pending_attack_read(atk) if not atk.is_empty() else {}
			if not pa_partial.is_empty():
				_record_resolved_exchange_yomi(tgt, attacker_id, pa_partial, true)
			var move_id: String = pa_partial.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")
			var move_def: Dictionary = WeaponConstants.get_move(move_id)
			var atk_line: String = pa_partial.get(
				DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, move_def.get(DataKeys.PA_ATTACK_LINE, "high")
			)
			# HEMA: a partial parry onto the defender's own open line is a *partial* re-coverage — the
			# blade only caught the blow partway, so the line is re-covered partially and the live
			# window shrinks (vs. a full parry, which fully re-covers and clears it).
			CombatGuardLines.shrink_open_line_on_partial_recover(tgt, atk_line)
			var align_ctx: Dictionary = {}
			if pa_partial.get(DataKeys.ATTACK_ATTACK_ANGLE_DEG, -999.0) >= 0.0:
				var read: float = PassiveParryContext.get_passive_parry_readiness(tgt)
				var def_w = CombatantEntityAccess.get_weapon(tgt)
				var wob: Dictionary = CombatantEntityAccess.parry_wobble_context(def_w, read)
				align_ctx = {
					DataKeys.ATTACK_ANGLE_DEG: pa_partial[DataKeys.ATTACK_ANGLE_DEG],
					"guard_angle_deg": CombatFootwork.guard_angle_deg(tgt, wob),
				}
			var align: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
			if align >= CombatConstants.PARRY_PARTIAL_BIND_ALIGNMENT_THRESHOLD or align >= CombatConstants.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD:
				GuardLineUpdater.set_guard_from_move(tgt, move_id, atk_line)
				var pcl_bind: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
				var clash_bind: Dictionary = pcl_bind if pcl_bind is Dictionary else {}
				var arch_bind: String = clash_bind.get(DataKeys.PA_ARCHETYPE_ID, "")
				var can_bind_partial: bool = (
					arch_bind.is_empty() or arch_bind not in CombatConstants.ARCHETYPES_NEVER_BIND
				)
				var is_bind: bool = (
					can_bind_partial
					and CombatConstants.parry_bind_control_reached(
						float(
							clash_bind.get(
								CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
							)
						)
					)
				)
				tgt[DataKeys.PA_PARRY_WAS_BIND] = is_bind
				if is_bind:
					tgt[DataKeys.PA_PARRY_AGAINST_ID] = attacker_id
					tgt[DataKeys.PA_PARRY_BONUS_UNTIL] = (
						CombatTiming.now_seconds() + CombatConstants.PARRY_BONUS_AFTER_DEFLECT_S
					)
					tgt[DataKeys.PA_PARRY_BONUS_MULT] = CombatConstants.parry_bonus_mult(float(
						clash_bind.get(
							CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
						)
					))
					CombatBindPressure.set_after_parry_bind(tgt, manager, attacker_id, float(
							clash_bind.get(
								CombatConstants.CLASH_KEY_PARRY_CONTROL, CombatConstants.DEFAULT_PARRY_CONTROL
							)
						))
					CombatFlurryBind.open_pair_after_bind(manager, target_id, attacker_id)
					# Doc-9: a successful bind (blade locked) opens the same counterstrike window a full deflect does.
					if (
						CombatConstants.is_feature_parry_counterstrike_window_enabled()
						and not CombatMobilityRetreat.cannot_commit_melee(tgt)
					):
						CounterTempo.grant_riposte_chain(manager, tgt, attacker_id)
				else:
					tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
					tgt.erase(DataKeys.PA_PARRY_BONUS_UNTIL)
					tgt.erase(DataKeys.PA_PARRY_BONUS_MULT)
			else:
				tgt.erase(DataKeys.PA_PARRY_WAS_BIND)
				tgt.erase(DataKeys.PA_PARRY_AGAINST_ID)
				tgt.erase(DataKeys.PA_PARRY_BONUS_UNTIL)
				tgt.erase(DataKeys.PA_PARRY_BONUS_MULT)
			_defender_set_idle_after_parry(tgt)
		# Apply parry deflection damage — momentum impulse transfers through blade into defender's body.
		# HEMA force-plate: blade contact time ~20ms, 20% of incoming momentum transmits to defender's arm.
		var remaining_ratio: float = pa_partial_emit.get(DataKeys.ATTACK_PARRY_REMAINING_RATIO, 1.0)
		if remaining_ratio > CombatConstants.PARRY_REMAINING_DEFLECT_THRESHOLD and not tgt.is_empty():
			var clash_data: Dictionary = partial_clash_raw if (partial_clash_raw is Dictionary) else {}
			var strike_ke_j: float = clash_data.get("strike_kinetic_energy_j", 0.0)
			var strike_momentum: float = clash_data.get("strike_momentum_kg_ms", 0.0)
			if strike_ke_j > 0.0 and strike_momentum > 0.0:
				## Momentum-based deflection damage: F = Δp/Δt, with Δp = momentum × deflection_fraction. A parry
				## transmits a small fraction of the incoming blow into the defender's arm — typically a small damage
				## amount (~0.2-1.0), meaningful mainly for heavy blows. The >0.5 gate below suppresses the small
				## values, so light parries are effectively free.
				var deflection_ratio: float = clampf(remaining_ratio - CombatConstants.PARRY_REMAINING_DEFLECT_THRESHOLD, 0.0, CombatConstants.PARRY_DEFLECTION_RATIO_MAX) / CombatConstants.PARRY_DEFLECTION_RATIO_MAX
				var momentum_transfer: float = strike_momentum * deflection_ratio * WeaponConstants.PARRY_DEFLECTION_MOMENTUM_FRACTION
				var base_deflect_dmg: float = momentum_transfer * WeaponConstants.IMPULSE_DAMAGE_SCALE
				var node_tgt: Node = CombatantEntityAccess.combat_body(tgt)
				if node_tgt != null and node_tgt.has_method("_get_vital_parts"):
					var right_pain: float = EntityPainConsciousness._get_effective_pain_for_region(node_tgt, BodyPartConstants.PART_RIGHT_ARM)
					var left_pain: float = EntityPainConsciousness._get_effective_pain_for_region(node_tgt, BodyPartConstants.PART_LEFT_ARM)
					var right_arm_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(right_pain)
					var left_arm_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(left_pain)
					var arm_shock_mult: float = (right_arm_mod + left_arm_mod) * 0.5
					base_deflect_dmg *= maxf(arm_shock_mult, CombatConstants.PERF_MOD_MIN)
				var deflect_part: String = BodyPartConstants.PART_CHEST
				var weapon_side: String = CombatantEntityAccess.get_attacking_arm(tgt)
				if not weapon_side.is_empty() and weapon_side in [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM]:
					deflect_part = weapon_side
				var applied_deflect: float = base_deflect_dmg * WeaponConstants.PARRY_DEFLECTION_SHOCK_TRANSFER
				if applied_deflect > CombatConstants.PARRY_DEFLECTION_MIN_DAMAGE and node_tgt != null:
					_apply_parry_deflection_blunt(manager, tgt, target_id, applied_deflect, deflect_part)
		var partial_emit: Dictionary = {DataKeys.RESULT_OUTCOME: "parry_partial", DataKeys.RESULT_DMG: 0, DataKeys.RESULT_DIED: false}
		var pcl_emit: Variant = result.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
		if pcl_emit is Dictionary:
			partial_emit[DataKeys.PA_PARRY_CLASH_CONTEXT] = pcl_emit
		_log_outcome("parry_partial", attacker_id, target_id)
		var clash_partial: Dictionary = pcl_emit if pcl_emit is Dictionary else {}
		_log_fp_parry_outcome(atk, tgt, attacker_id, target_id, "parry_partial", clash_partial)
		# XCamp-4: proficiency gains on parry_partial (small STR for attacker).
		notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "parry_partial", partial_emit)
		if not atk.is_empty():
			_evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
			_record_line_outcome(manager, atk, true)
		## Phase 3: parry — defender's guard held, reset their breaks; attacker gets break on follow-through.
		if not atk.is_empty() and remaining_ratio <= CombatConstants.PARRY_REMAINING_DEFLECT_THRESHOLD:
			MentalStackDecider._reset_guard_breaks(atk)
		if remaining_ratio > CombatConstants.PARRY_REMAINING_DEFLECT_THRESHOLD and not tgt.is_empty():
			MentalStackDecider._record_guard_break(tgt)
		_enrich_payload_for_tuning(manager, partial_emit, atk, tgt, pa_partial_emit)
		if _tuning_context_enabled(manager) and not atk.is_empty():
			var parent_idx: int = _tuning_parry_parent_strike_index(manager)
			if parent_idx > 0:
				atk[DataKeys.PA_TUNING_FT_PARENT_STRIKE] = parent_idx
		manager.emit_signal("action_resolved", target_id, attacker_id, partial_emit)
		# Follow-through gate: skip strike execution when parry absorbed >=90% of energy (remaining <= 0.3). Tuning fix
		if remaining_ratio > CombatConstants.PARRY_FOLLOW_THROUGH_THRESHOLD:
			manager._execute_attack(attacker_id)
		return
	if action == "hit":
		CombatFlurryBind.clear_pair(manager, attacker_id, target_id)
		var ft_extras: Dictionary = _tuning_follow_through_extras(atk)
		# Evaluate counter-read outcome before clearing stale fields.
		if not atk.is_empty():
			_evaluate_counter_read_outcome(manager, attacker_id, target_id, atk.get(DataKeys.PA_DEFENDER_FORM_AT_PARRY, ""))
		# Follow-through after **`parry_partial`**: strip calibration carry so **`attack_hit`** recovery does not see
		# stale clash dict.
		if not atk.is_empty():
			atk.erase(DataKeys.PA_PARRY_CLASH_CONTEXT)
			atk.erase(DataKeys.PA_DEFENDER_GUARD_LINE_AT_PARRY)
			atk.erase(DataKeys.PA_DEFENDER_FORM_AT_PARRY)
			CombatAIActionPicker.clear_feint_listing_opp_parry_deflect_for_target(atk, target_id)
		if not tgt.is_empty():
			CombatAttention.clear_yomi_for_attacker(tgt, attacker_id)
		if not tgt.is_empty() and CombatantEntityAccess.state_str(tgt) == CombatConstants.STATE_MEDICAL_WIND_UP:
			CombatStateHandlers.abort_medical_wind_up(manager, target_id)
		var rd_raw: Variant = result.get(DataKeys.RESULT_RESULT_DICT, null)
		var result_dict: Dictionary = rd_raw if rd_raw is Dictionary else {}
		var intensity: float = result.get(DataKeys.ATTACK_INTENSITY, 0.5)
		# Harness diagnostic: log every hit outcome so we can trace damage accumulation vs lethality.
		if manager != null and manager.has_meta("_fp_harness_diag") and bool(manager.get_meta("_fp_harness_diag")):
			var atk_name: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
			var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id) if not tgt.is_empty() else "?"
			var died_flag: bool = result_dict.get(CombatConstants.RESULT_KEY_DIED, false)
			var final_cut: float = result_dict.get("final_cut", 0.0)
			var final_blunt: float = result_dict.get("final_blunt", 0.0)
			var dmg: int = result_dict.get("dmg", 0)
			var part: String = result_dict.get("part", "")
			CombatDebug.harness_diag(
                "hit_resolve atk=%s tgt=%s id=%d->%d part=%s cut=%.1f blunt=%.1f dmg=%d died=%s"
				% [atk_name, tgt_name, attacker_id, target_id, part, final_cut, final_blunt, dmg, str(died_flag)]
			)
		var winner: String = ""
		if result_dict.get(CombatConstants.RESULT_KEY_DIED, false):
			_abort_incoming_wind_up_if_target_died(manager, target_id)
			CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
			_enrich_payload_for_tuning(
				manager,
				result_dict,
				atk,
				tgt,
				{},
				_hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
			)
			_clear_tuning_follow_through_marker(atk)
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			# XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
			notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
			winner = manager._check_for_winner()
			if not winner.is_empty():
				manager._end_combat_phase(winner, tgt_scene)
			# Attacker still needs recovery (killing blow); otherwise they stay in WIND_UP and never get another turn.
			if atk != null and CombatantEntityAccess.alive_bool(atk):
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
				atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
				_set_post_strike_stamp(manager, atk, attacker_id, target_id)
				_record_line_outcome(manager, atk, false)
			return
		winner = manager._check_for_winner()
		if not winner.is_empty():
			if tgt != null and CombatantEntityAccess.is_incapacitated(tgt):
				var reason: String = "consciousness <= %d%%" % int(PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD)
				if CombatantEntityAccess.is_cowering(tgt):
					var cower_reason: String = ""
					var tgt_entity: Node = CombatantEntityAccess.scene_node(tgt)
					if tgt_entity != null and tgt_entity.has_method("get_cowering_reason"):
						cower_reason = tgt_entity.get_cowering_reason()
					if cower_reason == "legs":
						reason = "cowering (leg destruction)"
					elif not cower_reason.is_empty():
						reason = "cowering (no functional arms)"
				var suppress_log = (
					OperationalLog.is_play_session_active() and CombatConstants.combat_hit_summary_active()
				)
				if not suppress_log:
					# Compact stable token on the always-on line (cause_code already summarizes this); verbose reason is calibration-only.
					var incap_token: String = "UNCONSCIOUS"
					if CombatantEntityAccess.is_cowering(tgt):
						var cr: String = ""
						var te: Node = CombatantEntityAccess.scene_node(tgt)
						if te != null and te.has_method("get_cowering_reason"):
							cr = te.get_cowering_reason()
						incap_token = "COWERING_LEGS" if cr == "legs" else "COWERING_ARMS"
					if CombatDebug.dc_trace_active():
						CombatDebug.combat_session(
							"INCAPACITATED %s (%s)" % [CombatantEntityAccess.get_display_name(tgt, target_id), reason]
						)
					else:
						CombatDebug.combat_session(
							"INCAPACITATED %s -- %s" % [CombatantEntityAccess.get_display_name(tgt, target_id), incap_token]
						)
			CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
			_enrich_payload_for_tuning(
				manager,
				result_dict,
				atk,
				tgt,
				{},
				_hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
			)
			_clear_tuning_follow_through_marker(atk)
			manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
			# XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
			notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
			# Attacker still needs recovery; otherwise they stay in WIND_UP
			if atk != null and CombatantEntityAccess.alive_bool(atk):
				_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
				atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")
				atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
				atk.state = CombatConstants.STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
				_set_post_strike_stamp(manager, atk, attacker_id, target_id)
				_record_line_outcome(manager, atk, false)
			manager._end_combat_phase(winner, tgt_scene)
			return
		if not MedicalPhaseController.combat_resolution_blocked(manager):
			AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict, intensity)
		# last_move_id set in AttackResolver before clearing pending_attack
		_log_outcome("hit", attacker_id, target_id)
		CombatF5SoakTrace.note_hit_resolve(attacker_id, target_id, atk, tgt, result_dict)
		_enrich_payload_for_tuning(
			manager,
			result_dict,
			atk,
			tgt,
			{},
			_hit_tuning_extras(atk, intensity, float(result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.0)), ft_extras)
		)
		_clear_tuning_follow_through_marker(atk)
		manager.emit_signal("action_resolved", attacker_id, target_id, result_dict)
		# XCamp-4: proficiency gains on hit (STR scaled by damage, END for absorbing).
		notify_proficiency_gains_from_resolve(manager, attacker_id, target_id, "hit", result_dict)
		if atk != null and CombatantEntityAccess.alive_bool(atk):
			_consume_stamina(manager, atk, _stamina_attack_cost_for_attacker(manager, atk, target_id))
			atk[DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE] = atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "")  # Set in AttackResolver before clear
			atk[DataKeys.ATTACK_RECOVERY_CAUSE] = "attack_hit"
			atk.state = CombatConstants.STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.get(DataKeys.ATTACK_RECOVERY_DURATION, 0.5)
			_set_post_strike_stamp(manager, atk, attacker_id, target_id)
			_record_line_outcome(manager, atk, false)
			# HEMA nach/Vorschlag: a landed strike leaves the attacker holding initiative while the
			# defender is off-balance — grant a short fast re-commit window against the hit target.
			if (
				CombatConstants.is_feature_hit_continuation_window_enabled()
				and not CombatMobilityRetreat.cannot_commit_melee(atk)
			):
				CounterTempo.grant_hit_continuation(manager, atk, target_id)
		if tgt != null and CombatantEntityAccess.alive_bool(tgt):
			# Defender was hit; stagger/dropped guard - blade ends low. Sync guard_zone.
			GuardLineUpdater.set_guard_from_line(tgt, "low")
			# Impact disrupts bracing/proprioception: defender is briefly off-balance (reduced parry capacity,
			# slower guard fill, wider angle variance). Scales with blow intensity.
			tgt[DataKeys.PA_OFF_BALANCE_UNTIL] = CombatTiming.now_seconds() + CombatConstants.hit_defender_off_balance_duration(intensity)
			# Positional feint: if the hit move was a feint, the defender's guard was committed to
			# the feint line — they are "open" on that line for a short window.
			var hit_move_id: String = atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")
			if hit_move_id != "" and WeaponConstants.is_feint_move(hit_move_id):
				var open_line: String = str(atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, ""))
				if not open_line.is_empty():
					# HEMA verwunden (circumscription): the compound cut went AROUND the committed blade,
					# so the open payoff is the far side (opposite line) with a stronger parry penalty and
					# a longer open window — a plain feint leaves the same line slightly exposed instead.
					var is_circ: bool = WeaponConstants.is_circumscription_move(hit_move_id)
					var open_mult: float = CombatConstants.FEINT_OPEN_LINE_PARRY_MULT
					if is_circ:
						open_line = CombatGuardLines.opposite_line(open_line)
						open_mult = CombatConstants.CIRCUMSCRIPTION_OPEN_LINE_PARRY_MULT
					CombatGuardLines.stamp_open_line(
						tgt, open_line,
						CombatGuardLines.open_line_duration_s(intensity, is_circ),
						open_mult
					)
			CombatantEntityAccess.manager_apply_formation_hit_reaction_if_needed(manager, target_id, intensity)
		## Phase 3: track guard break on hit (defense fully failed).
		if not atk.is_empty():
			MentalStackDecider._reset_guard_breaks(atk)
		if not tgt.is_empty():
			MentalStackDecider._record_guard_break(tgt)
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
	var move_id: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
	if not move_id.is_empty():
		CombatAttention.record_resolved_strike_toward_defender(defender, attacker_id, move_id)
	if count_feint_if_feint and not move_id.is_empty():
		var md: Dictionary = WeaponConstants.get_move(move_id)
		if md.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false) or WeaponConstants.is_feint_move(move_id):
			CombatAttention.record_feint_resolved_toward_defender(defender, attacker_id)


## MS-L8: stamp the attacker's dict with the combat clock so MS-L8 post-strike momentum fires next turn.
## Line-memory: record that a strike on `effective_line` just failed (got read) so the
## AI's move selection de-weights re-attacking that line for a short decay window. On a
## success (hit) the line's entry is cleared instead, so pressing an advantage is not
## penalized. No-op when the effective line is empty (e.g. non-strike actions).
##
## `parried` flags that the defender actively covered the line (a parry), as opposed to a
## miss (no contact) or a dodge (defender moved off the line). Only a parry is true
## evidence that "the defender now expects this line" — the signal `feint_read_fail_m`
## keys on. Misses and dodges still record into ATTACK_LINE_FAIL_MEMORY (the general
## vary-after-failure heuristic) but not into ATTACK_LINE_PARRY_MEMORY.
static func _record_line_outcome(manager: Node, atk: Dictionary, failed: bool, parried: bool = false) -> void:
	if atk.is_empty() or manager == null:
		return
	var line: String = str(atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, ""))
	if line.is_empty():
		return
	var mem: Dictionary = atk.get(DataKeys.ATTACK_LINE_FAIL_MEMORY, {})
	if failed:
		mem[line] = manager.combat_clock
	else:
		mem.erase(line)
	atk[DataKeys.ATTACK_LINE_FAIL_MEMORY] = mem
	if failed and parried:
		var pmem: Dictionary = atk.get(DataKeys.ATTACK_LINE_PARRY_MEMORY, {})
		pmem[line] = manager.combat_clock
		atk[DataKeys.ATTACK_LINE_PARRY_MEMORY] = pmem
	elif not failed:
		atk.erase(DataKeys.ATTACK_LINE_PARRY_MEMORY)


static func _set_post_strike_stamp(
	manager: Node, atk: Dictionary, attacker_id: int, struck_target_id: int = -1
) -> void:
	if not CombatConstants.is_feature_ms_post_strike_enabled():
		return
	if atk.is_empty() or manager == null:
		return
	var atk_read: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if not atk_read.is_empty():
		atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = manager.combat_clock
		if struck_target_id >= 0:
			atk_read[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = struck_target_id


## XCamp-4: award proficiency stat gains from a resolved attack action.
## Called after each action outcome (miss, dodge, hit, parry) in apply_result.
static func notify_proficiency_gains_from_resolve(
	manager: Node, attacker_id: int, target_id: int, action: String, result_dict: Dictionary
) -> void:
	if not CompanyState.read_stub_proficiency_enabled():
		return

	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
	if atk.is_empty():
		return

	var weapon_id: String = CombatantEntityAccess.weapon_type_id(atk)
	var form_str: String = CombatantEntityAccess.form_str(atk)

	var attacker_entity: Node = CombatantEntityAccess.combat_body(atk)
	var target_entity: Node = CombatantEntityAccess.combat_body(tgt) if not tgt.is_empty() else null
	var atk_tracked: bool = attacker_entity != null and EntityProficiency.is_stat_gain_tracked(attacker_entity)
	var tgt_tracked: bool = not tgt.is_empty() and target_entity != null and EntityProficiency.is_stat_gain_tracked(target_entity)
	# XCamp-4: physical stat training (striking / dodging / absorbing / parrying) is gated by how
	# cleanly the fighter executed the act. Two multiplicative factors: blood loss
	# (wounded_write_factor) and pain x consciousness execution quality (execution_quality_factor)
	# — the same pain/consciousness model the combat system uses to degrade the fighter's actions.
	# Perception reads (dodge / parry / counter-read) are cognitive and intentionally NOT scaled.
	# For a healthy, fully blooded fighter both factors are 1.0, so uncompromised fighters train
	# exactly as before.
	var atk_wounded: float = (
		EntityProficiency.wounded_write_factor(float(attacker_entity.blood_volume))
		* EntityProficiency.execution_quality_factor(attacker_entity)
		if attacker_entity != null else 1.0
	)
	var def_wounded: float = (
		EntityProficiency.wounded_write_factor(float(target_entity.blood_volume))
		* EntityProficiency.execution_quality_factor(target_entity)
		if target_entity != null else 1.0
	)
	# XCamp-4: desirable-difficulty for the perception channel — successfully *reading* or *deflecting*
	# a stronger opponent's attack is a sharper perception lesson, mirroring the attacker-STR scaling
	# already applied on a clean hit (opponent_difficulty_mult, same stats_dict source). For the parry /
	# dodge reads the *reader is the defender*, so the attacker is the foe; the counter-read path in
	# _evaluate_counter_read_outcome inverts the pair (reader = attacker, foe = defender).
	var atk_str: float = CombatantEntityAccess.stats_dict(atk).get(
		DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
	)
	var def_str: float = EntityProficiency.GAIN_DIFFICULTY_STR_BASE
	if not tgt.is_empty():
		def_str = CombatantEntityAccess.stats_dict(tgt).get(
			DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
		)

	# XCamp-4: a completed strike attempt (rep) trains the attacker's weapon/form even when it did not
	# land — a clean hit already carries the larger GAIN_*_PROF_HIT_BASE share via the hit path.
	# Gated by the same execution-quality x blood-loss composite as the physical stat reps: a
	# compromised fighter executes the swing less cleanly, so the motor rep is worth less.
	if atk_tracked and action != "hit" and action != "defeated":
		EntityProficiency.award_weapon_proficiency(
			attacker_entity, weapon_id, EntityProficiency.GAIN_WEAPON_PROF_ATTEMPT_BASE * atk_wounded
		)
		EntityProficiency.award_form_proficiency(
			attacker_entity, form_str, EntityProficiency.GAIN_FORM_PROF_ATTEMPT_BASE * atk_wounded
		)

	# XCamp-4: a committed strike is aerobic exertion — the wind-up, strike, and recovery cycle
	# trains cardiovascular/muscular-stamina conditioning (END) regardless of outcome. This is the
	# attacker's END channel (previously they trained END only by taking damage), so a fighter who
	# swings a lot but blocks well still builds endurance. Fires on every offensive outcome incl. a
	# clean hit; "defeated" completes no swing. Scaled by the wounded factor like other physical
	# gains; cognitive (PER) and weapon/form familiarity are unaffected.
	if atk_tracked and action != "defeated" and attacker_entity != null and "_proficiency_bonus" in attacker_entity:
		EntityProficiency.award_stat_gain(
			attacker_entity, "endurance", EntityProficiency.GAIN_STRIKE_AEROBIC_END_BASE * atk_wounded, weapon_id, form_str
		)
		# XCamp-4: a completed wind-up trains the attacker's execution AGI regardless of outcome -
		# miss / dodge / hit / parry all complete the swing, so timing/execution is trained on every
		# committed strike ("defeated" completes no swing). Previously miss-only, which created an
		# inverted incentive where a clean hit trained AGI *less* than a whiff.
		EntityProficiency.award_stat_gain(
			attacker_entity, "agility", EntityProficiency.GAIN_WINDUP_COMPLETED_AGI_BASE * atk_wounded, weapon_id, form_str
		)

	match action:
		"miss":
			# Strike attempted: the wind-up STR rep. (Wind-up AGI is now awarded in the common
			# committed-strike block above, so it fires on every swing, not just a miss.)
			# XCamp-4 write-side gate: only tracked attackers accrue (untracked enemies stay flat).
			if atk_tracked:
				EntityProficiency.award_stat_gain(
					attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded, weapon_id, form_str
				)

		"dodge":
			# Defender dodged - AGI gain for defender. Attacker gets STR wind-up gain.
			if tgt.is_empty() or target_entity == null:
				if atk_tracked:
					EntityProficiency.award_stat_gain(
						attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded, weapon_id, form_str
					)
				return
			var outnumbered := _is_defender_outnumbered(manager, tgt)
			var dodge_gain := EntityProficiency.GAIN_DODGE_EVADED_BASE
			if outnumbered:
				dodge_gain += EntityProficiency.GAIN_DODGE_OUTNUMBERED_BONUS
			if tgt_tracked:
				var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
				var tgt_form: String = CombatantEntityAccess.form_str(tgt)
				# Desirable difficulty: evading a *stronger* foe's strike is a sharper reflex lesson,
				# so the defender's AGI gain scales with the attacker's strength (same factor as the
				# perception read in the same dodge).
				EntityProficiency.award_stat_gain(
					target_entity, "agility",
					dodge_gain * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon, tgt_form
				)
				# XCamp-4: evading reads the attack line (perception) — subordinate to the parry read.
				# Cognitive: not scaled by blood loss, but scaled by execution quality — a dazed fighter
				# reads the attack less sharply, so the perception lesson is smaller. Also scaled by the
				# attacker's difficulty (desirable difficulty): dodging a *stronger* foe's strike is a
				# sharper read, matching the attacker-STR scaling on a clean hit.
				EntityProficiency.award_stat_gain_raw(
					target_entity, "perception",
					EntityProficiency.GAIN_DODGE_READ_PER_BASE
					* EntityProficiency.execution_quality_factor(target_entity)
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
				)
			if atk_tracked:
				EntityProficiency.award_stat_gain(
					attacker_entity, "strength", EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * atk_wounded, weapon_id, form_str
				)

		"hit":
			# Attacker hit - STR gain scaled by damage dealt AND opponent difficulty (beating a stronger foe
			# teaches more — desirable-difficulty principle). Write-side gate: tracked attackers only.
			if atk_tracked:
				var dmg: float = result_dict.get(DataKeys.RESULT_DMG, 0)
				var str_gain := (
					EntityProficiency.GAIN_MELEE_HIT_BASE
					+ minf(
						dmg / EntityProficiency.GAIN_HIT_STR_DAMAGE_DIVIDER,
						EntityProficiency.GAIN_MELEE_HIT_MAX_DMG_CONTRIB
					)
				)
				# Self-relative difficulty (desirable difficulty): a near-level bout is the 1.0 baseline,
				# beating a much stronger foe teaches proportionally more. Sized against the fighter's
				# own strength (atk_str/def_str read at the top of the resolve). 1.0 when no target.
				var hit_difficulty: float = (
					EntityProficiency.opponent_difficulty_mult(def_str, atk_str)
					if not tgt.is_empty() else 1.0
				)
				str_gain *= hit_difficulty
				EntityProficiency.award_stat_gain(attacker_entity, "strength", str_gain * atk_wounded, weapon_id, form_str)

				# Severe wound bonus (severity from result_dict). A critical landed on a stronger foe is a
				# harder, more valuable lesson, so it scales by the same difficulty factor as the hit STR.
				var wound_severity: String = result_dict.get(DataKeys.RESULT_WOUND_SEVERITY, "")
				if not wound_severity.is_empty():
					var sev_mult: float = EntityProficiency.get_severity_mult(wound_severity)
					EntityProficiency.award_stat_gain(
						attacker_entity,
						"strength",
						EntityProficiency.GAIN_SEVERE_WOUND_BASE * sev_mult * hit_difficulty * atk_wounded,
						weapon_id,
						form_str
					)

				var move_id_hit: String = str(result_dict.get(DataKeys.ACTION_MOVE_ID, result_dict.get(DataKeys.ATTACK_ATTACK_TYPE, "")))
				var move_def_hit: Dictionary = (
					WeaponConstants.get_move(move_id_hit) if not move_id_hit.is_empty() else {}
				)
				var hit_part: String = str(result_dict.get(DataKeys.RESULT_PART, ""))
				var intended_part: String = str(result_dict.get(DataKeys.ACTION_TARGET_PART, result_dict.get(DataKeys.AIM_PART_OVERRIDE, "")))
				var focus_part: String = ""
				if not tgt.is_empty():
					focus_part = CombatAttention.get_focus_part(tgt)
				# XCamp-4: targeting gains (weapon/form/INT/PER) for the attacker on a clean hit.
				# The enclosing block is already gated on atk_tracked. atk_wounded (blood x execution
				# quality) gates the weapon/form motor gains; execution_quality_factor alone gates the
				# cognitive INT/PER awards (a pained/dazed fighter reads the field less sharply).
				# The weapon/form motor gains scale by the same target-difficulty factor computed
				# above (hit_difficulty): landing a clean hit on a *stronger* foe is a sharper
				# weapon-handling lesson, mirroring the hit STR gain.
				EntityProficiency.notify_targeting_gains_from_hit(
					attacker_entity, weapon_id, form_str, move_def_hit, hit_part, intended_part, focus_part,
					atk_wounded, EntityProficiency.execution_quality_factor(attacker_entity),
					hit_difficulty
				)

			# Defender END gain for absorbing damage. Gated on the write-side tracked flag: only
			# tracked defenders accrue stat bonuses (untracked enemies stay at baseline). The defender's
			# stance form modulates the END (a braced/defensive guard that absorbs force trains more
			# endurance than a loose one) — consistent with the parry-deflect/parry-partial sites.
			if target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
				var dmg_taken: float = result_dict.get(DataKeys.RESULT_DMG, 0)
				var end_gain := (
					EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE
					+ minf(
						dmg_taken / EntityProficiency.GAIN_END_DMG_TAKEN_DIVIDER,
						EntityProficiency.GAIN_DAMAGE_ABSORBED_MAX_CONTRIB
					)
				)
				var tgt_wep_hit: String = CombatantEntityAccess.weapon_type_id(tgt)
				var tgt_frm_hit: String = CombatantEntityAccess.form_str(tgt)
				EntityProficiency.award_stat_gain(target_entity, "endurance", end_gain * def_wounded, tgt_wep_hit, tgt_frm_hit)

		"parry_deflect":
			# Both attacker and defender get wind-up completion gains.
			# Defender also gets END gain for successfully blocking (absorbing parry recoil).
			# Write-side gate: tracked attackers only.
			if atk_tracked:
				EntityProficiency.award_stat_gain(
					attacker_entity,
					"strength",
					EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT * atk_wounded,
					weapon_id,
					form_str
				)
			if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
				var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
				var tgt_form: String = CombatantEntityAccess.form_str(tgt)
				# XCamp-4: the parrier's physical gains modulate with their weapon/form — a parry is a
				# defensive weapon act, so STR and END both carry the stance/weapon modifiers (consistent
				# with the hit path's absorbed-END handling). Meeting a *stronger* foe's blade is a harder
				# physical lesson, so both also scale by the desirable-difficulty factor.
				EntityProficiency.award_stat_gain(
					target_entity,
					"strength",
					EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_STR_MULT * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon,
					tgt_form
				)
				EntityProficiency.award_stat_gain(
					target_entity,
					"endurance",
					EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE * EntityProficiency.GAIN_PARRY_DEFLECT_END_MULT * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon,
					tgt_form
				)
				# XCamp-4: a clean parry is a fast reactive act — beyond the weapon skill (STR) and force
				# absorption (END), the defender trains reflex/timing (AGI). Smaller than a dodge because a
				# parry is a controlled, localised movement. Gated on the write-side tracked flag. Reacting
				# to a *stronger* foe's faster strike is a harder reflex lesson, so this also scales by the
				# desirable-difficulty factor.
				EntityProficiency.award_stat_gain(
					target_entity,
					"agility",
					EntityProficiency.GAIN_PARRY_REFLEX_AGI_BASE * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon,
					tgt_form
				)
				# XCamp-4: a clean parry is a *read* of the incoming attack line — threat detection /
				# anticipation (perception), the sharpest perception lesson in the exchange. Not scaled
				# by blood loss or form/weapon, but scaled by execution quality (a dazed fighter reads
				# less sharply) and by the attacker's difficulty (desirable difficulty: meeting a
				# *stronger* foe's blade is a sharper read). Fires on parry_deflect; a partial parry
				# earns the reduced share below.
				EntityProficiency.award_stat_gain_raw(
					target_entity, "perception",
					EntityProficiency.GAIN_PARRY_READ_PER_BASE
					* EntityProficiency.execution_quality_factor(target_entity)
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
				)
				# XCamp-4: a clean parry is a precise defensive weapon act — the parrier trains
				# their own weapon/form (documented: fires on parry_deflect and parry_partial).
				# Gated by the defender's execution-quality x blood-loss composite like the
				# other parry physical gains, and scaled by the attacker's difficulty (meeting a
				# stronger foe's blade is a harder weapon-control rep).
				if tgt_tracked:
					EntityProficiency.award_weapon_proficiency(
						target_entity, tgt_weapon,
						EntityProficiency.GAIN_PARRY_WEAPON_PROF_BASE * def_wounded
						* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
					)
					EntityProficiency.award_form_proficiency(
						target_entity, tgt_form,
						EntityProficiency.GAIN_PARRY_FORM_PROF_BASE * def_wounded
						* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
					)

		"parry_partial":
			# Attacker gets partial STR gain; defender gets a partial END gain for absorbing the reduced hit
			# (a partial parry still transmits some force into the defender's arm — less than a full deflect).
			# Write-side gate: tracked attackers only.
			if atk_tracked:
				EntityProficiency.award_stat_gain(
					attacker_entity,
					"strength",
					EntityProficiency.GAIN_STRIKE_ATTEMPTED_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_STR_MULT * atk_wounded,
					weapon_id,
					form_str
				)
			if not tgt.is_empty() and target_entity != null and "_proficiency_bonus" in target_entity and tgt_tracked:
				var tgt_weapon: String = CombatantEntityAccess.weapon_type_id(tgt)
				var tgt_form: String = CombatantEntityAccess.form_str(tgt)
				# Desirable difficulty: a partial parry still met a *stronger* foe's line, so the
				# absorbed-END lesson scales with the attacker's strength, matching the PER read.
				EntityProficiency.award_stat_gain(
					target_entity,
					"endurance",
					EntityProficiency.GAIN_DAMAGE_ABSORBED_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_END_MULT * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon,
					tgt_form
				)
				# XCamp-4: a partial parry still met the line — reflex/timing was exercised, just less
				# cleanly than a full deflect, so the parrier earns a reduced AGI reflex gain. Also
				# scales by the desirable-difficulty factor (meeting a stronger foe's line is harder).
				EntityProficiency.award_stat_gain(
					target_entity,
					"agility",
					EntityProficiency.GAIN_PARRY_REFLEX_AGI_BASE * EntityProficiency.GAIN_PARRY_PARTIAL_AGI_MULT * def_wounded
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str),
					tgt_weapon,
					tgt_form
				)
				# XCamp-4: a partial parry still met the line — the read was right, the execution just
				# fell short, so the parrier earns a reduced perception read (same 0.3 partial fraction
				# as the other parry awards). Not blood- or form-scaled, but scaled by execution
				# quality (a dazed fighter reads less sharply) and by the attacker's difficulty
				# (desirable difficulty: reading a *stronger* foe is a sharper lesson).
				EntityProficiency.award_stat_gain_raw(
					target_entity,
					"perception",
					EntityProficiency.GAIN_PARRY_READ_PER_BASE
					* EntityProficiency.GAIN_PARRY_PARTIAL_PER_MULT
					* EntityProficiency.execution_quality_factor(target_entity)
					* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
				)
				# XCamp-4: a partial parry still met the line — the parrier trains their weapon/form
				# too, gated by the defender's execution-quality x blood-loss composite and scaled by
				# the attacker's difficulty (meeting a stronger foe's line is a harder weapon-control rep).
				if tgt_tracked:
					EntityProficiency.award_weapon_proficiency(
						target_entity, tgt_weapon,
						EntityProficiency.GAIN_PARRY_WEAPON_PROF_BASE * def_wounded
						* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
					)
					EntityProficiency.award_form_proficiency(
						target_entity, tgt_form,
						EntityProficiency.GAIN_PARRY_FORM_PROF_BASE * def_wounded
						* EntityProficiency.opponent_difficulty_mult(atk_str, def_str)
					)

		"defeated":
			# No proficiency gains on defeated action.
			pass

		_:
			# skip - no gains
			pass


## Phase 2: evaluate whether a counter-read switch was correct by comparing the defender's actual form at action start against their inferred form.
static func _evaluate_counter_read_outcome(
	manager: Node, attacker_id: int, target_id: int, defender_form_at_parry: String
) -> void:
	if manager == null or attacker_id < 0 or target_id < 0:
		return
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return
	## Check if the attacker had a counter-read commitment stamp — this means they auto-switched based on inference.
	if not CombatWeaponForm.is_counter_read_committed(atk, manager.combat_clock):
		return
	## The defender's actual form at action start was captured and stored on the attacker.
	## If the attacker switched to a counter-form expecting that form but got something else, record wrong.
	var inferred_key: String = CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID
	var cache_raw: Variant = atk.get(inferred_key, null)
	if cache_raw is not Dictionary:
		return
	var cached_val: Variant = (cache_raw as Dictionary).get(str(target_id), "")
	if cached_val is String and not str(cached_val).is_empty():
		var inferred_form: String = str(cached_val).strip_edges()
		var success: bool = defender_form_at_parry.strip_edges() == inferred_form
		CombatWeaponForm.record_counter_read_outcome(atk, target_id, success, inferred_form)
		CombatAttention.record_deception_outcome(atk, target_id, success)
		# XCamp-4: a committed counter-read outcome trains perception regardless of correctness
		# (a wrong read still teaches what that line was NOT). Not form-scaled, but scaled by the
		# reader's execution quality — a dazed fighter reads the opponent's form less reliably — and
		# by the target's difficulty (desirable difficulty: predicting a *stronger* foe's form is a
		# sharper read). Here the reader is the attacker, so the target (defender) is the foe.
		var atk_ent: Node = CombatantEntityAccess.scene_node(atk)
		if atk_ent != null and EntityProficiency.is_stat_gain_tracked(atk_ent):
			var per_amount: float = (
				EntityProficiency.GAIN_COUNTER_READ_CORRECT_PER_BASE if success
				else EntityProficiency.GAIN_COUNTER_READ_WRONG_PER_BASE
			)
			per_amount *= EntityProficiency.execution_quality_factor(atk_ent)
			var atk_str: float = CombatantEntityAccess.stats_dict(atk).get(
				DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
			)
			var def_dict: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, target_id)
			var def_str: float = EntityProficiency.GAIN_DIFFICULTY_STR_BASE
			if not def_dict.is_empty():
				def_str = CombatantEntityAccess.stats_dict(def_dict).get(
					DataKeys.ENTITY_STRENGTH, EntityProficiency.GAIN_DIFFICULTY_STR_BASE
				)
			per_amount *= EntityProficiency.opponent_difficulty_mult(def_str, atk_str)
			EntityProficiency.award_stat_gain_raw(atk_ent, "perception", per_amount)


## Checks if the defender combatant is the last alive in their slot group (outnumbered).
static func _is_defender_outnumbered(manager: Node, defender: Dictionary) -> bool:
	var slot_key: String = defender.get(DataKeys.COMBATANT_SLOT_KEY, "")
	if slot_key.is_empty():
		return false
	var slot_group: String = slot_key.get_slice("_", 0) if "_" in slot_key else ""
	if slot_group.is_empty():
		return false
	var defender_side := CombatantEntityAccess.side_str(defender)
	var count_alive_in_group: int = 0
	if not manager.has_method("get_combatants"):
		return false
	for c in manager.get_combatants():
		if not c is Dictionary:
			continue
		if not CombatantEntityAccess.side_str(c) == defender_side:
			continue
		var c_slot: String = c.get(DataKeys.COMBATANT_SLOT_KEY, "").get_slice("_", 1)
		if c_slot != slot_group:
			continue
		if not CombatantEntityAccess.alive_bool(c):
			continue
		count_alive_in_group += 1
	return count_alive_in_group <= 1


## Apply deflection shock damage from parry_partial — residual force transmitted through blade into defender's body.
static func _apply_parry_deflection_blunt(manager: Node, tgt: Dictionary, target_id: int, dmg_blunt: float, part: String) -> void:
	if dmg_blunt < 0.5 or tgt.is_empty():
		return
	var node_tgt: Node = CombatantEntityAccess.scene_node(tgt)
	if node_tgt == null or not node_tgt.has_method("take_damage_split"):
		return
	node_tgt.take_damage_split(0.0, dmg_blunt, part)
	if CombatConstants.combat_debug_active():
		var tgt_name: String = CombatantEntityAccess.get_display_name(tgt, target_id)
		CombatDebug.log("[ParryDeflect] %s took %.1f blunt from parry shock on %s" % [tgt_name, dmg_blunt, part])
	if manager != null and manager.has_signal("action_resolved"):
		var deflect_log: Dictionary = {
			"outcome": "parry_deflection_shock",
			"dmg": int(roundf(dmg_blunt)),
			"part": part,
			"damage_type": "blunt",
		}
		manager.emit_signal("action_resolved", target_id, -1, deflect_log)
