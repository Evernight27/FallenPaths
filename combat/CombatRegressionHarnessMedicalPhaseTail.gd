class_name CombatRegressionHarnessMedicalPhaseTail
extends RefCounted

## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _MedicalWindUp := preload("res://combat/MedicalWindUpHandler.gd")
const _AfterblowHandler := preload("res://combat/AfterblowHandler.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _ProcessTick := preload("res://combat/CombatProcessTick.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _MedicalActionStarter := preload("res://combat/MedicalActionStarter.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _BattleScene := preload("res://ui/BattleScene.gd")

## Medical phase: queued enemy melee and wind-up are torn down; dispatch does not resolve attacks.
static func _run_medical_phase_cancels_pending_enemy_melee(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ent_enemy := CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var en: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(en)
	en.state = CombatConstants.STATE_WIND_UP
	en.state_duration = 0.5
	en.pending_attack = {
		"target_id": p_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high",
	}
	var resolve_at: float = mgr.combat_clock + 0.1
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": e_id,
		"resolve_at": resolve_at,
		"data": {},
	})
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	mgr._end_combat_phase("player", ent_enemy)
	if not mgr.medical_phase:
		CombatRegressionHarness._fail(failures, "medical_phase_melee: expected medical_phase after player win")
		CombatRegressionHarness._free_manager(mgr)
		return
	if _EntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_melee: enemy should not remain in wind_up after teardown")
	if _EntityAccess.state_str(en) == CombatConstants.STATE_RECOVERING:
		CombatRegressionHarness._fail(failures, "medical_phase_melee: enemy should not remain in recovering after teardown")
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_melee: pending EVENT_MELEE_ATTACK should be cancelled")
	var enemy_actions: Array = mgr.get_available_actions(e_id)
	for raw in enemy_actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var mid: String = str((raw as Dictionary).get("move_id", ""))
		if not CombatConstants.is_medical_move(mid) and mid != CombatConstants.MOVE_ID_WAIT:
			CombatRegressionHarness._fail(
				failures,
				"medical_phase_melee: enemy should not list combat move %s" % mid
			)
			break
	mgr.combat_clock = resolve_at + 0.01
	_EventDispatch.process_event_queue(mgr)
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_melee: expected no action_resolved got fired=%d" % int(fired_box[0])
		)
	if _EntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_melee: enemy still wind_up after queued melee dispatch")
	CombatRegressionHarness._free_manager(mgr)


## After medical phase, afterblow must not resolve a losing-side wind-up.
static func _run_medical_phase_blocks_afterblow_on_loser(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var en: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(en)
	en.state = CombatConstants.STATE_WIND_UP
	en.pending_attack = {
		"target_id": p_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high",
	}
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	if _AfterblowHandler.try_afterblow(mgr, p_id, e_id, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 0.2):
		CombatRegressionHarness._fail(failures, "medical_phase_afterblow: try_afterblow should be false for losing side")
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(failures, "medical_phase_afterblow: expected no action_resolved")
	if not _EntityAccess.nested_dictionary_read(en, "pending_attack").is_empty():
		CombatRegressionHarness._fail(failures, "medical_phase_afterblow: pending_attack should clear")
	if _EntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_afterblow: enemy should not remain in wind_up")
	CombatRegressionHarness._free_manager(mgr)


## schedule_event / schedule_action_ready ignore losing-side combat queue entries during medical phase.
static func _run_medical_phase_blocks_scheduled_enemy_events(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_EventScheduler.schedule_action_ready(mgr, e_id, 0.05)
	if _EventScheduler.get_next_action_ready_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_schedule: enemy action_ready should not schedule")
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_schedule: enemy melee should not schedule")
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": e_id,
		"resolve_at": mgr.combat_clock + 0.05,
		"data": {},
	})
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_schedule: enemy melee via schedule_event should be blocked")
	_EventScheduler.schedule_action_ready(mgr, p_id, 0.05)
	if _EventScheduler.get_next_action_ready_at(mgr, p_id) < 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_schedule: winner action_ready should schedule")
	CombatRegressionHarness._free_manager(mgr)


## Teardown drops queued formation resolves for the losing side.
static func _run_medical_phase_teardown_cancels_formation_resolve(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var en: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(en)
	en.state = CombatConstants.STATE_SWAP_RANK
	en.state_duration = 2.0
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": e_id,
		"resolve_at": mgr.combat_clock + 0.5,
		"data": {"partner_id": -1},
	})
	mgr._end_combat_phase("player", _EntityAccess.scene_node(en))
	if _EntityAccess.state_str(en) == CombatConstants.STATE_SWAP_RANK:
		CombatRegressionHarness._fail(failures, "medical_phase_formation: enemy should leave swap_rank after teardown")
	var has_swap: bool = false
	for ev in mgr.event_queue:
		if typeof(ev) == TYPE_DICTIONARY and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			has_swap = true
			break
	if has_swap:
		CombatRegressionHarness._fail(failures, "medical_phase_formation: swap_rank_resolve should be cancelled")
	CombatRegressionHarness._free_manager(mgr)


## Purge pass + wind-up start guard: only winner combat events remain schedulable.
static func _run_medical_phase_purge_queue_and_windup_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var en: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(en)
	mgr.event_queue.clear()
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": e_id,
		"resolve_at": mgr.combat_clock + 0.2,
		"data": {},
	})
	_EventScheduler.schedule_action_ready(mgr, p_id, 0.3)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_MedicalPhase.halt_losing_side_combat(mgr)
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_purge: enemy melee should be purged from queue")
	if _EventScheduler.get_next_action_ready_at(mgr, p_id) < 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_purge: winner action_ready should remain in queue")
	_WindUpStarter.start(mgr, e_id, p_id, "thrust")
	if _EntityAccess.state_str(en) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_purge: losing-side wind-up start should be blocked")
	if not _EntityAccess.nested_dictionary_read(en, "pending_attack").is_empty():
		CombatRegressionHarness._fail(failures, "medical_phase_purge: losing-side pending_attack should stay empty")
	CombatRegressionHarness._free_manager(mgr)


## Loser skip_turn is a no-op during medical phase (no log spam / no reschedule).
static func _run_medical_phase_skip_turn_silent_for_loser(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var en: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(en)
	en.state = CombatConstants.STATE_WAITING
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_EventScheduler.cancel_pending_action_ready(mgr, e_id)
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	_EntityAccess.manager_skip_turn(mgr, e_id, CombatConstants.SKIP_TURN_LOG_PASS, "harness")
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(failures, "medical_phase_skip: loser skip_turn should not emit action_resolved")
	if _EventScheduler.get_next_action_ready_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_skip: loser skip_turn should not schedule action_ready")
	CombatRegressionHarness._free_manager(mgr)


## During medical phase the winner cannot start combat moves (thrust / wait / wind-up).
static func _run_medical_phase_winner_combat_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	mgr.resolve_action(p_id, e_id, "thrust", {})
	if _EntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_winner: thrust should not start wind-up")
	mgr.resolve_action(p_id, p_id, CombatConstants.MOVE_ID_WAIT, {})
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(failures, "medical_phase_winner: wait should not emit during medical phase")
	_WindUpStarter.start(mgr, p_id, e_id, "thrust")
	if _EntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WIND_UP:
		CombatRegressionHarness._fail(failures, "medical_phase_winner: AttackWindUpStarter.start should be blocked")
	var res: Dictionary = _AttackResolver.resolve_attack(mgr, p_id)
	if str(res.get("action", "")) != "skip":
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_winner: resolve_attack should skip got %s" % str(res.get("action", ""))
		)
	CombatRegressionHarness._free_manager(mgr)


## Winner-side action listing during medical phase must not offer combat or flee moves.
static func _run_medical_phase_winner_listing_medical_only(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var medic_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(medic_ent, "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ally_ent.take_damage_split(4.0, 1.0, "chest")
	mgr.register(ally_ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._end_combat_phase("player", _EntityAccess.scene_node(mgr.combatants[2]))
	var medic: Dictionary = mgr.combatants[0]
	medic.state = CombatConstants.STATE_WAITING
	var medic_id: int = _EntityAccess.id_int(medic)
	var blocked_move_ids: Array[String] = [
		"thrust", "cut", "slice", CombatConstants.MOVE_ID_WAIT, CombatConstants.MOVE_ID_FLEE,
		CombatConstants.MOVE_ID_ATTEMPT_CLOSE, CombatConstants.MOVE_ID_FALL_BACK,
		CombatConstants.MOVE_ID_SWAP_RANK,
	]
	var actions: Array = _ActionsBuilder.build(mgr, medic_id)
	for a in actions:
		var mid: String = str(a.get("move_id", ""))
		if mid in blocked_move_ids:
			CombatRegressionHarness._fail(
				failures,
				"medical_phase_winner_listing: blocked move_id '%s' in %s" % [mid, str(actions)]
			)
	CombatRegressionHarness._free_manager(mgr)


## AttackResultApplier must not apply combat outcomes during medical phase.
static func _run_medical_phase_apply_result_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_AttackResultApplier.apply_result(
		mgr,
		p_id,
		{"action": "hit", "target_id": p_id, "recovery_duration": 0.5, "result_dict": {"died": false}}
	)
	if int(fired_box[0]) != 0:
		CombatRegressionHarness._fail(failures, "medical_phase_applier: apply_result should not emit during medical phase")
	CombatRegressionHarness._free_manager(mgr)


## Second `_end_combat_phase("player")` refreshes teardown without re-emitting `enemies_eliminated`.
static func _run_medical_phase_end_combat_idempotent(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	en.state = CombatConstants.STATE_WIND_UP
	en.pending_attack = {"target_id": _EntityAccess.id_int(mgr.combatants[0]), "attack_type": "thrust", "intensity": 0.5}
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": e_id,
		"resolve_at": mgr.combat_clock + 0.2,
		"data": {},
	})
	var emit_box: Array = [0]
	mgr.enemies_eliminated.connect(
		func(_w: String) -> void:
			emit_box[0] = int(emit_box[0]) + 1
	)
	mgr._end_combat_phase("player", null)
	if not mgr.medical_phase:
		CombatRegressionHarness._fail(failures, "medical_phase_idempotent: expected medical_phase after first end")
	mgr._end_combat_phase("player", null)
	if int(emit_box[0]) != 1:
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_idempotent: enemies_eliminated should emit once got %d"
			% int(emit_box[0])
		)
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, e_id) >= 0.0:
		CombatRegressionHarness._fail(failures, "medical_phase_idempotent: loser melee should stay cancelled after refresh")
	CombatRegressionHarness._free_manager(mgr)


## Tier 6.2: winner fled before medical phase — clear **`combat_absent`**, suspend bleed, list triage.
static func _run_medical_phase_winner_fled_suspends_bleed_tick(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	mgr._end_combat_phase("player", null)
	if bool(c.get("combat_absent", false)):
		CombatRegressionHarness._fail(
			failures, "med_phase_fled: winner combat_absent should clear for medical listing"
		)
	if not bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
		CombatRegressionHarness._fail(
			failures, "med_phase_fled: winner should suspend bleed ticks after fleeing"
		)
	if _EntityAccess.state_str(c) == CombatConstants.STATE_FLED:
		CombatRegressionHarness._fail(
			failures, "med_phase_fled: winner should leave STATE_FLED for medical listing"
		)
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		CombatRegressionHarness._fail(
			failures,
			"med_phase_fled: want STATE_WAITING for triage got %s" % _EntityAccess.state_str(c)
		)
	if not _EntityAccess.is_alive_in_combat(c):
		CombatRegressionHarness._fail(failures, "med_phase_fled: fled winner should list medical actions")
	CombatRegressionHarness._free_manager(mgr)


## Fled winner with active bleed: medical tick must not drain blood while suspend flag is set.
static func _run_medical_phase_fled_winner_bleed_suspended_on_tick(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	var node: Node = _EntityAccess.scene_node(c)
	if node == null or not ("blood_volume" in node):
		CombatRegressionHarness._fail(failures, "med_phase_bleed_suspend: missing scene node blood")
		CombatRegressionHarness._free_manager(mgr)
		return
	node.take_damage_split(6.0, 2.0, "chest")
	if _EntityWounds.get_total_bleeding_rate(node) <= 0.0:
		CombatRegressionHarness._fail(failures, "med_phase_bleed_suspend: need active bleed on chest wound")
		CombatRegressionHarness._free_manager(mgr)
		return
	node.set_combat_blood_loss_mult(1.0)
	node.set_combat_blood_recovery_per_s(0.0)
	var bv_before: float = float(node.blood_volume)
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	mgr._end_combat_phase("player", null)
	_ProcessTick.tick(mgr, 2.0)
	if float(node.blood_volume) < bv_before - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"med_phase_bleed_suspend: blood %.2f should not drop from %.2f on tick"
			% [float(node.blood_volume), bv_before]
		)
	c.erase(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK)
	_ProcessTick.tick(mgr, 2.0)
	if float(node.blood_volume) >= bv_before - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"med_phase_bleed_suspend: blood should drain after suspend flag cleared (still %.2f)"
			% float(node.blood_volume)
		)
	CombatRegressionHarness._free_manager(mgr)


## Winner who stayed on field: medical phase must keep bleed ticks (urgency / triage pressure).
static func _run_medical_phase_non_fled_winner_bleed_continues_on_tick(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	var node: Node = _EntityAccess.scene_node(c)
	if node == null or not ("blood_volume" in node):
		CombatRegressionHarness._fail(failures, "med_phase_bleed_continue: missing scene node blood")
		CombatRegressionHarness._free_manager(mgr)
		return
	node.take_damage_split(6.0, 2.0, "chest")
	if _EntityWounds.get_total_bleeding_rate(node) <= 0.0:
		CombatRegressionHarness._fail(failures, "med_phase_bleed_continue: need active bleed on chest wound")
		CombatRegressionHarness._free_manager(mgr)
		return
	node.set_combat_blood_loss_mult(1.0)
	node.set_combat_blood_recovery_per_s(0.0)
	var bv_before: float = float(node.blood_volume)
	mgr._end_combat_phase("player", null)
	if bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
		CombatRegressionHarness._fail(
			failures, "med_phase_bleed_continue: non-fled winner must not suspend bleed ticks"
		)
	_ProcessTick.tick(mgr, 2.0)
	if float(node.blood_volume) >= bv_before - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"med_phase_bleed_continue: blood should drop from %.2f (still %.2f)"
			% [bv_before, float(node.blood_volume)]
		)
	CombatRegressionHarness._free_manager(mgr)


## Combat stop tears down suspend_bleed_tick so overworld bleed is not frozen on reused dicts.
static func _run_medical_phase_stop_clears_suspend_bleed_tick(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	mgr._end_combat_phase("player", null)
	if not bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
		CombatRegressionHarness._fail(failures, "med_phase_stop: setup want suspend_bleed_tick after fled medical entry")
	mgr.stop()
	if bool(c.get(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK, false)):
		CombatRegressionHarness._fail(failures, "med_phase_stop: stop() should erase suspend_bleed_tick")
	CombatRegressionHarness._free_manager(mgr)


## Medical log: ally bandage uses clear procedure label (not bare **`bandage_self`**).
static func _run_combat_log_formatter_bandage_ally_label(failures: PackedStringArray) -> void:
	var line: String = _CombatLogFormatter.format_action_line(
		"Alice",
		"player",
		"Bob",
		"player",
		{
			"outcome": "bandaged",
			"part": "left_leg",
			"effectiveness": 1.0,
			"medical_move_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
			"medical_target_is_self": false,
		}
	)
	if not line.contains("bandage (ally)"):
		CombatRegressionHarness._fail(failures, "bandage_ally_log: want bandage (ally) got '%s'" % line)
	if not line.contains("Bob"):
		CombatRegressionHarness._fail(failures, "bandage_ally_log: want target name in line")


static func _harness_wound_chest_for_packing(ent: Node) -> void:
	if ent == null:
		return
	# Thoracic cut at moderate+ (≥25% of chest max) so pack eligibility is stable; keep damage below vital collapse.
	_EntityWounds.add_wound(
		ent, "chest", _Bleeding.INJURY_TYPE_CUT, 9.0, "thoracic",
		_Bleeding.SEVERITY_MODERATE
	)


## Tier 6.1: **`pack_wound`** legal only on **`PACKING_PARTS`** with open wounds.
static func _run_pack_wound_strict_subregion_eligibility(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_EntityWounds.add_wound(
		ent, "head", _Bleeding.INJURY_TYPE_CUT, 5.0, "neck",
		_Bleeding.SEVERITY_MODERATE
	)
	if ent.wounds.get("head", []).size() > 0:
		ent.wounds["head"][0]["is_arterial"] = false
	if ent.can_apply_packing("head"):
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_strict: moderate non-arterial neck should not allow packing"
		)
	ent.wounds["head"].clear()
	_EntityWounds.add_wound(
		ent, "head", _Bleeding.INJURY_TYPE_CUT, 5.0, "neck",
		_Bleeding.SEVERITY_MODERATE
	)
	if ent.wounds["head"].size() != 1:
		CombatRegressionHarness._fail(failures, "pack_wound_strict: expected one neck wound")
	else:
		ent.wounds["head"][0]["is_arterial"] = true
	if not ent.can_apply_packing("head"):
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_strict: moderate arterial neck should allow packing"
		)
	ent.wounds["head"].clear()
	_EntityWounds.add_wound(
		ent, "head", _Bleeding.INJURY_TYPE_CUT, 12.0, "neck",
		_Bleeding.SEVERITY_SEVERE
	)
	if not ent.can_apply_packing("head"):
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_strict: severe neck should allow packing when linen ok"
		)


static func _run_pack_wound_can_apply_on_chest_wound(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	if not ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(failures, "pack_wound_can: chest wound should allow packing")
	if ent.can_apply_packing("left_arm"):
		CombatRegressionHarness._fail(failures, "pack_wound_can: left_arm not a packing part")


static func _run_pack_wound_blocked_when_already_packed(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	seed(88201)
	var ok: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not ok:
		CombatRegressionHarness._fail(failures, "pack_wound_packed: setup apply_packing should succeed")
	if ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(failures, "pack_wound_packed: should not pack twice")


static func _run_pack_wound_lists_in_medical_phase(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ent_enemy: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally: Dictionary = mgr.combatants[1]
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent == null:
		CombatRegressionHarness._fail(failures, "pack_wound_list: need ally entity")
		CombatRegressionHarness._free_manager(mgr)
		return
	_harness_wound_chest_for_packing(ally_ent)
	mgr._end_combat_phase("player", ent_enemy)
	if not mgr.medical_phase:
		CombatRegressionHarness._fail(failures, "pack_wound_list: expected medical_phase")
		CombatRegressionHarness._free_manager(mgr)
		return
	mgr.combatants[0]["gauge"] = 100.0
	mgr.combatants[0].state = CombatConstants.STATE_WAITING
	var acts: Array = mgr.get_available_actions(healer_id)
	var found_pressure: bool = false
	var found_pack: bool = false
	for raw in acts:
		if raw is not Dictionary:
			continue
		var a: Dictionary = raw
		if int(a.get("target_id", -1)) != _EntityAccess.id_int(ally):
			continue
		if str(a.get("target_part", "")) != "chest":
			continue
		var mid: String = str(a.get("move_id", ""))
		if CombatConstants.is_direct_pressure_move(mid):
			found_pressure = true
		elif CombatConstants.is_pack_wound_move(mid):
			found_pack = true
	CombatRegressionHarness._free_manager(mgr)
	if not found_pressure:
		CombatRegressionHarness._fail(failures, "pack_wound_list: actively bleeding chest should list apply_direct_pressure first")
	if found_pack:
		CombatRegressionHarness._fail(failures, "pack_wound_list: pack_wound should not list before pressure on active chest bleed")


static func _run_bandage_allowed_on_packed_part(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	seed(88203)
	var packed: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not packed:
		CombatRegressionHarness._fail(failures, "bandage_packed: setup packing should succeed")
	if not ent.can_apply_bandage("chest"):
		CombatRegressionHarness._fail(failures, "bandage_packed: should allow outer bandage over pack")


static func _run_direct_pressure_held_suppresses_bleed_rate(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "right_arm")
	if not ent.wounds.has("right_arm"):
		CombatRegressionHarness._fail(failures, "direct_pressure_held: need arm wound")
		return
	# Venous compressible bleed: arterial retained-flow (~50%) is intentionally weaker than this gate.
	for injury in ent.wounds["right_arm"]:
		injury["is_arterial"] = false
		injury["current_bleeding_rate"] = float(injury.get("base_bleeding_rate", injury.get("current_bleeding_rate", 0.0)))
	var raw: float = _EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
	if raw <= _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(failures, "direct_pressure_held: wound should bleed before pressure")
		return
	if not ent.apply_direct_pressure("right_arm"):
		CombatRegressionHarness._fail(failures, "direct_pressure_held: apply_direct_pressure failed")
		return
	var held: float = _EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
	if held >= raw * 0.4:
		CombatRegressionHarness._fail(failures, "direct_pressure_held: expected strong suppression while held got raw=%.3f held=%.3f" % [raw, held])


static func _run_direct_pressure_release_rebleeds_without_dressing(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "left_leg")
	if not ent.wounds.has("left_leg"):
		CombatRegressionHarness._fail(failures, "direct_pressure_rebound: need leg wound")
		return
	ent.apply_direct_pressure("left_leg")
	var held: float = _EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
	_EntityMedical.release_direct_pressure_on_part(ent, "left_leg")
	var after: float = _EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
	if after <= held + _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(failures, "direct_pressure_rebound: expected higher bleed after early release")


static func _run_treatment_channel_count_not_raw_hit_count(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	for _i in 6:
		_EntityWounds.add_wound(
			ent, "head", _Bleeding.INJURY_TYPE_CUT, 2.0, "scalp", _Bleeding.SEVERITY_MODERATE
		)
	if ent.wounds.get("head", []).size() != 1:
		CombatRegressionHarness._fail(failures, "treatment_channels: merge should leave one injury row")
		return
	var channels: int = _EntityMedical.get_treatment_channel_count(ent, "head")
	if channels != 1:
		CombatRegressionHarness._fail(failures, "treatment_channels: expected 1 channel for one sub_region got %d" % channels)
	var pack_s: float = _EntityMedical.get_packing_application_time_seconds_for_part(ent, "head")
	var raw_pack: float = (
		_Bleeding.PACKING_APPLICATION_TIME_SECONDS
		+ _Bleeding.PACKING_PER_WOUND_EXTRA_SECONDS * 5.0
	)
	if pack_s >= raw_pack - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"treatment_channels: channel pack %.1f should beat six-hit raw %.1f"
			% [pack_s, raw_pack]
		)


static func _run_failed_dressing_retains_direct_pressure(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.6, "severity": "moderate"},
	]
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "failed_dressing_retain: pressure setup failed")
		return
	if ent.apply_bandage("chest", 0.0):
		CombatRegressionHarness._fail(failures, "failed_dressing_retain: zero-eff bandage should fail")
		return
	if not _EntityMedical.has_direct_pressure_on_part(ent, "chest"):
		CombatRegressionHarness._fail(
			failures, "failed_dressing_retain: failed bandage must keep direct pressure"
		)
	ent.bandaged_parts.erase("chest")
	ent.linen_strips_remaining = 4
	ent.wounds["chest"] = [
		{"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
	]
	if ent.apply_packing("chest", 0.0):
		CombatRegressionHarness._fail(failures, "failed_dressing_retain: zero-eff packing should fail")
		return
	if not _EntityMedical.has_direct_pressure_on_part(ent, "chest"):
		CombatRegressionHarness._fail(
			failures, "failed_dressing_retain: failed packing must keep direct pressure"
		)


static func _run_dressings_blocked_without_pressure_when_bleeding(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var ally_ent := CombatRegressionHarness._new_entity("SWORD")
	var healer_ent := CombatRegressionHarness._new_entity("SWORD")
	ally_ent.take_damage_split(8.0, 3.0, "head")
	mgr.register(healer_ent, "player")
	mgr.register(ally_ent, "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_c: Dictionary = mgr.combatants[0]
	var ally_c: Dictionary = mgr.combatants[1]
	if _MedicalPhase.dressings_allowed_for_part(mgr, ally_c, "head"):
		CombatRegressionHarness._fail(failures, "dressings_gate: should block dressings on active unheld head bleed")
		return
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, healer_c, ally_c, "head")
	var mids: Array = []
	for raw in acts:
		if raw is Dictionary:
			mids.append(str((raw as Dictionary).get("move_id", "")))
	if CombatConstants.MOVE_ID_BANDAGE_SELF in mids or CombatConstants.MOVE_ID_PACK_WOUND in mids:
		CombatRegressionHarness._fail(failures, "dressings_gate: bandage/pack listed without pressure")
	CombatRegressionHarness._free_manager(mgr)


static func _run_dressings_still_offered_after_failure_out_of_peril(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var ally_ent := CombatRegressionHarness._new_entity("SWORD")
	var healer_ent := CombatRegressionHarness._new_entity("SWORD")
	ally_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.05, "base_bleeding_rate": 0.4, "severity": "moderate"},
	]
	ally_ent.apply_direct_pressure("chest")
	mgr.register(healer_ent, "player")
	mgr.register(ally_ent, "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_c: Dictionary = mgr.combatants[0]
	var ally_c: Dictionary = mgr.combatants[1]
	ally_c["failed_medical_parts"] = ["chest"]
	if not _MedicalPhase.has_left_immediate_peril_permanently(mgr, ally_c):
		CombatRegressionHarness._fail(
			failures, "dressings_retry: ally should be out of immediate peril for this fixture"
		)
		return
	if not _MedicalPhase.dressings_allowed_for_part(mgr, ally_c, "chest"):
		CombatRegressionHarness._fail(
			failures, "dressings_retry: must still allow dressings after failed attempt when out of peril"
		)
		return
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, healer_c, ally_c, "chest")
	var mids: Array = []
	for raw in acts:
		if raw is Dictionary:
			mids.append(str((raw as Dictionary).get("move_id", "")))
	if CombatConstants.MOVE_ID_BANDAGE_SELF not in mids:
		CombatRegressionHarness._fail(
			failures,
			"dressings_retry: bandage_self should stay listed after failure (got %s)" % str(mids)
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_pending_retry_set_even_with_other_medics(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var ally_ent := CombatRegressionHarness._new_entity("SWORD")
	var healer_a := CombatRegressionHarness._new_entity("SWORD")
	var healer_b := CombatRegressionHarness._new_entity("SWORD")
	ally_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.4, "severity": "moderate"},
	]
	ally_ent.apply_direct_pressure("chest")
	mgr.register(healer_a, "player")
	mgr.register(healer_b, "player")
	mgr.register(ally_ent, "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_ac: Dictionary = mgr.combatants[0]
	var healer_bc: Dictionary = mgr.combatants[1]
	var ally_c: Dictionary = mgr.combatants[2]
	_MedicalCoord.track_failure_and_maybe_retry(
		mgr, healer_ac, ally_c, "chest", _EntityAccess.id_int(ally_c)
	)
	var pending: Variant = healer_ac.get("pending_retry", null)
	if typeof(pending) != TYPE_DICTIONARY or (pending as Dictionary).is_empty():
		CombatRegressionHarness._fail(
			failures, "pending_retry: performer should keep retry hint after dressing failure"
		)
	elif (pending as Dictionary).get("part", "") != "chest":
		CombatRegressionHarness._fail(failures, "pending_retry: expected chest part in retry hint")
	var failed: Variant = ally_c.get("failed_medical_parts", null)
	if not (failed is Array) or "chest" not in (failed as Array):
		CombatRegressionHarness._fail(failures, "pending_retry: failed_medical_parts should track chest")
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_ai_prefers_dressing_over_stabilize_out_of_peril(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var healer_ent := CombatRegressionHarness._new_entity("SWORD")
	var ally_ent := CombatRegressionHarness._new_entity("SWORD")
	ally_ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.08, "severity": "moderate"},
	]
	ally_ent.apply_direct_pressure("chest")
	mgr.register(healer_ent, "player")
	mgr.register(ally_ent, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally_id: int = _EntityAccess.id_int(mgr.combatants[1])
	if _MedicalPhase.is_in_immediate_peril(mgr, mgr.combatants[1]):
		CombatRegressionHarness._fail(
			failures, "medical_ai_dressing: fixture should be out of immediate peril"
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	var bandage_act: Dictionary = {
		"move_id": "bandage_self", "target_id": ally_id, "target_part": "chest",
	}
	var stab_act: Dictionary = {
		"move_id": "stabilize_wound", "target_id": ally_id, "target_part": "chest",
	}
	var w_bandage: float = _AIPicker._get_medical_weight(bandage_act, healer_id, mgr)
	var w_stab: float = _AIPicker._get_medical_weight(stab_act, healer_id, mgr)
	if w_bandage <= w_stab:
		CombatRegressionHarness._fail(
			failures,
			"medical_ai_dressing: bandage weight %.3f should exceed stabilize %.3f out of peril"
			% [w_bandage, w_stab]
		)
	CombatRegressionHarness._free_manager(mgr)


static func _run_entity_untreated_matches_bridge(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
	ent.bandaged_parts["chest"] = true
	if _EntityWounds.entity_has_untreated_wounds(ent):
		CombatRegressionHarness._fail(failures, "entity_untreated: bandaged part should not count as untreated")
	var open: Node = CombatRegressionHarness._new_entity("SWORD")
	open.wounds["chest"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
	if not _EntityWounds.entity_has_untreated_wounds(open):
		CombatRegressionHarness._fail(failures, "entity_untreated: open wound should count as untreated")


static func _run_pressure_held_until_dressed(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["left_leg"] = [
		{
			"current_bleeding_rate": 0.05,
			"base_bleeding_rate": 0.4,
			"severity": "moderate",
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("left_leg")
	for _i in range(120):
		_EntityWounds.process_bleeding(ent, 1.0)
	if ent.self_direct_pressure_part != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"pressure_hold: compression should stay until part is dressed (part=%s)"
			% ent.self_direct_pressure_part
		)
	if bool(ent.bandaged_parts.get("left_leg", false)):
		CombatRegressionHarness._fail(failures, "pressure_hold: wound should remain undressed in this fixture")
	ent.apply_bandage("left_leg", 1.5)
	if ent.self_direct_pressure_part == "left_leg":
		CombatRegressionHarness._fail(
			failures, "pressure_hold: successful bandage should clear compression"
		)


static func _run_wound_merge_same_subregion(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_EntityWounds.add_wound(ent, "head", _Bleeding.INJURY_TYPE_CUT, 3.0, "face", _Bleeding.SEVERITY_MODERATE)
	_EntityWounds.add_wound(ent, "head", _Bleeding.INJURY_TYPE_CUT, 3.0, "face", _Bleeding.SEVERITY_MODERATE)
	if ent.wounds.get("head", []).size() != 1:
		CombatRegressionHarness._fail(
			failures,
			"wound_merge: expected 1 injury row for same sub_region got %d"
			% ent.wounds.get("head", []).size()
		)


static func _run_medical_phase_losing_side_stays_fled(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var enemy_c: Dictionary = mgr.combatants[1]
	enemy_c["combat_absent"] = true
	enemy_c.state = CombatConstants.STATE_FLED
	mgr._end_combat_phase("player", null)
	if not bool(enemy_c.get("combat_absent", false)):
		CombatRegressionHarness._fail(failures, "med_phase_rout: enemy combat_absent should stay set")
	if _EntityAccess.state_str(enemy_c) != CombatConstants.STATE_FLED:
		CombatRegressionHarness._fail(failures, "med_phase_rout: enemy should remain STATE_FLED")
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_coordination_stack_assist_during_windup(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
	var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
	var patient: Node = CombatRegressionHarness._new_entity("SWORD")
	patient.take_damage_split(12.0, 4.0, "left_arm")
	mgr.register(healer_a, "player")
	mgr.register(healer_b, "player")
	mgr.register(patient, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var ha: Dictionary = mgr.combatants[0]
	var hb: Dictionary = mgr.combatants[1]
	var pt: Dictionary = mgr.combatants[2]
	var hb_id: int = _EntityAccess.id_int(hb)
	var pt_id: int = _EntityAccess.id_int(pt)
	if not patient.apply_direct_pressure_from_ally("left_arm", healer_a):
		CombatRegressionHarness._fail(failures, "med_coord_assist: primary pressure setup failed")
		CombatRegressionHarness._free_manager(mgr)
		return
	ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
	ha.pending_medical = {
		"medical_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET,
		"target_part": "left_arm",
		"target_combatant_id": pt_id,
	}
	if not _MedicalCoord.can_stack_assist_pressure(mgr, hb_id, pt_id, "left_arm"):
		CombatRegressionHarness._fail(failures, "med_coord_assist: B should stack-assist while A holds during wind-up")
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, hb, pt, "left_arm")
	var has_assist_pressure: bool = false
	for raw in acts:
		if raw is Dictionary and CombatConstants.is_direct_pressure_move(
			str((raw as Dictionary).get("move_id", ""))
		):
			has_assist_pressure = true
	if not has_assist_pressure:
		CombatRegressionHarness._fail(failures, "med_coord_assist: listing should offer stack-assist pressure")
	var pick_pool: Array = [
		{
			"target_id": pt_id,
			"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
			"target_part": "left_arm",
		}
	]
	var filtered: Array = _MedicalCoord.filter_actions_for_pick(mgr, hb_id, pick_pool)
	if filtered.is_empty():
		CombatRegressionHarness._fail(failures, "med_coord_assist: filtered pick pool should include assist pressure")
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_coordination_blocks_overlapping_treatment(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
	var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
	var patient: Node = CombatRegressionHarness._new_entity("SWORD")
	patient.take_damage_split(14.0, 5.0, "left_arm")
	mgr.register(healer_a, "player")
	mgr.register(healer_b, "player")
	mgr.register(patient, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var ha: Dictionary = mgr.combatants[0]
	var hb: Dictionary = mgr.combatants[1]
	var pt: Dictionary = mgr.combatants[2]
	var hb_id: int = _EntityAccess.id_int(hb)
	var pt_id: int = _EntityAccess.id_int(pt)
	ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
	ha.state_duration = 8.0
	ha.pending_medical = {
		"medical_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET,
		"target_part": "left_arm",
		"target_combatant_id": pt_id,
	}
	if _MedicalCoord.medical_action_allowed(
		mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_TOURNIQUET
	):
		CombatRegressionHarness._fail(failures, "med_coord: second medic must not start tourniquet during ally wind-up")
	if _MedicalCoord.medical_action_allowed(
		mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
	):
		CombatRegressionHarness._fail(failures, "med_coord: second medic must not replace pressure during ally wind-up")
	var acts_overlap: Array = _MedicalPhase.get_ally_medical_actions(mgr, hb, pt, "left_arm")
	for raw in acts_overlap:
		if raw is not Dictionary:
			continue
		var mid: String = str((raw as Dictionary).get("move_id", ""))
		if (
			CombatConstants.is_tourniquet_move(mid)
			or CombatConstants.is_direct_pressure_move(mid)
		):
			CombatRegressionHarness._fail(
				failures,
				"med_coord: listing must omit overlap moves during wind-up got %s" % mid
			)
	if not patient.apply_direct_pressure_from_ally("left_arm", healer_a):
		CombatRegressionHarness._fail(failures, "med_coord: setup ally pressure failed")
		CombatRegressionHarness._free_manager(mgr)
		return
	ha.state = CombatConstants.STATE_WAITING
	ha.pending_medical = {}
	if not _MedicalCoord.can_stack_assist_pressure(mgr, hb_id, pt_id, "left_arm"):
		CombatRegressionHarness._fail(failures, "med_coord: B should stack-assist when A holds compression")
	if not _MedicalCoord.medical_action_allowed(
		mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
	):
		CombatRegressionHarness._fail(failures, "med_coord: stack-assist pressure should be allowed")
	var acts_held: Array = _MedicalPhase.get_ally_medical_actions(mgr, hb, pt, "left_arm")
	var assist_listed: bool = false
	for raw2 in acts_held:
		if raw2 is Dictionary and CombatConstants.is_direct_pressure_move(
			str((raw2 as Dictionary).get("move_id", ""))
		):
			assist_listed = true
	if not assist_listed:
		CombatRegressionHarness._fail(failures, "med_coord: listing should offer stack-assist direct_pressure")
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_windup_prepare_preserves_ally_head_pressure(failures: PackedStringArray) -> void:
	var patient: Node = CombatRegressionHarness._new_entity("SWORD")
	var ally: Node = CombatRegressionHarness._new_entity("SWORD")
	patient.take_damage_split(8.0, 3.0, "head")
	if not patient.wounds.has("head"):
		CombatRegressionHarness._fail(failures, "windup_prepare: need head wound")
		return
	if not patient.apply_direct_pressure_from_ally("head", ally):
		CombatRegressionHarness._fail(failures, "windup_prepare: ally pressure failed")
		return
	var held: float = _EntityWounds.get_bleeding_rate_for_part(patient, "head")
	if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
		CombatRegressionHarness._fail(failures, "windup_prepare: ally hold not registered")
		return
	_EntityMedical.prepare_for_medical_windup(patient, patient, "head")
	if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
		CombatRegressionHarness._fail(failures, "windup_prepare: ally hold cleared on treatment part")
		return
	var after: float = _EntityWounds.get_bleeding_rate_for_part(patient, "head")
	if after > held + _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(
			failures,
			"windup_prepare: rebound during prepare held=%.3f after=%.3f" % [held, after]
		)


static func _run_ally_medical_tourniquet_path_pressure_first(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(12.0, 4.0, "right_leg")
	var mgr: Node = _MgrScript.new()
	var healer: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(healer, "player")
	mgr.register(ent, "player")
	var healer_c: Dictionary = mgr.combatants[0]
	var ally_c: Dictionary = mgr.combatants[1]
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, healer_c, ally_c, "right_leg")
	CombatRegressionHarness._free_manager(mgr)
	if acts.is_empty():
		CombatRegressionHarness._fail(failures, "tq_path: expected actions on bleeding leg")
		return
	var mids: Array = []
	for raw in acts:
		if raw is Dictionary:
			mids.append(str((raw as Dictionary).get("move_id", "")))
	if CombatConstants.MOVE_ID_APPLY_TOURNIQUET not in mids:
		CombatRegressionHarness._fail(failures, "tq_path: expected tourniquet on severe leg bleed")
	if CombatConstants.MOVE_ID_BANDAGE_SELF in mids or CombatConstants.MOVE_ID_PACK_WOUND in mids:
		CombatRegressionHarness._fail(failures, "tq_path: should not list bandage/pack before tourniquet path")


## Winner locked after `enemies_eliminated`: party bleed-out during triage must not flip to enemy `combat_ended`.
static func _run_medical_phase_winner_locked_on_party_bleed_out(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._end_combat_phase("player", _EntityAccess.scene_node(mgr.combatants[2]))
	if not mgr.medical_phase or mgr.medical_phase_winner != "player":
		CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: expected player medical phase after victory")
		CombatRegressionHarness._free_manager(mgr)
		return
	if not _MedicalPhase.should_apply_phase_end(mgr, "enemy"):
		pass
	else:
		CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: enemy victor should be blocked")
	var ended_box: Array = [0]
	mgr.combat_ended.connect(
		func(_w: String, _d: Node) -> void:
			ended_box[0] = int(ended_box[0]) + 1
	)
	var p0: Dictionary = mgr.combatants[0]
	var p_ent: Node = _EntityAccess.get_entity_from_manager(mgr, p0)
	if p_ent == null:
		CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: missing player entity")
		CombatRegressionHarness._free_manager(mgr)
		return
	p_ent.blood_volume = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
	p0.alive = true
	mgr.set_process(true)
	_ProcessTick.tick(mgr, 0.05)
	if int(ended_box[0]) != 0:
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_winner_lock: combat_ended must not fire on party bleed-out (count=%d)"
			% int(ended_box[0])
		)
	if not mgr.medical_phase or mgr.medical_phase_winner != "player":
		CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: medical phase should persist")
	if not _EntityAccess.is_dead(p0):
		CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: expected player marked dead on entity")
	CombatRegressionHarness._free_manager(mgr)


## Locked phase-end must not abort the rest of the tick (e.g. ally medical wind-up still advances).
static func _run_medical_phase_tick_continues_after_locked_bleed_out(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var medic_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(medic_ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._end_combat_phase("player", _EntityAccess.scene_node(mgr.combatants[2]))
	var casualty: Dictionary = mgr.combatants[0]
	var medic: Dictionary = mgr.combatants[1]
	var cas_ent: Node = _EntityAccess.get_entity_from_manager(mgr, casualty)
	if cas_ent == null:
		CombatRegressionHarness._fail(failures, "medical_phase_tick_continue: missing casualty entity")
		CombatRegressionHarness._free_manager(mgr)
		return
	cas_ent.blood_volume = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
	casualty.alive = true
	medic.state = CombatConstants.STATE_MEDICAL_WIND_UP
	medic.state_timer = 0.0
	medic.state_duration = 2.0
	medic.pending_medical = {
		"medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
		"target_part": "chest",
		"target_combatant_id": _EntityAccess.id_int(medic),
	}
	mgr.set_process(true)
	_ProcessTick.tick(mgr, 0.25)
	if _EntityAccess.state_str(medic) != CombatConstants.STATE_MEDICAL_WIND_UP:
		CombatRegressionHarness._fail(
			failures,
			"medical_phase_tick_continue: medic wind-up should advance (state=%s timer=%.2f)"
			% [_EntityAccess.state_str(medic), float(medic.get("state_timer", 0.0))]
		)
	elif float(medic.get("state_timer", 0.0)) < 0.01:
		CombatRegressionHarness._fail(failures, "medical_phase_tick_continue: medic state_timer should advance after tick")
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_phase_full_blood_loss_rate(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "chest")
	ent.blood_volume = 60.0
	var rate: float = _EntityWounds.get_total_bleeding_rate(ent)
	if rate <= 0.0:
		CombatRegressionHarness._fail(failures, "med_phase_bleed: need active bleed")
		return
	ent.set_combat_blood_loss_mult(1.0)
	ent.set_combat_blood_recovery_per_s(0.0)
	ent.process_blood_loss(1.0)
	var loss: float = 60.0 - ent.blood_volume
	var want: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER * 1.0
	if absf(loss - want) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"med_phase_bleed: expect full ATLS drain rate got loss=%.4f want≈%.4f" % [loss, want]
		)
	# No passive recovery without fluids (post-victory medical phase uses same physiology).
	ent.blood_volume = 55.0
	ent.set_combat_blood_recovery_per_s(0.06)
	ent.process_blood_loss(1.0)
	if ent.blood_volume > 55.01:
		CombatRegressionHarness._fail(failures, "med_phase_bleed: passive recovery should not run without explicit treatment")


static func _run_pack_wound_apply_packing_marks_packed_parts(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	seed(88202)
	var ok: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not ok:
		CombatRegressionHarness._fail(failures, "pack_wound_apply: apply_packing should succeed with high effectiveness")
	if not bool(ent.packed_parts.get("chest", false)):
		CombatRegressionHarness._fail(failures, "pack_wound_apply: packed_parts[chest] should be set")


static func _run_pack_wound_windup_complete_packed_outcome(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ally_ent, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var ally_id: int = _EntityAccess.id_int(ally)
	var ally_node: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	_harness_wound_chest_for_packing(ally_node)
	if ally_node.is_dead():
		CombatRegressionHarness._fail(failures, "pack_wound_windup: harness wound must not kill ally")
		CombatRegressionHarness._free_manager(mgr)
		return
	healer.state = CombatConstants.STATE_MEDICAL_WIND_UP
	healer.state_duration = 2.0
	healer.pending_medical = {
		"medical_id": CombatConstants.MOVE_ID_PACK_WOUND,
		"target_part": "chest",
		"target_combatant_id": ally_id,
	}
	seed(88203)
	var outcome_box: Array = [""]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, r: Dictionary) -> void:
			outcome_box[0] = str(r.get("outcome", ""))
	)
	_MedicalWindUp.complete(mgr, healer, healer.pending_medical)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	CombatRegressionHarness._free_manager(mgr)
	if str(outcome_box[0]) != "packed" and str(outcome_box[0]) != "packing_failed":
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_windup: want packed or packing_failed got '%s'" % str(outcome_box[0])
		)
	if str(outcome_box[0]) == "packed" and not bool(ally_node.packed_parts.get("chest", false)):
		CombatRegressionHarness._fail(failures, "pack_wound_windup: packed outcome should set packed_parts")


static func _run_instant_complete_finishes_in_progress_bandage(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ally_ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_harness_wound_chest_for_packing(ally_ent)
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally: Dictionary = mgr.combatants[1]
	var ally_id: int = _EntityAccess.id_int(ally)
	if not _EntityAccess.entity_apply_direct_pressure_from_ally(mgr, ally, mgr.combatants[0], "chest"):
		CombatRegressionHarness._fail(failures, "instant_complete_bandage: ally pressure setup failed")
		CombatRegressionHarness._free_manager(mgr)
		return
	_MedicalActionStarter.start(
		mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest"
	)
	if _EntityAccess.state_str(mgr.combatants[0]) != CombatConstants.STATE_MEDICAL_WIND_UP:
		CombatRegressionHarness._fail(failures, "instant_complete_bandage: expected medical wind-up")
		CombatRegressionHarness._free_manager(mgr)
		return
	var clock_before: float = float(mgr.combat_clock)
	seed(88204)
	_MedicalPhase.instant_complete_on_early_exit(mgr)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if float(mgr.combat_clock) <= clock_before:
		CombatRegressionHarness._fail(
			failures, "instant_complete_bandage: fast-forward should advance combat_clock"
		)
	if _EntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_MEDICAL_WIND_UP:
		CombatRegressionHarness._fail(
			failures, "instant_complete_bandage: wind-up should finish via simulated time, not stay active"
		)
	if not bool(ally_ent.bandaged_parts.get("chest", false)):
		CombatRegressionHarness._fail(
			failures, "instant_complete_bandage: ally chest should be bandaged after instant complete"
		)
	CombatRegressionHarness._free_manager(mgr)


## Turn-ready winner with untreated wounds is still triage-active (not "paused").
static func _run_winner_side_triage_busy_turn_ready_pending(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
	wounded.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
	mgr.register(wounded, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	mgr.combatants[0]["state"] = CombatConstants.STATE_WAITING
	mgr.combatants[0]["gauge"] = 100.0
	if not _MedicalPhase.winner_side_triage_busy(mgr):
		CombatRegressionHarness._fail(
			failures,
			"winner_triage_busy: turn-ready with untreated wounds should stay busy"
		)
	CombatRegressionHarness._free_manager(mgr)


## Gauge fill and triage-complete idle both clear busy.
static func _run_winner_side_triage_busy_gauge_and_complete(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	mgr.combatants[0]["state"] = CombatConstants.STATE_WAITING
	mgr.combatants[0]["gauge"] = 40.0
	if not _MedicalPhase.winner_side_triage_busy(mgr):
		CombatRegressionHarness._fail(
			failures, "winner_triage_busy: partial gauge should count as busy"
		)
	mgr.combatants[0]["gauge"] = 100.0
	if _MedicalPhase.winner_side_triage_busy(mgr):
		CombatRegressionHarness._fail(
			failures, "winner_triage_busy: triage complete at 100%% should not be busy"
		)
	CombatRegressionHarness._free_manager(mgr)


## Contract finish_battle logs campaign_medical_exit and refreshes camp supplement after an earlier medical flush.
static func _run_finish_battle_campaign_medical_exit_refreshes_camp(
	failures: PackedStringArray
) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_F5SoakTrace.set_fight_profile("7v7")
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("harness", "", false, true)
	CombatF5SoakTrace.log_fight_end_summary("player", true)
	_F5SoakTrace.note_medical_pack_listed("Leader", "chest")
	var world: Node2D = Node2D.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var battle: Node = _BattleScene.new()
	battle.parent_scene = world
	var mgr: Node = _MgrScript.new()
	battle.add_child(mgr)
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	mgr.finish_battle()
	var exit_log: int = 0
	var camp_med_pass: int = 0
	for raw in _OperationalLog.get_captured_lines():
		var body: String = str(raw).strip_edges()
		if body.begins_with(_OperationalLog.TAG_COMBAT + ":"):
			body = body.substr(_OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
		if body.begins_with("campaign_medical_exit"):
			exit_log += 1
		if body.begins_with("soak_coverage camp pass [camp_medical_exit]"):
			camp_med_pass += 1
	_OperationalLog.end_play_session()
	CombatRegressionHarness._free_manager(mgr)
	battle.free()
	world.free()
	if exit_log != 1:
		CombatRegressionHarness._fail(
			failures,
			"finish_battle_camp_exit: want 1 campaign_medical_exit log got %d" % exit_log
		)
	if camp_med_pass < 1:
		CombatRegressionHarness._fail(
			failures,
			"finish_battle_camp_exit: want camp_medical_exit supplement pass got %d" % camp_med_pass
		)


## F5: finish_battle after deferred medical must flush soak_coverage (no medical picks required).
static func _run_finish_battle_flushes_deferred_soak_coverage(
	failures: PackedStringArray
) -> void:
	_F5SoakTrace.prepare_fight_end_log()
	_F5SoakTrace.set_fight_profile("7v7")
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("harness", "", false, true)
	_F5SoakTrace.log_fight_end_summary("player", true)
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	mgr.finish_battle()
	var cov_ok: int = 0
	for raw in _OperationalLog.get_captured_lines():
		var body: String = str(raw).strip_edges()
		var fp_tag: String = "FP_COMBAT:"
		var fp_idx: int = body.find(fp_tag)
		if fp_idx >= 0:
			body = body.substr(fp_idx + fp_tag.length()).strip_edges()
		if body.begins_with("soak_coverage ok="):
			cov_ok += 1
	_OperationalLog.end_play_session()
	CombatRegressionHarness._free_manager(mgr)
	if cov_ok != 1:
		CombatRegressionHarness._fail(
			failures,
			"finish_battle_deferred_cov: want 1 soak_coverage ok= after early exit got %d"
			% cov_ok
		)


## Campaign-only: incomplete fast-forward warning must not fire on soak / dev fights.
static func _run_finish_battle_incomplete_hint_campaign_only(failures: PackedStringArray) -> void:
	_OperationalLog.end_play_session()
	var mgr: Node = _MgrScript.new()
	var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
	wounded.wounds["chest"] = [{"current_bleeding_rate": 0.8, "severity": "moderate"}]
	mgr.register(wounded, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var hints: Array = []
	mgr.combat_ui_hint.connect(func(m: String) -> void: hints.append(m))
	mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
	if not hints.is_empty():
		CombatRegressionHarness._fail(
			failures,
			"finish_battle_incomplete_hint: soak fight should not emit campaign hint got %s"
			% str(hints)
		)
	var world: Node2D = Node2D.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var battle: Node = _BattleScene.new()
	battle.parent_scene = world
	battle.add_child(mgr)
	hints.clear()
	mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
	if hints.is_empty():
		CombatRegressionHarness._fail(
			failures, "finish_battle_incomplete_hint: campaign fight should emit incomplete hint"
		)
	elif str(hints[0]) != _BattleUIConstants.CAMPAIGN_MEDICAL_FAST_FORWARD_INCOMPLETE_HINT:
		CombatRegressionHarness._fail(
			failures,
			"finish_battle_incomplete_hint: want campaign incomplete copy got '%s'" % str(hints[0])
		)
	_OperationalLog.begin_play_session("headless://incomplete_ff_parts", "", false, false)
	_OperationalLog.set_capture_enabled(true)
	hints.clear()
	mgr.call("_notify_incomplete_campaign_medical_fast_forward_if_needed")
	var world_logged: bool = false
	for line in _OperationalLog.get_captured_lines():
		if str(line).contains("parts_left=1"):
			world_logged = true
			break
	_OperationalLog.set_capture_enabled(false)
	_OperationalLog.end_play_session()
	if not world_logged:
		CombatRegressionHarness._fail(
			failures, "finish_battle_incomplete_hint: world log should include parts_left count"
		)
	CombatRegressionHarness._free_manager(mgr)
	battle.free()
	world.free()


static func _run_finish_battle_instant_completes_medical_windup(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
	mgr.register(ally_ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	_harness_wound_chest_for_packing(ally_ent)
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally_id: int = _EntityAccess.id_int(mgr.combatants[1])
	if not _EntityAccess.entity_apply_direct_pressure_from_ally(
		mgr, mgr.combatants[1], mgr.combatants[0], "chest"
	):
		CombatRegressionHarness._fail(failures, "finish_battle_instant: ally pressure setup failed")
		CombatRegressionHarness._free_manager(mgr)
		return
	_MedicalActionStarter.start(
		mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest"
	)
	seed(88205)
	mgr.finish_battle()
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not bool(ally_ent.bandaged_parts.get("chest", false)):
		CombatRegressionHarness._fail(
			failures, "finish_battle_instant: ally chest should be bandaged after finish_battle"
		)
	if bool(mgr.medical_phase):
		CombatRegressionHarness._fail(failures, "finish_battle_instant: medical_phase should clear on stop")
	CombatRegressionHarness._free_manager(mgr)


static func _run_combat_log_formatter_pack_ally_label(failures: PackedStringArray) -> void:
	var line: String = _CombatLogFormatter.format_action_line(
		"Healer",
		"player",
		"Ally",
		"player",
		{
			"outcome": "packed",
			"part": "chest",
			"effectiveness": 1.0,
			"medical_move_id": CombatConstants.MOVE_ID_PACK_WOUND,
			"medical_target_is_self": false,
		}
	)
	if not line.contains("pack wound (ally)"):
		CombatRegressionHarness._fail(failures, "pack_ally_log: want pack wound (ally) got '%s'" % line)

## Fast medical-phase halt subset — **`FP_HARNESS_MODE=medical`** (full suite: `run()`).
static func run_fast_phase_halt_checks(failures: PackedStringArray) -> void:
	_run_medical_phase_cancels_pending_enemy_melee(failures)
	_run_medical_phase_blocks_afterblow_on_loser(failures)
	_run_medical_phase_blocks_scheduled_enemy_events(failures)
	_run_medical_phase_teardown_cancels_formation_resolve(failures)
	_run_medical_phase_purge_queue_and_windup_blocked(failures)
	_run_medical_phase_skip_turn_silent_for_loser(failures)
	_run_medical_phase_winner_combat_resolve_blocked(failures)
	_run_medical_phase_winner_listing_medical_only(failures)
	_run_medical_phase_winner_locked_on_party_bleed_out(failures)
	_run_medical_phase_apply_result_blocked(failures)
	_run_medical_phase_end_combat_idempotent(failures)
	CombatRegressionHarness._run_combat_end_enemy_win_stops_manager(failures)


static func run(failures: PackedStringArray) -> void:
	_run_medical_phase_cancels_pending_enemy_melee(failures)
	_run_medical_phase_blocks_afterblow_on_loser(failures)
	_run_medical_phase_blocks_scheduled_enemy_events(failures)
	_run_medical_phase_teardown_cancels_formation_resolve(failures)
	_run_medical_phase_purge_queue_and_windup_blocked(failures)
	_run_medical_phase_skip_turn_silent_for_loser(failures)
	_run_medical_phase_winner_combat_resolve_blocked(failures)
	_run_medical_phase_winner_listing_medical_only(failures)
	_run_medical_phase_apply_result_blocked(failures)
	_run_medical_phase_end_combat_idempotent(failures)
	_run_medical_phase_winner_locked_on_party_bleed_out(failures)
	_run_medical_phase_tick_continues_after_locked_bleed_out(failures)
	_run_medical_phase_winner_fled_suspends_bleed_tick(failures)
	_run_medical_phase_fled_winner_bleed_suspended_on_tick(failures)
	_run_medical_phase_non_fled_winner_bleed_continues_on_tick(failures)
	_run_medical_phase_stop_clears_suspend_bleed_tick(failures)
	_run_combat_log_formatter_bandage_ally_label(failures)
	_run_pack_wound_strict_subregion_eligibility(failures)
	_run_pack_wound_can_apply_on_chest_wound(failures)
	_run_pack_wound_blocked_when_already_packed(failures)
	_run_pack_wound_lists_in_medical_phase(failures)
	_run_pack_wound_apply_packing_marks_packed_parts(failures)
	_run_pack_wound_windup_complete_packed_outcome(failures)
	_run_instant_complete_finishes_in_progress_bandage(failures)
	_run_winner_side_triage_busy_turn_ready_pending(failures)
	_run_winner_side_triage_busy_gauge_and_complete(failures)
	_run_finish_battle_flushes_deferred_soak_coverage(failures)
	_run_finish_battle_campaign_medical_exit_refreshes_camp(failures)
	_run_finish_battle_incomplete_hint_campaign_only(failures)
	_run_finish_battle_instant_completes_medical_windup(failures)
	_run_bandage_allowed_on_packed_part(failures)
	_run_direct_pressure_held_suppresses_bleed_rate(failures)
	_run_direct_pressure_release_rebleeds_without_dressing(failures)
	_run_medical_windup_prepare_preserves_ally_head_pressure(failures)
	_run_medical_coordination_blocks_overlapping_treatment(failures)
	_run_medical_coordination_stack_assist_during_windup(failures)
	_run_treatment_channel_count_not_raw_hit_count(failures)
	_run_failed_dressing_retains_direct_pressure(failures)
	_run_dressings_blocked_without_pressure_when_bleeding(failures)
	_run_dressings_still_offered_after_failure_out_of_peril(failures)
	_run_pending_retry_set_even_with_other_medics(failures)
	_run_medical_ai_prefers_dressing_over_stabilize_out_of_peril(failures)
	_run_entity_untreated_matches_bridge(failures)
	_run_pressure_held_until_dressed(failures)
	_run_wound_merge_same_subregion(failures)
	_run_medical_phase_losing_side_stays_fled(failures)
	_run_ally_medical_tourniquet_path_pressure_first(failures)
	_run_medical_phase_full_blood_loss_rate(failures)
	_run_combat_log_formatter_pack_ally_label(failures)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	_F5SoakTrace.prepare_fight_end_log()
