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
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _ResearchAnchors := preload("res://core/CombatResearchAnchors.gd")
const _PartyRowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _EntityPainConsciousness := preload("res://core/EntityPainConsciousness.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")


static func _free_entity_fixture(n: Node) -> void:
	CombatRegressionHarness._free_harness_node(n)


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


## Hold compression when fixture still bleeds so dress/pack gates match TCCC production paths.
static func _harness_hold_pressure_if_bleeding(ent: Node, part: String) -> void:
	if ent == null or part.is_empty():
		return
	if _EntityWounds.get_bleeding_rate_for_part(ent, part) <= _Bleeding.BLEEDING_RATE_EPSILON:
		return
	if _EntityMedical.has_direct_pressure_on_part(ent, part):
		return
	if not ent.apply_direct_pressure(part):
		push_warning("harness: could not hold pressure on %s for dressing fixture" % part)


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
	_harness_hold_pressure_if_bleeding(ent, "head")
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
	_harness_hold_pressure_if_bleeding(ent, "head")
	if not ent.can_apply_packing("head"):
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_strict: severe neck should allow packing when linen ok"
		)
	_free_entity_fixture(ent)


static func _run_pack_wound_can_apply_on_chest_wound(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	_harness_hold_pressure_if_bleeding(ent, "chest")
	if not ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(failures, "pack_wound_can: chest wound should allow packing")
	if ent.can_apply_packing("left_arm"):
		CombatRegressionHarness._fail(failures, "pack_wound_can: left_arm not a packing part")
	_free_entity_fixture(ent)


static func _run_pack_wound_blocked_when_already_packed(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	_harness_hold_pressure_if_bleeding(ent, "chest")
	seed(88201)
	var ok: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not ok:
		CombatRegressionHarness._fail(failures, "pack_wound_packed: setup apply_packing should succeed")
	if ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(failures, "pack_wound_packed: should not pack twice")
	_free_entity_fixture(ent)


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
	_harness_hold_pressure_if_bleeding(ent, "chest")
	seed(88203)
	var packed: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not packed:
		CombatRegressionHarness._fail(failures, "bandage_packed: setup packing should succeed")
	if not ent.can_apply_bandage("chest"):
		CombatRegressionHarness._fail(failures, "bandage_packed: should allow outer bandage over pack")
	_free_entity_fixture(ent)


static func _run_direct_pressure_held_suppresses_bleed_rate(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "right_arm")
	if not ent.wounds.has("right_arm"):
		CombatRegressionHarness._fail(failures, "direct_pressure_held: need arm wound")
		_free_entity_fixture(ent)
		return
	# Venous compressible bleed: arterial retained-flow (~50%) is intentionally weaker than this gate.
	for injury in ent.wounds["right_arm"]:
		injury["is_arterial"] = false
		injury["current_bleeding_rate"] = float(injury.get("base_bleeding_rate", injury.get("current_bleeding_rate", 0.0)))
	var raw: float = _EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
	if raw <= _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(failures, "direct_pressure_held: wound should bleed before pressure")
		_free_entity_fixture(ent)
		return
	if not ent.apply_direct_pressure("right_arm"):
		CombatRegressionHarness._fail(failures, "direct_pressure_held: apply_direct_pressure failed")
		_free_entity_fixture(ent)
		return
	var held: float = _EntityWounds.get_bleeding_rate_for_part(ent, "right_arm")
	if held >= raw * 0.4:
		CombatRegressionHarness._fail(failures, "direct_pressure_held: expected strong suppression while held got raw=%.3f held=%.3f" % [raw, held])
	_free_entity_fixture(ent)


static func _run_direct_pressure_release_rebleeds_without_dressing(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "left_leg")
	if not ent.wounds.has("left_leg"):
		CombatRegressionHarness._fail(failures, "direct_pressure_rebound: need leg wound")
		_free_entity_fixture(ent)
		return
	ent.apply_direct_pressure("left_leg")
	var held: float = _EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
	_EntityMedical.release_direct_pressure_on_part(ent, "left_leg")
	var after: float = _EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
	if after <= held + _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(failures, "direct_pressure_rebound: expected higher bleed after early release")
	_free_entity_fixture(ent)


## III-5: multi-channel cavity pack scales success by **`PACKING_SUCCESS_PER_EXTRA_CHANNEL`** (depth / complexity).
static func _run_iii5_packing_channel_success_depth(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.linen_strips_remaining = _Bleeding.PACKING_LINEN_PARTY_START
	_EntityWounds.add_wound(
		ent, "chest", _Bleeding.INJURY_TYPE_CUT, 8.0, "upper_thorax", _Bleeding.SEVERITY_MODERATE
	)
	_EntityWounds.add_wound(
		ent, "chest", _Bleeding.INJURY_TYPE_CUT, 8.0, "lower_thorax", _Bleeding.SEVERITY_MODERATE
	)
	var channels: int = _EntityMedical.get_treatment_channel_count(ent, "chest")
	if channels < 2:
		CombatRegressionHarness._fail(
			failures, "iii5_pack_depth: want 2+ treatment channels got %d" % channels
		)
		_free_entity_fixture(ent)
		return
	var mult: float = _EntityMedical.packing_channel_success_mult(ent, "chest")
	var want: float = pow(_Bleeding.PACKING_SUCCESS_PER_EXTRA_CHANNEL, float(channels - 1))
	if absf(mult - want) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"iii5_pack_depth: want mult=%.3f got %.3f (channels=%d)"
			% [want, mult, channels]
		)
	_free_entity_fixture(ent)


static func _run_treatment_channel_count_not_raw_hit_count(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	for _i in 6:
		_EntityWounds.add_wound(
			ent, "head", _Bleeding.INJURY_TYPE_CUT, 2.0, "scalp", _Bleeding.SEVERITY_MODERATE
		)
	if ent.wounds.get("head", []).size() != 1:
		CombatRegressionHarness._fail(failures, "treatment_channels: merge should leave one injury row")
		_free_entity_fixture(ent)
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
	_free_entity_fixture(ent)


static func _run_failed_dressing_retains_direct_pressure(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{"current_bleeding_rate": 0.6, "severity": "moderate"},
	]
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "failed_dressing_retain: pressure setup failed")
		_free_entity_fixture(ent)
		return
	if ent.apply_bandage("chest", 0.0):
		CombatRegressionHarness._fail(failures, "failed_dressing_retain: zero-eff bandage should fail")
		_free_entity_fixture(ent)
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
		_free_entity_fixture(ent)
		return
	if not _EntityMedical.has_direct_pressure_on_part(ent, "chest"):
		CombatRegressionHarness._fail(
			failures, "failed_dressing_retain: failed packing must keep direct pressure"
		)
	_free_entity_fixture(ent)


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
	_free_entity_fixture(ent)
	_free_entity_fixture(open)


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
	_free_entity_fixture(ent)


## Field care: one procedure step advances sim bleed time (150 s), not UI label (120 s).
static func _run_field_care_procedure_sim_advance_seconds(failures: PackedStringArray) -> void:
	var want: float = _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
	if not is_equal_approx(want, 150.0):
		CombatRegressionHarness._fail(
			failures,
			"field_care_sim: FIELD_CARE_SIM_ADVANCE_SECONDS want 150 got %.1f" % want
		)
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.12,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("chest")
	var bleed_before: float = _EntityWounds.get_bleeding_rate_for_part(ent, "chest")
	_EntityTimeAdvance.advance(ent, want, false)
	var bleed_after: float = _EntityWounds.get_bleeding_rate_for_part(ent, "chest")
	if bleed_after >= bleed_before - 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"field_care_sim: procedure advance should reduce bleed under pressure got %.4f→%.4f"
			% [bleed_before, bleed_after]
		)
	_free_entity_fixture(ent)


## LIVE_PATHS §1: moderate venous may reach local hemostasis under sustained pressure over field-care window.
static func _run_field_care_venous_clot_under_procedure(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["left_leg"] = [
		{
			"current_bleeding_rate": 0.08,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	if not ent.apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(
			failures, "field_care_venous_clot: apply_direct_pressure failed (need free hand for leg hold)"
		)
		_free_entity_fixture(ent)
		return
	_EntityTimeAdvance.advance(ent, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var rate: float = _EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
	if rate > _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(
			failures,
			"field_care_venous_clot: moderate venous should clot under procedure pressure got rate=%.4f"
			% rate
		)
	if ent.self_direct_pressure_part != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"field_care_venous_clot: TCCC hold should stay until dressed (part=%s)"
			% ent.self_direct_pressure_part
		)
	_free_entity_fixture(ent)


## Arterial rates stay lethal under compression until dressed (pressure alone over one procedure).
static func _run_field_care_arterial_stays_lethal_under_procedure(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.8,
			"base_bleeding_rate": 2.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": true,
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("chest")
	_EntityTimeAdvance.advance(ent, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var rate: float = _EntityWounds.get_bleeding_rate_for_part(ent, "chest")
	if rate <= _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(
			failures,
			"field_care_arterial: arterial should stay bleeding after one procedure got rate=%.4f"
			% rate
		)
	_free_entity_fixture(ent)


## Controlled moderate venous field procedure: blood volume stays ATLS class II+ (70% remaining).
static func _run_field_care_venous_blood_loss_bounded(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	ent.wounds["left_leg"] = [
		{
			"current_bleeding_rate": 0.08,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("left_leg")
	_EntityTimeAdvance.advance(ent, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	if float(ent.blood_volume) < 70.0:
		CombatRegressionHarness._fail(
			failures,
			"field_care_blood_loss: controlled venous procedure should stay ATLS II+ got bv=%.1f"
			% float(ent.blood_volume)
		)
	_free_entity_fixture(ent)


## TCCC: venous ~10% / arterial ~50% flow retained under sustained direct pressure (displayed bleed rate).
static func _run_direct_pressure_flow_retention_venous_vs_arterial_parity(
	failures: PackedStringArray
) -> void:
	const intrinsic: float = 0.4
	var venous: Node = CombatRegressionHarness._new_entity("SWORD")
	venous.wounds["left_leg"] = [
		{
			"current_bleeding_rate": intrinsic,
			"base_bleeding_rate": intrinsic,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
		},
	]
	if not venous.apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(failures, "pressure_flow: venous self-pressure setup failed")
		_free_entity_fixture(venous)
		return
	var venous_disp: float = _EntityWounds.get_bleeding_rate_for_part(venous, "left_leg")
	var post_venous: float = float(
		venous.wounds["left_leg"][0].get("current_bleeding_rate", 0.0)
	)
	var want_venous: float = (
		post_venous * _Bleeding.direct_pressure_held_flow_retained(false)
	)
	if not is_equal_approx(venous_disp, want_venous):
		CombatRegressionHarness._fail(
			failures,
			"pressure_flow: venous want %.4f got %.4f (post_pressure=%.4f)"
			% [want_venous, venous_disp, post_venous]
		)
	var arterial: Node = CombatRegressionHarness._new_entity("SWORD")
	arterial.wounds["chest"] = [
		{
			"current_bleeding_rate": intrinsic,
			"base_bleeding_rate": intrinsic,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": true,
		},
	]
	if not arterial.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "pressure_flow: arterial self-pressure setup failed")
		_free_entity_fixture(venous)
		_free_entity_fixture(arterial)
		return
	var arterial_disp: float = _EntityWounds.get_bleeding_rate_for_part(arterial, "chest")
	var post_arterial: float = float(
		arterial.wounds["chest"][0].get("current_bleeding_rate", 0.0)
	)
	var want_arterial: float = (
		post_arterial * _Bleeding.direct_pressure_held_flow_retained(true)
	)
	if not is_equal_approx(arterial_disp, want_arterial):
		CombatRegressionHarness._fail(
			failures,
			"pressure_flow: arterial want %.4f got %.4f (post_pressure=%.4f)"
			% [want_arterial, arterial_disp, post_arterial]
		)
	if arterial_disp <= venous_disp + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"pressure_flow: arterial should retain more flow than venous got art=%.4f ven=%.4f"
			% [arterial_disp, venous_disp]
		)
	_free_entity_fixture(venous)
	_free_entity_fixture(arterial)


## Camp-2.1 ↔ combat: active bleed blocks field bandage until compression; matches medical-phase dressings gate.
static func _run_field_care_pressure_before_bandage_parity(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.12,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_stabilized": false,
		},
	]
	var member: Dictionary = {"name": "Fielder", "node_ref": ent}
	if not _MapFieldCare.field_bandage_needs_pressure_first(member):
		CombatRegressionHarness._fail(
			failures, "field_pressure_first: active bleed without hold should wait on pressure"
		)
	if not _MapFieldCare.field_bandage_part_ready(member).is_empty():
		CombatRegressionHarness._fail(
			failures, "field_pressure_first: bandage-ready part should be empty until compressed"
		)
	var mgr: Node = _MgrScript.new()
	var healer_ent := CombatRegressionHarness._new_entity("SWORD")
	mgr.register(healer_ent, "player")
	mgr.register(ent, "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var ally_c: Dictionary = mgr.combatants[1]
	if _MedicalPhase.dressings_allowed_for_part(mgr, ally_c, "chest"):
		CombatRegressionHarness._fail(
			failures, "field_pressure_first: combat dressings should block until pressure on chest"
		)
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "field_pressure_first: apply_direct_pressure failed")
		CombatRegressionHarness._free_manager(mgr)
		_free_entity_fixture(ent)
		return
	if _MapFieldCare.field_bandage_needs_pressure_first(member):
		CombatRegressionHarness._fail(
			failures, "field_pressure_first: compression held should clear pressure-first wait"
		)
	if _MapFieldCare.field_bandage_part_ready(member) != "chest":
		CombatRegressionHarness._fail(
			failures,
			"field_pressure_first: want bandage-ready chest got '%s'"
			% _MapFieldCare.field_bandage_part_ready(member)
		)
	if not _MedicalPhase.dressings_allowed_for_part(mgr, ally_c, "chest"):
		CombatRegressionHarness._fail(
			failures, "field_pressure_first: combat dressings should allow after pressure held"
		)
	CombatRegressionHarness._free_manager(mgr)
	_free_entity_fixture(ent)


## EntityMedical production gate: bandage/pack blocked on active bleed without compression (all call sites).
static func _run_entity_medical_dressing_requires_compression_when_bleeding(
	failures: PackedStringArray
) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	if ent.can_apply_bandage("chest"):
		CombatRegressionHarness._fail(
			failures, "entity_dress_gate: bandage should require compression on active chest bleed"
		)
	if ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(
			failures, "entity_dress_gate: pack should require compression on active chest bleed"
		)
	_harness_hold_pressure_if_bleeding(ent, "chest")
	if not ent.can_apply_packing("chest"):
		CombatRegressionHarness._fail(
			failures, "entity_dress_gate: pack should be legal once compression is held"
		)
	_free_entity_fixture(ent)


## Camp-2.1 ↔ combat: junctional pack waits on compression like bandage.
static func _run_field_care_pressure_before_pack_parity(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	var member: Dictionary = {"name": "Fielder", "node_ref": ent}
	if not _MapFieldCare.field_pack_part_ready(member).is_empty():
		CombatRegressionHarness._fail(
			failures, "field_pack_gate: pack-ready part should be empty until compressed"
		)
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "field_pack_gate: pressure setup failed")
		_free_entity_fixture(ent)
		return
	if _MapFieldCare.field_pack_part_ready(member) != "chest":
		CombatRegressionHarness._fail(
			failures,
			"field_pack_gate: want pack-ready chest got '%s'"
			% _MapFieldCare.field_pack_part_ready(member)
		)
	_free_entity_fixture(ent)


## Stabilize-only success still counts as untreated (camp / bridge / field dress chain).
static func _run_stabilize_success_still_untreated_for_camp(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.35,
			"base_bleeding_rate": 0.8,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("chest")
	if not ent.apply_stabilize("chest", 1.5):
		CombatRegressionHarness._fail(failures, "stabilize_untreated: apply_stabilize should succeed")
		_free_entity_fixture(ent)
		return
	if not _EntityWounds.entity_has_untreated_wounds(ent):
		CombatRegressionHarness._fail(
			failures, "stabilize_untreated: stabilize-only must still block camp rest / travel dress"
		)
	_free_entity_fixture(ent)


## Failed pack keeps compression (TCCC retry path).
static func _run_failed_packing_retains_direct_pressure(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "failed_pack_retain: pressure setup failed")
		_free_entity_fixture(ent)
		return
	if ent.apply_packing("chest", 0.0):
		CombatRegressionHarness._fail(failures, "failed_pack_retain: zero-eff pack should fail")
	if not _EntityMedical.has_direct_pressure_on_part(ent, "chest"):
		CombatRegressionHarness._fail(
			failures, "failed_pack_retain: failed pack must keep direct pressure"
		)
	_free_entity_fixture(ent)


## Research anchor: severity clot half-life ordering + bandaged hemostasis band (60–300 s).
static func _run_research_anchor_clotting_half_life_physics(failures: PackedStringArray) -> void:
	if not _ResearchAnchors.clotting_half_life_ordering_ok():
		CombatRegressionHarness._fail(
			failures, "clot_anchor: minor<moderate<severe<critical half-life ordering failed"
		)
	var bandage_hl: float = _ResearchAnchors.bandage_clot_half_life_s()
	if bandage_hl < 60.0 or bandage_hl > 300.0:
		CombatRegressionHarness._fail(
			failures,
			"clot_anchor: bandage half-life want 60-300s got %.0fs"
			% bandage_hl
		)
	if not _ResearchAnchors.pressure_held_clot_half_life_in_literature_band():
		CombatRegressionHarness._fail(
			failures,
			"clot_anchor: pressure-held half-life want 10-180s and < bandage got press=%.0fs band=%.0fs"
			% [_ResearchAnchors.pressure_held_clot_half_life_s(), bandage_hl]
		)


## LIVE_PATHS bleeding physics: shipped reference bleed rate + BLOOD_LOSS_RATE_MULTIPLIER match research derivation.
static func _run_research_anchor_reference_bleed_derivation_parity(failures: PackedStringArray) -> void:
	var deriv: Dictionary = _ResearchAnchors.reference_bleed_rate_derivation()
	if not bool(deriv.get("matches_reference_const", false)):
		CombatRegressionHarness._fail(
			failures,
			"ref_bleed: product %.3f should match REFERENCE_UNCONTROLLED_BLEED_RATE %.3f"
			% [
				float(deriv.get("product_hp_per_s", 0.0)),
				_Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE,
			]
		)
	if not bool(deriv.get("multiplier_matches_derived", false)):
		CombatRegressionHarness._fail(
			failures,
			"ref_bleed: BLOOD_LOSS_RATE_MULTIPLIER should match derived TTD anchor (shipped=%.3f derived=%.3f)"
			% [
				float(deriv.get("shipped_blood_loss_multiplier", 0.0)),
				float(deriv.get("derived_blood_loss_multiplier", 0.0)),
			]
		)
	if not bool(deriv.get("ml_ttd_parity_ok", false)):
		CombatRegressionHarness._fail(failures, "ref_bleed: percent and mL TTD bridge should match")
	var ttd: float = float(deriv.get("clinical_ttd_s", 0.0))
	if ttd < 30.0 or ttd > 120.0:
		CombatRegressionHarness._fail(
			failures, "ref_bleed: clinical TTD %.1fs outside 30-120s band" % ttd
		)


## Reference uncontrolled bleed: danger/peril gates + PartyRowFormatter danger ETA match BleedingConstants TTD math.
static func _run_medical_triage_reference_bleed_peril_parity(failures: PackedStringArray) -> void:
	const ref_rate: float = _Bleeding.REFERENCE_UNCONTROLLED_BLEED_RATE
	var ref_ttd: float = _ResearchAnchors.clinical_ttd_seconds(1.0)
	if ref_ttd < 30.0 or ref_ttd > 120.0:
		CombatRegressionHarness._fail(
			failures, "triage_ref: reference TTD %.1fs outside 30-120s band" % ref_ttd
		)
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	ent.wounds["head"] = [
		{
			"current_bleeding_rate": ref_rate,
			"base_bleeding_rate": ref_rate,
			"severity": _Bleeding.SEVERITY_CRITICAL,
			"is_arterial": true,
			"is_stabilized": false,
		},
	]
	var mgr: Node = _MgrScript.new()
	mgr.register(ent, "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var fighter: Dictionary = mgr.combatants[0]
	if not _MedicalPhase.is_in_medical_danger(mgr, fighter):
		CombatRegressionHarness._fail(
			failures,
			"triage_ref: full blood reference bleed should be danger (TTD=%.1fs < danger_s=%.0f)"
			% [ref_ttd, _Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS]
		)
	if _MedicalPhase.is_in_immediate_peril(mgr, fighter):
		CombatRegressionHarness._fail(
			failures,
			"triage_ref: full blood reference bleed should not be peril yet (TTD=%.1f > peril_s=%.0f)"
			% [ref_ttd, _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS]
		)
	var loss_per_s: float = _Bleeding.blood_volume_loss_per_second(ref_rate, 1.0)
	var peril_bv: float = (
		_Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
		+ loss_per_s * _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS
	)
	ent.blood_volume = peril_bv
	if not _MedicalPhase.is_in_immediate_peril(mgr, fighter):
		CombatRegressionHarness._fail(
			failures,
			"triage_ref: bv=%.1f at reference bleed should be immediate peril (TTD≈%.0fs)"
			% [peril_bv, _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS]
		)
	var eta_danger: float = _PartyRowFormatter.seconds_to_danger_band(
		_Bleeding.MAX_BLOOD_VOLUME, ref_rate
	)
	var want_danger_eta: float = _Bleeding.seconds_to_exsanguination_at_death_threshold(
		ref_rate,
		_Bleeding.MAX_BLOOD_VOLUME,
		_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING,
		1.0,
	)
	if absf(eta_danger - want_danger_eta) > 0.05:
		CombatRegressionHarness._fail(
			failures,
			"triage_eta: PartyRowFormatter danger ETA got %.2f want %.2f"
			% [eta_danger, want_danger_eta]
		)
	CombatRegressionHarness._free_manager(mgr)


## D-004 ambient path: sub-threshold pain clears accum; sustained NRS-shock-band pain accumulates delta.
static func _run_ambient_pain_shock_tick_accum_physics(failures: PackedStringArray) -> void:
	var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
	CombatConstants.set_feature_ambient_pain_shock(true)
	var low: Node = CombatRegressionHarness._new_entity("SWORD")
	low.wounds["chest"] = [
		{
			"damage": 2.0,
			"severity": _Bleeding.SEVERITY_MINOR,
			"injury_type": _Bleeding.INJURY_TYPE_CUT,
			"current_bleeding_rate": 0.0,
		},
	]
	low._ambient_pain_shock_accum = 2.5
	_EntityPainConsciousness.try_ambient_pain_shock_tick(low, 1.0)
	if low._ambient_pain_shock_accum != 0.0:
		CombatRegressionHarness._fail(
			failures,
			"ambient_pain: sub-threshold effective pain should reset accum got %.2f"
			% float(low._ambient_pain_shock_accum)
		)
	var high: Node = CombatRegressionHarness._new_entity("SWORD")
	high.wounds["chest"] = [
		{
			"damage": 28.0,
			"severity": _Bleeding.SEVERITY_SEVERE,
			"injury_type": _Bleeding.INJURY_TYPE_CUT,
			"current_bleeding_rate": 0.4,
		},
	]
	high.wounds["head"] = [
		{
			"damage": 22.0,
			"severity": _Bleeding.SEVERITY_SEVERE,
			"injury_type": _Bleeding.INJURY_TYPE_CUT,
			"current_bleeding_rate": 0.3,
		},
	]
	var eff: float = _EntityPainConsciousness.get_effective_pain_for_thresholds(high)
	var shock_thresh: float = _PainConscious.get_pain_shock_threshold()
	if eff <= shock_thresh:
		CombatRegressionHarness._fail(
			failures,
			"ambient_pain fixture: need effective pain > %.1f got %.2f"
			% [shock_thresh, eff]
		)
	high._ambient_pain_shock_accum = 0.0
	_EntityPainConsciousness.try_ambient_pain_shock_tick(high, 1.0)
	if high._ambient_pain_shock_accum < 0.99:
		CombatRegressionHarness._fail(
			failures,
			"ambient_pain: high sustained pain should accumulate tick delta got %.2f"
			% float(high._ambient_pain_shock_accum)
		)
	CombatConstants.set_feature_ambient_pain_shock(prior_flag)
	_free_entity_fixture(low)
	_free_entity_fixture(high)


## D-004 ambient path: seeded RNG roll at interval enters pain shock (`_pain_shock_until_time` set).
static func _run_ambient_pain_shock_seeded_rng_enters_shock(failures: PackedStringArray) -> void:
	var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
	CombatConstants.set_feature_ambient_pain_shock(true)
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"damage": 28.0,
			"severity": _Bleeding.SEVERITY_SEVERE,
			"injury_type": _Bleeding.INJURY_TYPE_CUT,
			"current_bleeding_rate": 0.4,
		},
	]
	ent.wounds["head"] = [
		{
			"damage": 22.0,
			"severity": _Bleeding.SEVERITY_SEVERE,
			"injury_type": _Bleeding.INJURY_TYPE_CUT,
			"current_bleeding_rate": 0.3,
		},
	]
	ent._pain_shock_until_time = -1.0
	ent._ambient_pain_shock_accum = 0.0
	var pain: float = _EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
	var shock_thresh: float = _PainConscious.get_pain_shock_threshold()
	shock_thresh += (float(ent.endurance) - 100.0) * 0.02
	if pain <= shock_thresh:
		CombatRegressionHarness._fail(
			failures,
			"ambient_shock_seed: need effective pain > %.1f got %.2f" % [shock_thresh, pain]
		)
		CombatConstants.set_feature_ambient_pain_shock(prior_flag)
		_free_entity_fixture(ent)
		return
	var risk: float = minf(
		1.0,
		(pain - shock_thresh)
		* _PainConscious.PAIN_SHOCK_AMBIENT_RISK_PER_POINT
		* _PainConscious.PAIN_SHOCK_AMBIENT_RISK_MULT
	)
	risk = minf(1.0, risk * _PainConscious.get_pain_shock_susceptibility_mult(pain))
	if risk <= 0.0:
		CombatRegressionHarness._fail(failures, "ambient_shock_seed: need positive ambient risk got %.4f" % risk)
		CombatConstants.set_feature_ambient_pain_shock(prior_flag)
		_free_entity_fixture(ent)
		return
	var win_seed: int = -1
	var lose_seed: int = -1
	for i in range(4096):
		seed(i)
		var roll: float = randf()
		if roll < risk and win_seed < 0:
			win_seed = i
		if roll >= risk and lose_seed < 0:
			lose_seed = i
		if win_seed >= 0 and lose_seed >= 0:
			break
	if win_seed < 0:
		CombatRegressionHarness._fail(failures, "ambient_shock_seed: no winning seed for risk=%.4f" % risk)
		CombatConstants.set_feature_ambient_pain_shock(prior_flag)
		_free_entity_fixture(ent)
		return
	var interval: float = _PainConscious.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
	ent._ambient_pain_shock_accum = interval - 0.001
	seed(win_seed)
	if not _EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
		CombatRegressionHarness._fail(failures, "ambient_shock_seed: want shock entry at seed=%d" % win_seed)
	if ent._pain_shock_until_time < 0.0:
		CombatRegressionHarness._fail(failures, "ambient_shock_seed: _pain_shock_until_time should be set")
	if lose_seed >= 0:
		ent._pain_shock_until_time = -1.0
		ent._ambient_pain_shock_accum = interval - 0.001
		seed(lose_seed)
		if _EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
			CombatRegressionHarness._fail(
				failures, "ambient_shock_seed: roll>=risk should not enter shock at seed=%d" % lose_seed
			)
	CombatConstants.set_feature_ambient_pain_shock(prior_flag)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	_free_entity_fixture(ent)


## D-004: ambient pain-shock rolls gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.
static func _run_ambient_pain_shock_skips_when_feature_off(failures: PackedStringArray) -> void:
	var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
	CombatConstants.set_feature_ambient_pain_shock(false)
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(20.0, 20.0, "chest")
	ent._pain_shock_until_time = -1.0
	for _i in 40:
		if _EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 2.0):
			CombatConstants.set_feature_ambient_pain_shock(prior_flag)
			CombatRegressionHarness._fail(failures, "ambient_shock_off: should not enter shock when feature off")
			_free_entity_fixture(ent)
			return
	CombatConstants.set_feature_ambient_pain_shock(prior_flag)
	_free_entity_fixture(ent)


## Stabilize (hemostatic hold) trims rate but does not mark injuries `is_stabilized` — definitive dress still required.
static func _run_stabilize_hold_does_not_mark_injury_stabilized(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.35,
			"base_bleeding_rate": 0.8,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "stabilize_flag: pressure setup failed")
		_free_entity_fixture(ent)
		return
	if not ent.apply_stabilize("chest", 1.5):
		CombatRegressionHarness._fail(failures, "stabilize_flag: apply_stabilize should succeed")
		_free_entity_fixture(ent)
		return
	if bool(ent.bandaged_parts.get("chest", false)):
		CombatRegressionHarness._fail(failures, "stabilize_flag: stabilize must not set bandaged_parts")
	if bool(ent.wounds["chest"][0].get("is_stabilized", false)):
		CombatRegressionHarness._fail(
			failures, "stabilize_flag: stabilize must not set is_stabilized (dress/pack only)"
		)
	if not _EntityWounds.entity_has_untreated_wounds(ent):
		CombatRegressionHarness._fail(
			failures, "stabilize_flag: stabilize alone must still count as untreated for camp/field dress"
		)
	_free_entity_fixture(ent)


## TCCC: intrinsic bleed may reach 0 under compression, but pressure stays until definitive dress.
static func _run_dressings_allowed_when_locally_clotted_under_pressure(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	var ally_ent := CombatRegressionHarness._new_entity("SWORD")
	var healer_ent := CombatRegressionHarness._new_entity("SWORD")
	ally_ent.wounds["left_leg"] = [
		{
			"current_bleeding_rate": 0.08,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	ally_ent.apply_direct_pressure("left_leg")
	_EntityTimeAdvance.advance(ally_ent, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var intrinsic: float = float(ally_ent.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
	if intrinsic > _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(
			failures,
			"local_clot_dress: fixture should clot intrinsically got rate=%.5f"
			% intrinsic
		)
		CombatRegressionHarness._free_manager(mgr)
		_free_entity_fixture(ally_ent)
		_free_entity_fixture(healer_ent)
		return
	if ally_ent.self_direct_pressure_part != "left_leg":
		CombatRegressionHarness._fail(
			failures,
			"local_clot_dress: TCCC hold until dressed (part=%s)"
			% ally_ent.self_direct_pressure_part
		)
	mgr.register(healer_ent, "player")
	mgr.register(ally_ent, "player")
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var healer_c: Dictionary = mgr.combatants[0]
	var ally_c: Dictionary = mgr.combatants[1]
	if not _MedicalPhase.dressings_allowed_for_part(mgr, ally_c, "left_leg"):
		CombatRegressionHarness._fail(
			failures, "local_clot_dress: dressings should be allowed when display bleed is controlled"
		)
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, healer_c, ally_c, "left_leg")
	var has_bandage: bool = false
	for raw in acts:
		if raw is Dictionary and str((raw as Dictionary).get("move_id", "")) == CombatConstants.MOVE_ID_BANDAGE_SELF:
			has_bandage = true
	if not has_bandage:
		CombatRegressionHarness._fail(failures, "local_clot_dress: bandage should list after local clot under pressure")
	CombatRegressionHarness._free_manager(mgr)
	_free_entity_fixture(ally_ent)
	_free_entity_fixture(healer_ent)


## Field stabilize: hemostatic trim must apply before procedure sim advance (not after).
static func _run_field_stabilize_trim_before_procedure_advance(failures: PackedStringArray) -> void:
	const wound_row: Dictionary = {
		"current_bleeding_rate": 0.35,
		"base_bleeding_rate": 0.8,
		"severity": _Bleeding.SEVERITY_MODERATE,
		"is_arterial": false,
		"is_stabilized": false,
	}
	var advance_only: Node = CombatRegressionHarness._new_entity("SWORD")
	advance_only.wounds["chest"] = [wound_row.duplicate(true)]
	if not advance_only.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "field_stab_order: pressure setup failed")
		_free_entity_fixture(advance_only)
		return
	_EntityTimeAdvance.advance(advance_only, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var rate_advance_only: float = float(
		advance_only.wounds["chest"][0].get("current_bleeding_rate", 0.0)
	)
	var trim_then_advance: Node = CombatRegressionHarness._new_entity("SWORD")
	trim_then_advance.wounds["chest"] = [wound_row.duplicate(true)]
	if not trim_then_advance.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "field_stab_order: pressure setup failed (trim path)")
		_free_entity_fixture(advance_only)
		_free_entity_fixture(trim_then_advance)
		return
	if not trim_then_advance.apply_stabilize("chest", 1.5):
		CombatRegressionHarness._fail(failures, "field_stab_order: stabilize should succeed under pressure")
		_free_entity_fixture(advance_only)
		_free_entity_fixture(trim_then_advance)
		return
	_EntityTimeAdvance.advance(trim_then_advance, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var rate_trim_path: float = float(
		trim_then_advance.wounds["chest"][0].get("current_bleeding_rate", 0.0)
	)
	if rate_trim_path >= rate_advance_only - 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"field_stab_order: stabilize trim before advance should lower intrinsic rate got trim=%.5f advance=%.5f"
			% [rate_trim_path, rate_advance_only]
		)
	_free_entity_fixture(advance_only)
	_free_entity_fixture(trim_then_advance)


## Field tourniquet: occlude limb hemorrhage before procedure sim advance (not 2 min open bleed first).
static func _run_field_tourniquet_applies_before_procedure_advance(failures: PackedStringArray) -> void:
	const wound_row: Dictionary = {
		"current_bleeding_rate": 1.4,
		"base_bleeding_rate": 2.0,
		"severity": _Bleeding.SEVERITY_SEVERE,
		"is_arterial": true,
		"is_stabilized": false,
	}
	var tq_first: Node = CombatRegressionHarness._new_entity("SWORD")
	tq_first.blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	tq_first.wounds["left_leg"] = [wound_row.duplicate(true)]
	var bleed_first: Node = CombatRegressionHarness._new_entity("SWORD")
	bleed_first.blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	bleed_first.wounds["left_leg"] = [wound_row.duplicate(true)]
	seed(884401)
	var tq_ok: bool = tq_first.apply_tourniquet("left_leg", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not tq_ok:
		CombatRegressionHarness._fail(failures, "field_tq_order: tourniquet setup should succeed")
		_free_entity_fixture(tq_first)
		_free_entity_fixture(bleed_first)
		return
	_EntityTimeAdvance.advance(tq_first, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	_EntityTimeAdvance.advance(bleed_first, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	seed(884401)
	bleed_first.apply_tourniquet("left_leg", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if float(tq_first.blood_volume) <= float(bleed_first.blood_volume):
		CombatRegressionHarness._fail(
			failures,
			"field_tq_order: TQ-before-advance should preserve more blood (tq_first=%.1f bleed_first=%.1f)"
			% [float(tq_first.blood_volume), float(bleed_first.blood_volume)]
		)
	if not bleed_first.tourniquet_applied.has("left_leg"):
		CombatRegressionHarness._fail(failures, "field_tq_order: bleed-first path should still end with TQ applied")
	_free_entity_fixture(tq_first)
	_free_entity_fixture(bleed_first)


## Stabilize requires intrinsic active bleed — not arterial label alone after local clot under compression.
static func _run_stabilize_requires_intrinsic_active_bleed(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.0,
			"base_bleeding_rate": 0.8,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": true,
			"is_stabilized": false,
		},
	]
	if not ent.apply_direct_pressure("chest"):
		CombatRegressionHarness._fail(failures, "stabilize_intrinsic: pressure setup failed")
		_free_entity_fixture(ent)
		return
	if ent.can_apply_stabilize("chest"):
		CombatRegressionHarness._fail(
			failures,
			"stabilize_intrinsic: no hemostatic hold when intrinsic bleed already controlled under compression"
		)
	ent.wounds["chest"][0]["current_bleeding_rate"] = 0.15
	if not ent.can_apply_stabilize("chest"):
		CombatRegressionHarness._fail(
			failures, "stabilize_intrinsic: stabilize should allow while intrinsic bleed remains active"
		)
	_free_entity_fixture(ent)


## Arterial hemorrhage under compression alone: meaningful blood loss over one field-care procedure.
static func _run_field_care_arterial_blood_loss_meaningful(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.blood_volume = _Bleeding.MAX_BLOOD_VOLUME
	ent.wounds["chest"] = [
		{
			"current_bleeding_rate": 0.8,
			"base_bleeding_rate": 2.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": true,
			"is_stabilized": false,
		},
	]
	ent.apply_direct_pressure("chest")
	_EntityTimeAdvance.advance(ent, _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS, false)
	var loss_pct: float = _Bleeding.MAX_BLOOD_VOLUME - float(ent.blood_volume)
	if loss_pct < 3.0:
		CombatRegressionHarness._fail(
			failures,
			"field_care_arterial_loss: pressure alone should still lose meaningful blood got loss=%.2f%%"
			% loss_pct
		)
	if float(ent.blood_volume) >= _Bleeding.ATLS_CLASS_I_MIN_REMAINING:
		CombatRegressionHarness._fail(
			failures,
			"field_care_arterial_loss: moderate arterial should exit procedure below ATLS I got bv=%.1f"
			% float(ent.blood_volume)
		)
	_free_entity_fixture(ent)


## Ally/self pressure requires active hemorrhage (display rate above epsilon).
static func _run_direct_pressure_requires_active_bleed(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.wounds["left_leg"] = [
		{
			"current_bleeding_rate": 0.0,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_stabilized": false,
		},
	]
	if ent.can_apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(failures, "pressure_active_bleed: self-pressure blocked when rate=0")
	var ally: Node = CombatRegressionHarness._new_entity("SWORD")
	var healer: Node = CombatRegressionHarness._new_entity("SWORD")
	if ent.can_apply_direct_pressure_from_ally("left_leg", healer):
		CombatRegressionHarness._fail(
			failures, "pressure_active_bleed: ally-pressure blocked when rate=0"
		)
	ent.wounds["left_leg"][0]["current_bleeding_rate"] = 0.12
	if not ent.can_apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(
			failures, "pressure_active_bleed: self-pressure should allow active bleed"
		)
	if not ent.can_apply_direct_pressure_from_ally("left_leg", healer):
		CombatRegressionHarness._fail(
			failures, "pressure_active_bleed: ally-pressure should allow active bleed"
		)
	_free_entity_fixture(ent)
	_free_entity_fixture(ally)
	_free_entity_fixture(healer)


## Clotting k: sustained direct pressure decays bleed rate faster than open moderate venous wound.
static func _run_clotting_pressure_faster_than_open_bleed(failures: PackedStringArray) -> void:
	var wound_row: Dictionary = {
		"current_bleeding_rate": 0.08,
		"base_bleeding_rate": 0.4,
		"severity": _Bleeding.SEVERITY_MODERATE,
		"is_arterial": false,
		"is_stabilized": false,
	}
	var open: Node = CombatRegressionHarness._new_entity("SWORD")
	open.wounds["left_leg"] = [wound_row.duplicate(true)]
	var pressed: Node = CombatRegressionHarness._new_entity("SWORD")
	pressed.wounds["left_leg"] = [wound_row.duplicate(true)]
	if not pressed.apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(failures, "clot_pressure: apply_direct_pressure failed")
		_free_entity_fixture(open)
		_free_entity_fixture(pressed)
		return
	const steps: int = 45
	for _i in range(steps):
		_EntityWounds.process_bleeding(open, 1.0)
		_EntityWounds.process_bleeding(pressed, 1.0)
	var inj_open: float = float(open.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
	var inj_press: float = float(pressed.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
	if inj_press >= inj_open - 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"clot_pressure: pressure should decay intrinsic rate faster got open=%.5f press=%.5f"
			% [inj_open, inj_press]
		)
	var moderate_k: float = (
		_Bleeding.get_clotting_rate(_Bleeding.SEVERITY_MODERATE)
		* _Bleeding.get_clotting_multiplier(_Bleeding.SEVERITY_MODERATE)
	)
	var delta_k: float = _Bleeding.CLOTTING_RATE_UNDER_DIRECT_PRESSURE - moderate_k
	var want_ratio: float = exp(-delta_k * float(steps))
	if inj_press > inj_open * want_ratio * 1.05 + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"clot_pressure: intrinsic ratio want <=%.3f got %.3f (open=%.5f press=%.5f)"
			% [want_ratio, inj_press / inj_open if inj_open > 0.0 else 0.0, inj_open, inj_press]
		)
	_free_entity_fixture(open)
	_free_entity_fixture(pressed)


## Medical phase integrated loss: clotting during tick replay stays below constant-rate ATLS drain.
static func _run_medical_phase_blood_loss_clotting_below_constant_drain(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	ent.take_damage_split(6.0, 2.0, "chest")
	ent.blood_volume = 60.0
	ent.set_combat_blood_loss_mult(1.0)
	ent.set_combat_blood_recovery_per_s(0.0)
	var rate0: float = _EntityWounds.get_total_bleeding_rate(ent)
	if rate0 <= 0.0:
		CombatRegressionHarness._fail(failures, "med_clot_drain: need active bleed")
		_free_entity_fixture(ent)
		return
	const seconds: float = 12.0
	var constant_want: float = rate0 * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER * seconds
	var steps: int = int(seconds)
	for _i in range(steps):
		ent.process_bleeding(1.0)
		ent.process_blood_loss(1.0)
	var actual_loss: float = 60.0 - float(ent.blood_volume)
	if actual_loss >= constant_want - 0.02:
		CombatRegressionHarness._fail(
			failures,
			"med_clot_drain: clotting should reduce integrated loss got %.3f want < %.3f"
			% [actual_loss, constant_want - 0.02]
		)
	_free_entity_fixture(ent)


## Hemostasis k: definitive bandage (`CLOTTING_RATE_STABILIZED`) decays slower than sustained compression (`CLOTTING_RATE_UNDER_DIRECT_PRESSURE`) at matched intrinsic rate.
static func _run_clotting_bandaged_slower_k_than_pressure_held(failures: PackedStringArray) -> void:
	const start_rate: float = 0.08
	const steps: int = 60
	var bandaged: Node = CombatRegressionHarness._new_entity("SWORD")
	bandaged.wounds["left_leg"] = [
		{
			"current_bleeding_rate": start_rate,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": true,
		},
	]
	bandaged.bandaged_parts["left_leg"] = true
	var pressed: Node = CombatRegressionHarness._new_entity("SWORD")
	pressed.wounds["left_leg"] = [
		{
			"current_bleeding_rate": start_rate,
			"base_bleeding_rate": 0.4,
			"severity": _Bleeding.SEVERITY_MODERATE,
			"is_arterial": false,
			"is_stabilized": false,
		},
	]
	if not pressed.apply_direct_pressure("left_leg"):
		CombatRegressionHarness._fail(failures, "clot_bandage_vs_press: apply_direct_pressure failed")
		_free_entity_fixture(bandaged)
		_free_entity_fixture(pressed)
		return
	for _i in range(steps):
		_EntityWounds.process_bleeding(bandaged, 1.0)
		_EntityWounds.process_bleeding(pressed, 1.0)
	var inj_bandaged: float = float(bandaged.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
	var inj_pressed: float = float(pressed.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
	if inj_bandaged <= inj_pressed + 0.0001:
		CombatRegressionHarness._fail(
			failures,
			"clot_bandage_vs_press: stabilized bandage k should stay above pressure-held intrinsic rate got band=%.5f press=%.5f"
			% [inj_bandaged, inj_pressed]
		)
	var want_ratio: float = exp(
		-(_Bleeding.CLOTTING_RATE_STABILIZED - _Bleeding.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
		* float(steps)
	)
	if inj_bandaged < inj_pressed * want_ratio * 0.92:
		CombatRegressionHarness._fail(
			failures,
			"clot_bandage_vs_press: intrinsic ratio want >=%.2f got %.2f"
			% [want_ratio, inj_bandaged / inj_pressed if inj_pressed > 0.0 else 0.0]
		)
	_free_entity_fixture(bandaged)
	_free_entity_fixture(pressed)


static func _run_battle_ui_receiving_care_gauge_primary(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	var c: Dictionary = {
		"state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
		"alive": true,
		"gauge": 0.0,
		"stamina": 40.0,
	}
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	var tip: String = _UiHints.medical_busy_row_tooltip_line(c)
	CombatRegressionHarness._free_manager(mgr)
	if not label.contains("Receiving care"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_receiving: want Receiving care primary got '%s'" % label
		)
	if not tip.contains("Receiving care"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_receiving: want tooltip line got '%s'" % tip
		)


## TCCC: sustained compression raises dressing success (`TREATMENT_PRESSURE_HELD_SUCCESS_MULT`) — combat + field care share `EntityMedical.apply_bandage`.
static func _run_pressure_held_bandage_success_mult_parity(failures: PackedStringArray) -> void:
	if not is_equal_approx(_Bleeding.TREATMENT_PRESSURE_HELD_SUCCESS_MULT, 1.18):
		CombatRegressionHarness._fail(
			failures,
			"pressure_held_mult: expected 1.18 got %.3f"
			% _Bleeding.TREATMENT_PRESSURE_HELD_SUCCESS_MULT
		)
	const eff: float = 0.55
	var extra_with_pressure: int = 0
	for i in range(256):
		seed(88100 + i)
		var no_p: Node = CombatRegressionHarness._new_entity("SWORD")
		no_p.wounds["left_leg"] = [
			{"current_bleeding_rate": 0.5, "severity": "moderate", "is_stabilized": false},
		]
		var ok_no: bool = no_p.apply_bandage("left_leg", eff)
		seed(88100 + i)
		var with_p: Node = CombatRegressionHarness._new_entity("SWORD")
		with_p.wounds["left_leg"] = [
			{"current_bleeding_rate": 0.5, "severity": "moderate", "is_stabilized": false},
		]
		if not with_p.apply_direct_pressure("left_leg"):
			CombatRegressionHarness._fail(failures, "pressure_held_mult: self-pressure setup failed")
			_free_entity_fixture(no_p)
			_free_entity_fixture(with_p)
			return
		var ok_yes: bool = with_p.apply_bandage("left_leg", eff)
		if ok_yes and not ok_no:
			extra_with_pressure += 1
		if ok_no and not ok_yes:
			CombatRegressionHarness._fail(
				failures, "pressure_held_mult: pressure must not reduce success at same roll"
			)
		_free_entity_fixture(no_p)
		_free_entity_fixture(with_p)
	if extra_with_pressure < 8:
		CombatRegressionHarness._fail(
			failures,
			"pressure_held_mult: want pressure-held bonus wins got %d (eff=%.2f)"
			% [extra_with_pressure, eff]
		)


## Camp-3.3: medical wind-up primary label shows procedure + remaining seconds.
static func _run_battle_ui_medical_wind_up_gauge_primary(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.medical_phase = true
	var c: Dictionary = {
		"state": CombatConstants.STATE_MEDICAL_WIND_UP,
		"alive": true,
		"state_timer": 0.5,
		"state_duration": 3.0,
		"pending_medical": {
			"medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
			"target_combatant_id": 1,
		},
		"gauge": 0.0,
		"stamina": 40.0,
	}
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	var tip: String = _UiHints.medical_busy_row_tooltip_line(c)
	CombatRegressionHarness._free_manager(mgr)
	if not label.contains("Bandaging") or not label.contains("2.5s"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_med_wu: want procedure + timer primary got '%s'" % label
		)
	if not tip.contains("Medical wind-up"):
		CombatRegressionHarness._fail(
			failures, "battle_ui_med_wu: want wind-up tooltip got '%s'" % tip
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
	_free_entity_fixture(ent)


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


## Bandage/pack blocked on a part while another medic's wind-up targets the same part.
static func _run_medical_coordination_blocks_bandage_during_ally_windup(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
	var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
	var patient: Node = CombatRegressionHarness._new_entity("SWORD")
	patient.take_damage_split(10.0, 3.0, "chest")
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
	if not patient.apply_direct_pressure_from_ally("chest", healer_a):
		CombatRegressionHarness._fail(failures, "med_coord_bandage: setup ally pressure failed")
		CombatRegressionHarness._free_manager(mgr)
		return
	ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
	ha.state_duration = 6.0
	ha.pending_medical = {
		"medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
		"target_part": "chest",
		"target_combatant_id": pt_id,
	}
	if _MedicalCoord.medical_action_allowed(
		mgr, hb_id, pt_id, "chest", CombatConstants.MOVE_ID_BANDAGE_SELF
	):
		CombatRegressionHarness._fail(
			failures, "med_coord_bandage: second medic must not bandage during ally wind-up"
		)
	if _MedicalCoord.medical_action_allowed(
		mgr, hb_id, pt_id, "chest", CombatConstants.MOVE_ID_PACK_WOUND
	):
		CombatRegressionHarness._fail(
			failures, "med_coord_bandage: second medic must not pack during ally bandage wind-up"
		)
	var acts: Array = _MedicalPhase.get_ally_medical_actions(mgr, hb, pt, "chest")
	for raw in acts:
		if raw is not Dictionary:
			continue
		var mid: String = str((raw as Dictionary).get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_BANDAGE_SELF or mid == CombatConstants.MOVE_ID_PACK_WOUND:
			CombatRegressionHarness._fail(
				failures,
				"med_coord_bandage: listing must omit dress moves during ally wind-up got %s" % mid
			)
	CombatRegressionHarness._free_manager(mgr)


static func _run_medical_windup_prepare_preserves_ally_head_pressure(failures: PackedStringArray) -> void:
	var patient: Node = CombatRegressionHarness._new_entity("SWORD")
	var ally: Node = CombatRegressionHarness._new_entity("SWORD")
	patient.take_damage_split(8.0, 3.0, "head")
	if not patient.wounds.has("head"):
		CombatRegressionHarness._fail(failures, "windup_prepare: need head wound")
		CombatRegressionHarness._free_harness_node(patient)
		CombatRegressionHarness._free_harness_node(ally)
		return
	if not patient.apply_direct_pressure_from_ally("head", ally):
		CombatRegressionHarness._fail(failures, "windup_prepare: ally pressure failed")
		CombatRegressionHarness._free_harness_node(patient)
		CombatRegressionHarness._free_harness_node(ally)
		return
	var held: float = _EntityWounds.get_bleeding_rate_for_part(patient, "head")
	if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
		CombatRegressionHarness._fail(failures, "windup_prepare: ally hold not registered")
		CombatRegressionHarness._free_harness_node(patient)
		CombatRegressionHarness._free_harness_node(ally)
		return
	_EntityMedical.prepare_for_medical_windup(patient, patient, "head")
	if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
		CombatRegressionHarness._fail(failures, "windup_prepare: ally hold cleared on treatment part")
		CombatRegressionHarness._free_harness_node(patient)
		CombatRegressionHarness._free_harness_node(ally)
		return
	var after: float = _EntityWounds.get_bleeding_rate_for_part(patient, "head")
	if after > held + _Bleeding.BLEEDING_RATE_EPSILON:
		CombatRegressionHarness._fail(
			failures,
			"windup_prepare: rebound during prepare held=%.3f after=%.3f" % [held, after]
		)
	CombatRegressionHarness._free_harness_node(patient)
	CombatRegressionHarness._free_harness_node(ally)


## MS-MID: mid-fight listing for ally immediate peril + L1 coordinated pick (not medical phase).
static func _run_ms_mid_infight_med_depth_suite(failures: PackedStringArray) -> void:
	if not CombatConstants.FEATURE_MS_MID_INFIGHT_MED:
		CombatRegressionHarness._fail(
			failures, "ms_mid_depth: FEATURE_MS_MID_INFIGHT_MED should be enabled"
		)
		return
	if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
		CombatRegressionHarness._fail(failures, "ms_mid_depth: production getter should be on")
		return
	_run_ms_mid_infight_ally_medical_listing(failures)


static func _run_ms_mid_infight_ally_medical_listing(failures: PackedStringArray) -> void:
	const _FootworkTail := preload("res://combat/CombatRegressionHarnessAttentionFootworkTail.gd")
	const _MentalStack := preload("res://combat/MentalStackDecider.gd")
	if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
		CombatRegressionHarness._fail(
			failures, "ms_mid_listing: FEATURE_MS_MID_INFIGHT_MED must be on in production"
		)
		return
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	medic["gauge"] = 100.0
	medic.state = CombatConstants.STATE_WAITING
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	_FootworkTail._harness_immediate_peril_bleeding_chest(ally_ent, 30.0)
	if mgr.medical_phase:
		CombatRegressionHarness._fail(failures, "ms_mid_listing: fixture must stay in combat phase")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var built: Array = _ActionsBuilder.build(mgr, medic_id)
	var has_ally_pressure: bool = false
	for raw in built:
		if raw is not Dictionary:
			continue
		var act: Dictionary = raw as Dictionary
		if (
			str(act.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
			and int(act.get("target_id", -1)) == ally_id
			and str(act.get("target_part", "")) == "chest"
		):
			has_ally_pressure = true
	if not has_ally_pressure:
		CombatRegressionHarness._fail(
			failures, "ms_mid_listing: want ally chest pressure in mid-fight build got %d actions" % built.size()
		)
	var saved: bool = CombatConstants.is_feature_ms_mid_infight_med_enabled()
	CombatConstants.set_feature_ms_mid_infight_med_load(false)
	var built_off: Array = _ActionsBuilder.build(mgr, medic_id)
	CombatConstants.set_feature_ms_mid_infight_med_load(saved)
	for raw in built_off:
		if raw is not Dictionary:
			continue
		var act_off: Dictionary = raw as Dictionary
		if (
			CombatConstants.is_medical_move(str(act_off.get("move_id", "")))
			and int(act_off.get("target_id", -1)) == ally_id
		):
			CombatRegressionHarness._fail(
				failures,
				"ms_mid_listing: flag off should not list ally medical mid-fight"
			)
			break
	var picked: Dictionary = _MentalStack.try_pick(built, medic_id, mgr)
	if picked.is_empty():
		CombatRegressionHarness._fail(failures, "ms_mid_listing: mental stack expected L1 medical pick")
	elif (
		str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		!= CombatConstants.MENTAL_STACK_LAYER_MEDICAL
	):
		CombatRegressionHarness._fail(
			failures,
			"ms_mid_listing: want layer medical got %s"
			% str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	elif str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
		CombatRegressionHarness._fail(
			failures,
			"ms_mid_listing: want apply_direct_pressure got %s" % str(picked.get("move_id", ""))
		)
	var filtered: Array = _MedicalCoord.filter_actions_for_pick(mgr, medic_id, built)
	var filtered_has_pressure: bool = false
	for raw in filtered:
		if raw is not Dictionary:
			continue
		var act_f: Dictionary = raw as Dictionary
		if (
			str(act_f.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
			and int(act_f.get("target_id", -1)) == ally_id
		):
			filtered_has_pressure = true
	if not filtered_has_pressure:
		CombatRegressionHarness._fail(failures, "ms_mid_listing: mid-fight pick filter dropped coordinated ally pressure")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


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
		_free_entity_fixture(ent)
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
	_free_entity_fixture(ent)


static func _run_pack_wound_apply_packing_marks_packed_parts(failures: PackedStringArray) -> void:
	var ent: Node = CombatRegressionHarness._new_entity("SWORD")
	_harness_wound_chest_for_packing(ent)
	_harness_hold_pressure_if_bleeding(ent, "chest")
	seed(88202)
	var ok: bool = ent.apply_packing("chest", 1.5)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if not ok:
		CombatRegressionHarness._fail(failures, "pack_wound_apply: apply_packing should succeed with high effectiveness")
	if not bool(ent.packed_parts.get("chest", false)):
		CombatRegressionHarness._fail(failures, "pack_wound_apply: packed_parts[chest] should be set")
	_free_entity_fixture(ent)


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
	var packed_chest: bool = bool(ally_node.packed_parts.get("chest", false))
	CombatRegressionHarness._free_manager(mgr)
	if str(outcome_box[0]) != "packed" and str(outcome_box[0]) != "packing_failed":
		CombatRegressionHarness._fail(
			failures,
			"pack_wound_windup: want packed or packing_failed got '%s'" % str(outcome_box[0])
		)
	if str(outcome_box[0]) == "packed" and not packed_chest:
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


## Idle fast-forward tick must advance clock when winners wait at full gauge with open wounds.
static func _run_fast_forward_idle_unsticks_waiting_triage(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
	wounded.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
	mgr.register(wounded, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	for raw in mgr.combatants:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw as Dictionary
		if not _MedicalPhase.is_winner_side(mgr, c):
			continue
		c["state"] = CombatConstants.STATE_WAITING
		c["gauge"] = 100.0
	mgr.event_queue.clear()
	var clock_before: float = float(mgr.combat_clock)
	var parts_before: int = _MedicalPhase.winner_side_untreated_part_count(mgr)
	seed(88206)
	_MedicalPhase.instant_complete_on_early_exit(mgr)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var clock_after: float = float(mgr.combat_clock)
	var parts_after: int = _MedicalPhase.winner_side_untreated_part_count(mgr)
	var progressed: bool = (
		clock_after > clock_before
		or parts_after < parts_before
		or _MedicalPhase.can_end_medical_phase(mgr)
	)
	if not progressed:
		CombatRegressionHarness._fail(
			failures,
			"fast_forward_idle: want clock advance or fewer untreated parts (clock %.3f->%.3f parts %d->%d)"
			% [clock_before, clock_after, parts_before, parts_after]
		)
	CombatRegressionHarness._free_manager(mgr)


## Turn picks with dt=0 must still advance sim time (no infinite fast-forward spin).
static func _run_fast_forward_stalled_picks_advance_clock(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for i in range(3):
		var ent: Node = CombatRegressionHarness._new_entity("SWORD")
		ent.wounds["chest"] = [{"current_bleeding_rate": 0.35, "severity": "moderate"}]
		mgr.register(ent, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	mgr.event_queue.clear()
	for raw in mgr.combatants:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw as Dictionary
		if not _MedicalPhase.is_winner_side(mgr, c):
			continue
		c["state"] = CombatConstants.STATE_WAITING
		c["gauge"] = 100.0
	var clock_before: float = float(mgr.combat_clock)
	seed(88207)
	_MedicalPhase.instant_complete_on_early_exit(mgr)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if _MedicalPhase.medical_fast_forward_active(mgr):
		CombatRegressionHarness._fail(
			failures, "fast_forward_stalled_picks: fast-forward meta should clear after exit"
		)
	if float(mgr.combat_clock) <= clock_before:
		CombatRegressionHarness._fail(
			failures,
			"fast_forward_stalled_picks: want combat_clock advance (%.3f->%.3f)"
			% [clock_before, float(mgr.combat_clock)]
		)
	CombatRegressionHarness._free_manager(mgr)


## Interactive per-pass sim cap must terminate and clear fast-forward meta (no hang).
static func _run_fast_forward_sim_cap_terminates(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var wounded: Node = CombatRegressionHarness._new_entity("SWORD")
	wounded.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
	mgr.register(wounded, "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	for raw in mgr.combatants:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw as Dictionary
		if not _MedicalPhase.is_winner_side(mgr, c):
			continue
		c["state"] = CombatConstants.STATE_WAITING
		c["gauge"] = 100.0
	mgr.event_queue.clear()
	var cap: float = _MedicalPhase.INSTANT_FAST_FORWARD_INTERACTIVE_MAX_SECONDS
	seed(88208)
	_MedicalPhase.instant_complete_on_early_exit(mgr, cap)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if _MedicalPhase.medical_fast_forward_active(mgr):
		CombatRegressionHarness._fail(
			failures, "fast_forward_sim_cap: fast-forward meta should clear after capped pass"
		)
	if _MedicalPhase.can_end_medical_phase(mgr):
		CombatRegressionHarness._fail(
			failures, "fast_forward_sim_cap: capped pass should not fully dress all wounds in harness"
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


## Time-sliced fast-forward (interactive path) must finish the same in-progress bandage as sync exit.
static func _run_fast_forward_time_slice_completes_medical_windup(failures: PackedStringArray) -> void:
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
		CombatRegressionHarness._fail(
			failures, "fast_forward_time_slice: ally pressure setup failed"
		)
		CombatRegressionHarness._free_manager(mgr)
		return
	_MedicalActionStarter.start(
		mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest"
	)
	var sim_state: Dictionary = _MedicalPhase.fast_forward_prepare(mgr, -1.0)
	if sim_state.is_empty():
		CombatRegressionHarness._fail(failures, "fast_forward_time_slice: prepare should start")
		CombatRegressionHarness._free_manager(mgr)
		return
	var sim_cap: float = float(sim_state["sim_cap"])
	var break_reason: String = "sim_cap"
	var guard: int = 0
	seed(88209)
	while guard < 200000:
		guard += 1
		var slice: Dictionary = _MedicalPhase.fast_forward_advance_time_slice(
			mgr,
			sim_state,
			sim_cap,
			_MedicalPhase.INTERACTIVE_FAST_FORWARD_FRAME_BUDGET_US
		)
		if not bool(slice.get("continue_loop", false)):
			break_reason = str(slice.get("break_reason", "sim_cap"))
			break
	_MedicalPhase.fast_forward_finalize(mgr, sim_state, break_reason)
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	if _MedicalPhase.medical_fast_forward_active(mgr):
		CombatRegressionHarness._fail(
			failures, "fast_forward_time_slice: fast-forward meta should clear"
		)
	if not bool(ally_ent.bandaged_parts.get("chest", false)):
		CombatRegressionHarness._fail(
			failures, "fast_forward_time_slice: ally chest should be bandaged after slices"
		)
	CombatRegressionHarness._free_manager(mgr)


## Campaign contract: batch_resolve on finish_battle completes in-progress bandage (no tick-replay).
static func _run_finish_battle_campaign_batch_completes_windup(failures: PackedStringArray) -> void:
	var world: Node2D = Node2D.new()
	world.set_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT, {"contract_title": "Scout"})
	var battle: Node = _BattleScene.new()
	battle.parent_scene = world
	var mgr: Node = _MgrScript.new()
	battle.add_child(mgr)
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
		CombatRegressionHarness._fail(failures, "finish_battle_campaign_batch: ally pressure setup failed")
		CombatRegressionHarness._free_manager(mgr)
		battle.free()
		world.free()
		return
	_MedicalActionStarter.start(
		mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest"
	)
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.clear_capture()
	_OperationalLog.begin_play_session("harness_batch_exit", "", false, false)
	seed(88206)
	mgr.finish_battle()
	seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
	var bandaged_chest: bool = bool(ally_ent.bandaged_parts.get("chest", false))
	var batch_exit_log: bool = false
	var batch_summary_log: bool = false
	for raw in _OperationalLog.get_captured_lines():
		var body: String = str(raw).strip_edges()
		if body.begins_with(_OperationalLog.TAG_COMBAT + ":"):
			body = body.substr(_OperationalLog.TAG_COMBAT.length() + 1).strip_edges()
		if body.begins_with("campaign_medical_exit") and "batch_resolve=true" in body:
			batch_exit_log = true
		if body.begins_with("medical_batch_resolve"):
			batch_summary_log = true
	_OperationalLog.end_play_session()
	CombatRegressionHarness._free_manager(mgr)
	battle.free()
	world.free()
	if not bandaged_chest:
		CombatRegressionHarness._fail(
			failures, "finish_battle_campaign_batch: ally chest should be bandaged after batch exit"
		)
	if not batch_exit_log:
		CombatRegressionHarness._fail(
			failures, "finish_battle_campaign_batch: want campaign_medical_exit batch_resolve=true"
		)
	if not batch_summary_log:
		CombatRegressionHarness._fail(
			failures, "finish_battle_campaign_batch: want medical_batch_resolve log line"
		)


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
	var bandaged_chest: bool = bool(ally_ent.bandaged_parts.get("chest", false))
	var medical_phase_cleared: bool = not bool(mgr.medical_phase)
	CombatRegressionHarness._free_manager(mgr)
	if not bandaged_chest:
		CombatRegressionHarness._fail(
			failures, "finish_battle_instant: ally chest should be bandaged after finish_battle"
		)
	if not medical_phase_cleared:
		CombatRegressionHarness._fail(failures, "finish_battle_instant: medical_phase should clear on stop")


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
	_run_field_care_procedure_sim_advance_seconds(failures)
	_run_field_care_venous_clot_under_procedure(failures)
	_run_field_care_arterial_stays_lethal_under_procedure(failures)
	_run_field_care_venous_blood_loss_bounded(failures)
	_run_field_care_arterial_blood_loss_meaningful(failures)
	_run_direct_pressure_flow_retention_venous_vs_arterial_parity(failures)
	_run_research_anchor_clotting_half_life_physics(failures)
	_run_research_anchor_reference_bleed_derivation_parity(failures)
	_run_direct_pressure_held_suppresses_bleed_rate(failures)
	_run_treatment_channel_count_not_raw_hit_count(failures)
	_run_direct_pressure_release_rebleeds_without_dressing(failures)
	_run_field_care_pressure_before_bandage_parity(failures)
	_run_field_care_pressure_before_pack_parity(failures)
	_run_entity_medical_dressing_requires_compression_when_bleeding(failures)
	_run_failed_packing_retains_direct_pressure(failures)
	_run_dressings_blocked_without_pressure_when_bleeding(failures)
	_run_dressings_still_offered_after_failure_out_of_peril(failures)
	_run_failed_dressing_retains_direct_pressure(failures)
	_run_pressure_held_until_dressed(failures)
	_run_medical_phase_full_blood_loss_rate(failures)
	_run_medical_phase_fled_winner_bleed_suspended_on_tick(failures)
	_run_medical_triage_reference_bleed_peril_parity(failures)
	_run_ambient_pain_shock_tick_accum_physics(failures)
	_run_ambient_pain_shock_seeded_rng_enters_shock(failures)
	_run_ambient_pain_shock_skips_when_feature_off(failures)
	_run_iii5_packing_channel_success_depth(failures)
	_run_stabilize_hold_does_not_mark_injury_stabilized(failures)
	_run_stabilize_success_still_untreated_for_camp(failures)
	_run_field_stabilize_trim_before_procedure_advance(failures)
	_run_field_tourniquet_applies_before_procedure_advance(failures)
	_run_stabilize_requires_intrinsic_active_bleed(failures)
	_run_dressings_allowed_when_locally_clotted_under_pressure(failures)
	_run_direct_pressure_requires_active_bleed(failures)
	_run_clotting_pressure_faster_than_open_bleed(failures)
	_run_clotting_bandaged_slower_k_than_pressure_held(failures)
	_run_medical_phase_blood_loss_clotting_below_constant_drain(failures)
	_run_battle_ui_receiving_care_gauge_primary(failures)
	_run_medical_coordination_blocks_bandage_during_ally_windup(failures)
	_run_pressure_held_bandage_success_mult_parity(failures)
	_run_battle_ui_medical_wind_up_gauge_primary(failures)


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
	_run_fast_forward_idle_unsticks_waiting_triage(failures)
	_run_fast_forward_stalled_picks_advance_clock(failures)
	_run_fast_forward_sim_cap_terminates(failures)
	_run_winner_side_triage_busy_turn_ready_pending(failures)
	_run_winner_side_triage_busy_gauge_and_complete(failures)
	_run_finish_battle_flushes_deferred_soak_coverage(failures)
	_run_finish_battle_campaign_medical_exit_refreshes_camp(failures)
	_run_finish_battle_incomplete_hint_campaign_only(failures)
	_run_fast_forward_time_slice_completes_medical_windup(failures)
	_run_finish_battle_campaign_batch_completes_windup(failures)
	_run_finish_battle_instant_completes_medical_windup(failures)
	_run_bandage_allowed_on_packed_part(failures)
	_run_direct_pressure_held_suppresses_bleed_rate(failures)
	_run_direct_pressure_release_rebleeds_without_dressing(failures)
	_run_medical_windup_prepare_preserves_ally_head_pressure(failures)
	_run_medical_coordination_blocks_overlapping_treatment(failures)
	_run_medical_coordination_blocks_bandage_during_ally_windup(failures)
	_run_medical_coordination_stack_assist_during_windup(failures)
	_run_ms_mid_infight_med_depth_suite(failures)
	_run_treatment_channel_count_not_raw_hit_count(failures)
	_run_iii5_packing_channel_success_depth(failures)
	_run_failed_dressing_retains_direct_pressure(failures)
	_run_dressings_blocked_without_pressure_when_bleeding(failures)
	_run_dressings_still_offered_after_failure_out_of_peril(failures)
	_run_pending_retry_set_even_with_other_medics(failures)
	_run_medical_ai_prefers_dressing_over_stabilize_out_of_peril(failures)
	_run_entity_untreated_matches_bridge(failures)
	_run_pressure_held_until_dressed(failures)
	_run_field_care_procedure_sim_advance_seconds(failures)
	_run_field_care_venous_clot_under_procedure(failures)
	_run_field_care_arterial_stays_lethal_under_procedure(failures)
	_run_field_care_venous_blood_loss_bounded(failures)
	_run_field_care_arterial_blood_loss_meaningful(failures)
	_run_direct_pressure_flow_retention_venous_vs_arterial_parity(failures)
	_run_field_care_pressure_before_bandage_parity(failures)
	_run_field_care_pressure_before_pack_parity(failures)
	_run_entity_medical_dressing_requires_compression_when_bleeding(failures)
	_run_failed_packing_retains_direct_pressure(failures)
	_run_research_anchor_clotting_half_life_physics(failures)
	_run_medical_triage_reference_bleed_peril_parity(failures)
	_run_ambient_pain_shock_tick_accum_physics(failures)
	_run_ambient_pain_shock_seeded_rng_enters_shock(failures)
	_run_ambient_pain_shock_skips_when_feature_off(failures)
	_run_stabilize_hold_does_not_mark_injury_stabilized(failures)
	_run_stabilize_success_still_untreated_for_camp(failures)
	_run_field_stabilize_trim_before_procedure_advance(failures)
	_run_field_tourniquet_applies_before_procedure_advance(failures)
	_run_stabilize_requires_intrinsic_active_bleed(failures)
	_run_dressings_allowed_when_locally_clotted_under_pressure(failures)
	_run_direct_pressure_requires_active_bleed(failures)
	_run_clotting_pressure_faster_than_open_bleed(failures)
	_run_clotting_bandaged_slower_k_than_pressure_held(failures)
	_run_medical_phase_blood_loss_clotting_below_constant_drain(failures)
	_run_battle_ui_receiving_care_gauge_primary(failures)
	_run_pressure_held_bandage_success_mult_parity(failures)
	_run_battle_ui_medical_wind_up_gauge_primary(failures)
	_run_wound_merge_same_subregion(failures)
	_run_medical_phase_losing_side_stays_fled(failures)
	_run_ally_medical_tourniquet_path_pressure_first(failures)
	_run_medical_phase_full_blood_loss_rate(failures)
	_run_combat_log_formatter_pack_ally_label(failures)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	_F5SoakTrace.prepare_fight_end_log()
