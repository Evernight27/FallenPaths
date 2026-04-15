extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal enemies_eliminated(winner_side)
signal combatant_health_changed(combatant_id)
signal formation_changed(side)
signal engagement_state_changed(formation_id: String, line_cohesion: float, engagement_posture: String)
signal turn_resolved(combatant_id)  # Combatant has committed their action (attacked, skipped, swapped, etc.)

## Player side became ready to act; UI / TurnReadyHandler listen on `turn_ready`. Subsystems call this instead of `emit_signal` on the manager node.
func notify_turn_ready(combatant_id: int) -> void:
	emit_signal("turn_ready", combatant_id)

## Formation slots/ranks changed for `formation_id` (plug, pair resolve, rotate, death). Subsystems call this instead of `emit_signal` on the manager node.
## Re-runs **vacancy plug** on every file of **both** formations (fills empty shallow cells when deeper non-intruded allies exist),
## then `_recompute_zoc_and_distance()` if anything promoted. Many callers already `_recompute_zoc_and_distance()` before this;
## that is safe and cheap when nothing moved. Emits `formation_changed` for the triggering side and for any other formation that changed.
func notify_formation_changed(formation_id: String) -> void:
	var reconciled_fids: Array = []
	for fk in formations.keys():
		if _FormationFlow.reconcile_vacancy_plugs_formation(self, str(fk)):
			reconciled_fids.append(str(fk))
	if not reconciled_fids.is_empty():
		_recompute_zoc_and_distance()
	emit_signal("formation_changed", formation_id)
	for rfid in reconciled_fids:
		if str(rfid) != formation_id:
			emit_signal("formation_changed", rfid)
	_FormationFlow.debug_verify_vacancy_invariants_after_reconcile(self)


func notify_engagement_state_changed(formation_id: String, line_cohesion: float, engagement_posture: String) -> void:
	emit_signal("engagement_state_changed", formation_id, line_cohesion, engagement_posture)
	if CombatConstants.COMBAT_EVENT_DEBUG:
		CombatDebug.flow_log(
			"engagement_state_changed fid=%s cohesion=%.3f posture=%s"
			% [formation_id, line_cohesion, engagement_posture]
		)

var combatants := []
var medical_phase: bool = false
var medical_phase_winner: String = ""
# Event queue (min-heap), combat clock, encounter, formations.
# Hybrid: signals (`formation_changed`, `turn_resolved`, …) decide when to schedule; heap runs events at `resolve_at`.
var event_queue: Array = []
var combat_clock: float = 0.0
var encounter: Dictionary = {}
var formations: Dictionary = {}

const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _StandingHelper := preload("res://combat/CombatStandingHelper.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _ProcessTick := preload("res://combat/CombatProcessTick.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationSetup := preload("res://combat/CombatFormationSetup.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _CombatantsSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")

## Returns the node that holds health/wounds (CoreEntity for enemies; CombatBody for Character). Use for all health reads.
func _get_entity(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e = node.get_medical_entity()
		return e if e != null else node
	return node


func _armor_mass_duration_multiplier_for_node(node: Node) -> float:
	if node == null:
		return 1.0
	var m: float = _EntityAccess.get_total_armor_mass_kg_from_node(node)
	var ref: float = CombatConstants.FORMATION_ARMOR_MASS_REF_KG
	var t: float = clampf(m / ref, 0.0, 1.5)
	return lerpf(1.0, CombatConstants.FORMATION_ARMOR_MAX_SLOW_MULT, t)


## Defender (or anyone) struck while in formation move: extend timer and event — does not cancel.
func apply_formation_hit_reaction_if_needed(combatant_id: int, intensity: float = 0.5) -> void:
	_FormationFlow.apply_hit_reaction_if_needed(self, combatant_id, intensity)

func _refresh_combatant_stats(c: Dictionary) -> void:
	"""Keep combatant stats in sync with node (pain, consciousness, blood, etc.) for UI and gauge fill.
	Uses _get_entity for unified health access (party Character -> CombatBody, enemies -> self)."""
	if c.node == null:
		return
	var entity = _get_entity(c.node)
	if entity == null:
		return
	_StatsSync.sync_from_entity(entity, c.stats)

func register(node: Node, side: String) -> int:
	var id = combatants.size()
	var entity = _get_entity(node)
	var stats = _StatsSync.sync_from_entity_for_register(entity if entity != null else node)
	combatants.append({
		"id": id,
		"node": node,
		"side": side,
		"stats": stats,
		"gauge": 0.0,
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"state_timer": 0.0,
		"state_duration": 0.0,
		"pending_attack": {},
		"receiving_medical_count": 0,
		"guard": 1.0,
		"guard_line": CombatConstants.GUARD_DEFAULT,
		"guard_zone": "head",
		"stamina": CombatConstants.STAMINA_MAX,
		# FF4 formation fields (Phase 0). Phase 3 assigns rank/file.
		"rank": 0,
		"file": 0,
		"formation_id": "",
		"distance_to": {},
		"engaged_with_id": -1,
		"engagement_angle": "front",
		"zone_id": "",
		"occupied_zone_id": "",
		"stance": CombatConstants.STANCE_BALANCED,
		"stance_preference": "balanced",
		# Incursion / breach (see docs/TACTICAL_ZONES_BREACH_MOVEMENT.md Phase B).
		"tactical_penetration_depth": 0,
		"crash_cooldown_until": 0.0,
		"engagement_role": CombatConstants.ENGAGEMENT_ROLE_LINE,
		"intrusion_host_fid": "",
		"intrusion_anchor_file": -1,
		"intrusion_source_file": -1,
		"lane_offset": CombatConstants.LANE_OFFSET_DEFAULT,
	})
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	# Connect creature_incapacitated: same refresh as health_changed when consciousness drops below threshold
	if entity != null and entity.has_signal("creature_incapacitated"):
		entity.creature_incapacitated.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

## Clears tactical breach / penetration (combat end, new encounter, medical phase handoff). Non-persisted fields (§10.3 B3).
func _reset_tactical_breach_state() -> void:
	for c in combatants:
		c["tactical_penetration_depth"] = 0
		c["crash_cooldown_until"] = 0.0
		c["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_LINE
		c["intrusion_host_fid"] = ""
		c["intrusion_anchor_file"] = -1
		c["intrusion_source_file"] = -1
		c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT
	for fid in formations.keys():
		var f: Dictionary = formations[fid]
		if not f.is_empty():
			f["breached_files"] = {}
			_IntrusionWedge.clear_all_wedges_in_formation(f)
	if not formations.is_empty():
		_FormationEngagement.recompute_all(self)

## Start combat. Optional player_formation and enemy_formation presets: { files, ranks, density }.
## When provided, builds formations and assigns rank/file to combatants (spawn order).
## Phase 4: Set encounter before start() for ZoC flags (e.g. CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE).
func start(player_formation: Dictionary = {}, enemy_formation: Dictionary = {}):
	medical_phase = false
	medical_phase_winner = ""
	event_queue.clear()
	combat_clock = 0.0
	var default_enc := {
		"ambush_type": CombatConstants.AMBUSH_TYPE_NONE,
		"ambush_penalty": 0.0,
		CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE: false,
		CombatConstants.ENCOUNTER_AMBUSHED_SIDE: "player",
	}
	if encounter.is_empty():
		encounter = default_enc.duplicate(true)
	else:
		for k in default_enc.keys():
			if not encounter.has(k):
				encounter[k] = default_enc[k]
	formations.clear()
	# Build formations from presets and assign rank/file (always; use defaults when preset empty)
	_FormationSetup.build_formations_and_assign_slots(self, player_formation, enemy_formation)
	_reset_tactical_breach_state()
	# Phase 1: Schedule initial EVENT_ACTION_READY for each alive combatant (staggered by agility).
	_schedule_initial_action_ready_events()
	set_process(true)

## Phase 4–6: Incursion pressure from front-rank imbalance, then zone control, assign zone_id, distance bands.
func _recompute_zoc_and_distance() -> void:
	_TacticalCombat.recompute_incursion_pressure(self)
	_ZoneOfControl.recompute_all(self)
	_DistanceBands.update_distance_to_from_formations(self)
	_FormationEngagement.recompute_all(self)

func _schedule_initial_action_ready_events() -> void:
	_EventScheduler.schedule_initial_action_ready_events(self)

func _action_ready_cooldown(c: Dictionary) -> float:
	return _EventScheduler.action_ready_cooldown(c)

func _schedule_event(ev: Dictionary) -> void:
	_EventScheduler.schedule_event(self, ev)

func stop():
	_reset_tactical_breach_state()
	set_process(false)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated (bandaged, packed, or tourniqueted). Used to gate "End battle" during medical phase.
func can_end_medical_phase() -> bool:
	return _MedicalPhase.can_end_medical_phase(self)

## True if combatant has any wounded part that is not comprehensively treated (bandaged, packed, or tourniqueted). Direct pressure alone does not count.
func _has_untreated_wounds(c: Dictionary) -> bool:
	return _MedicalPhase.has_untreated_wounds(self, c)

## Called when player clicks "End battle" during medical phase. Emits combat_ended and stops.
func finish_battle() -> void:
	print("[Combat] finish_battle: player clicked End battle, winner=%s" % medical_phase_winner)
	emit_signal("combat_ended", medical_phase_winner, null)
	stop()

## Resets a combatant's turn so they can "skip" when they have no available actions.
## Back rank (rank 1+) with no swap/melee: wait longer (reserve) to avoid spamming skip every 0.5s.
## formation_changed schedules ready for promoted units; they act soon after plug.
## log_outcome: "wait" = explicit pass; "pass" = no actions available (CombatLogFormatter).
func skip_turn(combatant_id: int, log_outcome: String = "pass", flow_reason: String = "") -> void:
	var c = _get_by_id(combatant_id)
	if c == null or c.state != CombatConstants.STATE_WAITING:
		return
	var extra: String = (" (%s)" % flow_reason) if not flow_reason.is_empty() else ""
	CombatDebug.flow_log("skip_turn id=%d outcome=%s rank=%d%s" % [combatant_id, log_outcome, c.get("rank", 0), extra])
	emit_signal("action_resolved", combatant_id, combatant_id, {
		"outcome": log_outcome,
		"dmg": 0,
		"died": false,
		"rank": c.get("rank", 0)
	})
	emit_signal("turn_resolved", combatant_id)
	c.gauge = 0.0
	var delay: float = CombatConstants.READY_DELAY_SKIP_DEFAULT_S
	if c.get("rank", 0) > 0:
		# Back rank with no actions — wait in reserve (formation_changed reschedules promoted on plug).
		delay = CombatConstants.READY_DELAY_SKIP_BACK_RANK_S
	_schedule_action_ready(combatant_id, delay)

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	_reset_tactical_breach_state()
	var alive_by_side: Dictionary = {}
	for c in combatants:
		if c.alive:
			alive_by_side[c.side] = alive_by_side.get(c.side, 0) + 1
	var def_node: String = str(defeated_node.name) if defeated_node != null else "null"
	print("[Combat] Phase end: winner=%s defeated_node=%s alive_by_side=%s" % [winner, def_node, alive_by_side])
	if winner == "enemy":
		print("[Combat] Enemy won => combat_ended, stopping manager")
		emit_signal("combat_ended", winner, defeated_node)
		stop()
	else:
		print("[Combat] Player side won => medical_phase=true, enemies_eliminated")
		medical_phase = true
		medical_phase_winner = winner
		emit_signal("enemies_eliminated", winner)

func get_combatants() -> Array:
	return _CombatantsSnapshot.build(self)

func _get_next_action_ready_at(combatant_id: int) -> float:
	return _EventScheduler.get_next_action_ready_at(self, combatant_id)

func _cancel_pending_action_ready(combatant_id: int) -> void:
	_EventScheduler.cancel_pending_action_ready(self, combatant_id)

func _schedule_action_ready(combatant_id: int, delay_s: float) -> void:
	_EventScheduler.schedule_action_ready(self, combatant_id, delay_s)

func _reschedule_back_rank_turns(fid: String) -> void:
	_EventScheduler.reschedule_back_rank_turns(self, fid)

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Attack moves (non-parry) and medical when in danger. Parry is passive only (A4v3).
func _is_in_medical_danger(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_medical_danger(self, c)

## Stricter than _is_in_medical_danger: about to bleed out. Must self-treat; cannot help others.
func _is_in_immediate_peril(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_immediate_peril(self, c)

## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).
func _has_left_immediate_peril_permanently(c: Dictionary) -> bool:
	return _MedicalPhase.has_left_immediate_peril_permanently(self, c)

func _get_medical_urgency(c: Dictionary) -> float:
	return _MedicalPhase.get_medical_urgency(self, c)

static func _is_medical_move(move_id: String) -> bool:
	return _ResolveAction.is_medical_move(move_id)

func _track_medical_failure_and_maybe_retry(performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	_MedicalCoord.track_failure_and_maybe_retry(self, performer, target, part, target_cid)

func _count_others_who_can_perform_medical_on_target(exclude_id: int, target_id: int) -> int:
	return _MedicalCoord.count_others_who_can_perform_medical_on_target(self, exclude_id, target_id)

func _get_parts_being_treated_on(combatant_id: int) -> Array:
	return _MedicalCoord.get_parts_being_treated_on(self, combatant_id)

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	return _MedicalPhase.get_ally_medical_actions(self, performer, ally, part)

## Ensures vacancy reconcile before listing actions (covers paths that mutated slots without `notify_formation_changed`). Idempotent when lines are full.
func get_available_actions(combatant_id: int) -> Array:
	if _FormationFlow.reconcile_vacancy_plugs_all_formations(self):
		_recompute_zoc_and_distance()
	return _ActionsBuilder.build(self, combatant_id)

func _process(delta: float) -> void:
	_ProcessTick.tick(self, delta)

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
# Phase 1: Event-driven; combatant is ready when EVENT_ACTION_READY fired (state == WAITING).
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	_ResolveAction.resolve(self, attacker_id, target_id, move_id, options)

func _execute_attack(attacker_id: int) -> void:
	var result: Dictionary = _AttackResolver.resolve_attack(self, attacker_id)
	_AttackResultApplier.apply_result(self, attacker_id, result)
	# Phase 3: Plug on death — when target died, update formation (slot_obstacles, promote rank 1 if rank 0 died).
	var tgt_id: int = result.get("target_id", -1)
	if tgt_id >= 0:
		var tgt = _get_by_id(tgt_id)
		if tgt != null and not tgt.alive:
			_on_combatant_died(tgt)
	# Option D: CombatManager owns flow. After parry, defender gets EVENT_ACTION_READY.
	var action: String = result.get("action", "")
	if action in ["parry_deflect", "parry_partial"] and tgt_id >= 0:
		var tgt = _get_by_id(tgt_id)
		if tgt != null and tgt.alive and tgt.state == CombatConstants.STATE_WAITING:
			_schedule_action_ready(tgt_id, CombatConstants.READY_DELAY_PARRY_RIPOSTE_S)

func _resolve_close_attempt(attacker_id: int, target_id: int) -> void:
	_EngagementResolver.resolve_close_attempt(self, attacker_id, target_id)


func _resolve_crash_attempt(attacker_id: int, defender_id: int) -> void:
	_EngagementResolver.resolve_crash_attempt(self, attacker_id, defender_id)


func _start_formation_pair_move(initiator_id: int, partner_id: int, move_kind: String) -> void:
	_FormationFlow.start_pair_move(self, initiator_id, partner_id, move_kind)


func _start_fall_back_solo(initiator_id: int) -> void:
	_FormationFlow.start_fall_back_solo(self, initiator_id)


func _start_rotate_file(initiator_id: int, partner_id: int) -> void:
	_FormationFlow.start_rotate_file(self, initiator_id, partner_id)


func _handle_swap_rank_resolve(ev: Dictionary) -> void:
	_FormationFlow.handle_swap_rank_resolve(self, ev)


func _handle_fall_back_solo_resolve(ev: Dictionary) -> void:
	_FormationFlow.handle_fall_back_solo_resolve(self, ev)


func _handle_rotate_file_resolve(ev: Dictionary) -> void:
	_FormationFlow.handle_rotate_file_resolve(self, ev)


func _on_combatant_died(c: Dictionary) -> void:
	_FormationFlow.on_combatant_died(self, c)

func _get_by_id(id: int):
	for c in combatants:
		if c.id == id:
			return c
	return null

func _find_first_opponent(side: String):
	return _StandingHelper.get_first_opponent(combatants, side)

func _check_for_winner() -> String:
	return _StandingHelper.get_winner(combatants)
