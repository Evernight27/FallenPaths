extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal enemies_eliminated(winner_side)
signal combatant_health_changed(combatant_id)
signal formation_changed(side)
signal engagement_state_changed(formation_id: String, line_cohesion: float, engagement_posture: String)
signal turn_resolved(combatant_id)  # Combatant has committed their action (attacked, skipped, swapped, etc.)
signal combat_ui_hint(message: String)

## Player side became ready to act; UI / TurnReadyHandler listen on `turn_ready`. Subsystems call this instead of `emit_signal` on the manager node.
func notify_turn_ready(combatant_id: int) -> void:
	emit_signal("turn_ready", combatant_id)

## Formation slots/ranks changed for `formation_id` (plug, pair resolve, rotate, death). Subsystems call this instead of `emit_signal` on the manager node.
## Vacancy reconcile: dirty-only (see `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`) or all formations each call. Then `_recompute_zoc_and_distance()` via follow-up if anything promoted.
## Emits `formation_changed` for the triggering side and for any other formation that changed.
func notify_formation_changed(formation_id: String) -> void:
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		mark_formation_vacancy_dirty(formation_id)
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(self)
	var reconciled_fids: Array = _FormationFlow.reconcile_vacancy_plugs(self)
	_FormationFlow.finish_vacancy_reconcile_follow_up(self, reconciled_fids, snap, false)
	emit_signal("formation_changed", formation_id)
	for rfid in reconciled_fids:
		if str(rfid) != formation_id:
			emit_signal("formation_changed", rfid)


func notify_engagement_state_changed(formation_id: String, line_cohesion: float, engagement_posture: String) -> void:
	emit_signal("engagement_state_changed", formation_id, line_cohesion, engagement_posture)
	if CombatDebug.flow_verbose_enabled():
		CombatDebug.flow_log(
			"engagement_state_changed fid=%s cohesion=%.3f posture=%s"
			% [formation_id, line_cohesion, engagement_posture],
			"engagement_state:%s" % formation_id
		)


func notify_combat_ui_hint(message: String) -> void:
	var m: String = str(message).strip_edges()
	if m.is_empty():
		return
	if has_meta(_META_LAST_COMBAT_UI_HINT) and str(get_meta(_META_LAST_COMBAT_UI_HINT, "")) == m:
		return
	set_meta(_META_LAST_COMBAT_UI_HINT, m)
	emit_signal("combat_ui_hint", m)


func mark_formation_vacancy_dirty(formation_id: String) -> void:
	if not CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		return
	var fk: String = str(formation_id)
	if fk.is_empty():
		return
	_vacancy_dirty_fids[fk] = true


func mark_all_formations_vacancy_dirty() -> void:
	if not CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		return
	for k in formations.keys():
		_vacancy_dirty_fids[str(k)] = true


var combatants := []
var medical_phase: bool = false
var medical_phase_winner: String = ""
# Event queue (min-heap), combat clock, encounter, formations.
# Hybrid: signals (`formation_changed`, `turn_resolved`, …) decide when to schedule; heap runs events at `resolve_at`.
var event_queue: Array = []
var combat_clock: float = 0.0
var encounter: Dictionary = {}
var formations: Dictionary = {}
## Per `formation_id` (e.g. player / enemy): `CombatConstants.DOCTRINE_*` — hybrid targeting + AI weights.
## Seeded in `start()`: defaults, then encounter doctrine via **`CombatConstants.encounter_formation_doctrine_string`**, then preset via **`CombatConstants.formation_doctrine_string_from_dict`** (**`FORMATION_PRESET_KEY_DOCTRINE`** + alt **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, wins per side); runtime changes via `set_formation_doctrine`.
var formation_doctrine: Dictionary = {}
## Per `formation_id`: merged depth-spear doctrine mults (**`CombatConstants.default_depth_polearm_ai_doctrine_mults_dict`** + encounter + preset at **`start()`**).
var depth_polearm_ai_doctrine_mults_by_fid: Dictionary = {}
## When `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`: keys are formation_id strings pending `reconcile_vacancy_plugs_formation` for that line only.
var _vacancy_dirty_fids: Dictionary = {}
var _combat_tick_index: int = 0

const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _StandingHelper := preload("res://combat/CombatStandingHelper.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
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
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")

## Consecutive duplicate `combat_ui_hint` lines suppressed (same string back-to-back across turns).
const _META_LAST_COMBAT_UI_HINT := "_fp_last_combat_ui_hint_dedupe"

## Scene combat node → health/wounds/stats holder (e.g. Character → CoreEntity). Subsystems should use **`CombatantEntityAccess.get_health_entity_from_node`** / **`get_entity_from_manager`**.
func get_health_entity(node: Node) -> Node:
	return _get_entity(node)


## Monotonic combat tick (**`CombatProcessTick`**); used for short-horizon AI signals (e.g. Tier **4.2** feint listing after **`parry_deflect`**).
func get_combat_tick_index() -> int:
	return _combat_tick_index


## Private implementation for **`get_health_entity`**; do not call from other classes.
func _get_entity(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e = node.get_medical_entity()
		return e if e != null else node
	return node


## Defender (or anyone) struck while in formation move: extend timer and event — does not cancel.
func apply_formation_hit_reaction_if_needed(combatant_id: int, intensity: float = 0.5) -> void:
	_FormationFlow.apply_hit_reaction_if_needed(self, combatant_id, intensity)

func _refresh_combatant_stats(c: Dictionary) -> void:
	"""Keep combatant stats in sync with node (pain, consciousness, blood, etc.) for UI and gauge fill.
	Uses get_health_entity / CombatantEntityAccess for unified health access (party Character -> CombatBody, enemies -> self)."""
	var n: Node = _EntityAccess.scene_node(c)
	if n == null:
		return
	var entity = _EntityAccess.get_health_entity_from_node(self, n)
	if entity == null:
		return
	_StatsSync.sync_from_entity(entity, _EntityAccess.stats_dict_for_mutation(c))

func register(node: Node, side: String) -> int:
	var id = combatants.size()
	var entity = _EntityAccess.get_health_entity_from_node(self, node)
	var stats = _StatsSync.sync_from_entity_for_register(entity if entity != null else node)
	var morale_c: float = 1.0
	if node != null:
		var raw_m: Variant = node.get("morale_cohesion")
		if raw_m != null:
			morale_c = clampf(float(raw_m), 0.0, 1.0)
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
		"doctrine_target_commit_id": -1,
		"doctrine_commit_until": 0.0,
		## defender_id -> combat_clock until which `attempt_close` vs that defender is logic-gated off (failed close backoff).
		"close_block_until_by_target_id": {},
		## Copied from character `is_party_leader` (player lead only); enemies always false.
		"is_party_leader": (side == "player" and node != null and node.get("is_party_leader") == true),
		## Tier 1.5: 0..1 input to side mean `morale_cohesion_factor` when encounter override absent; default neutral.
		"morale_cohesion": morale_c,
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
		var f: Dictionary = _FormationSlots.formation_record_read(formations, str(fid))
		if not f.is_empty():
			f["breached_files"] = {}
			_IntrusionWedge.clear_all_wedges_in_formation(f)
	if not formations.is_empty():
		_FormationEngagement.recompute_all(self)

## Start combat. Optional player_formation and enemy_formation presets: { files, ranks, density, optional **`CombatConstants.FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, … }.
## Clears **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on each combatant (Tier 4.2) so a second **`start()`** on the same manager does not carry feint telegraph from a prior encounter.
## When provided, builds formations and assigns rank/file to combatants (spawn order).
## Phase 4: Set encounter before start() for ZoC flags (e.g. CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE).
func start(player_formation: Dictionary = {}, enemy_formation: Dictionary = {}):
	CombatDebug.clear_flow_log_dedup()
	_combat_tick_index = 0
	_vacancy_dirty_fids.clear()
	medical_phase = false
	medical_phase_winner = ""
	event_queue.clear()
	combat_clock = 0.0
	CombatEngagementMode.clear_resolved_mode_cache(self)
	if has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		remove_meta(_TacticalCombat.META_COMBAT_TELEMETRY)
	var default_enc := {
		"ambush_type": CombatConstants.AMBUSH_TYPE_NONE,
		"ambush_penalty": 0.0,
		CombatConstants.ENCOUNTER_KEY_POSTURE_ENTER_DELTA: 0.0,
		CombatConstants.ENCOUNTER_KEY_POSTURE_LEAVE_DELTA: 0.0,
		CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT: "",
		CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER: {},
		CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY: {},
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
	formation_doctrine.clear()
	# Build formations from presets and assign rank/file (always; use defaults when preset empty)
	_FormationSetup.build_formations_and_assign_slots(self, player_formation, enemy_formation)
	mark_all_formations_vacancy_dirty()
	for fk in formations.keys():
		formation_doctrine[str(fk)] = CombatConstants.DOCTRINE_DEFAULT
	var doc_p0: String = CombatConstants.encounter_formation_doctrine_string(
		encounter,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if not doc_p0.is_empty():
		set_formation_doctrine("player", doc_p0)
	var doc_e0: String = CombatConstants.encounter_formation_doctrine_string(
		encounter,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT
	)
	if not doc_e0.is_empty():
		set_formation_doctrine("enemy", doc_e0)
	var doc_p1: String = CombatConstants.formation_doctrine_string_from_dict(
		player_formation,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if not doc_p1.is_empty():
		set_formation_doctrine("player", doc_p1)
	var doc_e1: String = CombatConstants.formation_doctrine_string_from_dict(
		enemy_formation,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if not doc_e1.is_empty():
		set_formation_doctrine("enemy", doc_e1)
	depth_polearm_ai_doctrine_mults_by_fid.clear()
	for _fk in formations.keys():
		var fks: String = str(_fk)
		var preset_side: Dictionary = (
			player_formation if fks == "player" else enemy_formation
		)
		depth_polearm_ai_doctrine_mults_by_fid[fks] = (
			CombatConstants.depth_polearm_ai_doctrine_mults_for_encounter_and_preset(
				encounter, preset_side, fks
			)
		)
	_reset_tactical_breach_state()
	if has_meta(_META_LAST_COMBAT_UI_HINT):
		remove_meta(_META_LAST_COMBAT_UI_HINT)
	# Tier 4.2: drop stale incoming feint telegraph on encounter (re)start — same combatant dicts may persist across `start()`.
	for c in combatants:
		if c is Dictionary:
			var cd: Dictionary = c as Dictionary
			cd.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
			cd.erase(CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK)
			cd.erase(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL)
			cd.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED)
			cd.erase(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT)
			cd.erase(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL)
			cd.erase(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_TARGET_ID)
			_FlurryBind.clear(cd)
			_MedicalPhase._reset_fled_and_combat_absent(cd)
			_Attention.clear_focus_and_yomi(cd)
			_Footwork.clear_position_offset(cd)
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
	CombatDebug.clear_flow_log_dedup()
	_vacancy_dirty_fids.clear()
	_reset_tactical_breach_state()
	medical_phase = false
	medical_phase_winner = ""
	if has_meta(_META_LAST_COMBAT_UI_HINT):
		remove_meta(_META_LAST_COMBAT_UI_HINT)
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
	if c == null or _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return
	if _MedicalPhase.combat_resolution_blocked(self) and _MedicalPhase.is_losing_side(self, c):
		return
	var extra: String = (" (%s)" % flow_reason) if not flow_reason.is_empty() else ""
	CombatDebug.flow_log(
		"skip_turn id=%d outcome=%s rank=%d%s" % [combatant_id, log_outcome, _EntityAccess.rank_int(c), extra],
		"skip_turn:%d" % combatant_id
	)
	emit_signal("action_resolved", combatant_id, combatant_id, {
		"outcome": log_outcome,
		"dmg": 0,
		"died": false,
		"rank": _EntityAccess.rank_int(c)
	})
	emit_signal("turn_resolved", combatant_id)
	c.gauge = 0.0
	var delay: float = CombatConstants.READY_DELAY_SKIP_DEFAULT_S
	if _EntityAccess.rank_int(c) > 0:
		# Back rank with no actions — wait in reserve (formation_changed reschedules promoted on plug).
		delay = CombatConstants.READY_DELAY_SKIP_BACK_RANK_S
	_schedule_action_ready(combatant_id, delay)

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	_reset_tactical_breach_state()
	var alive_by_side: Dictionary = {}
	for c in combatants:
		if _EntityAccess.alive_bool(c):
			var sd: String = _EntityAccess.side_str(c)
			alive_by_side[sd] = alive_by_side.get(sd, 0) + 1
	var def_node: String = str(defeated_node.name) if defeated_node != null else "null"
	print("[Combat] Phase end: winner=%s defeated_node=%s alive_by_side=%s" % [winner, def_node, alive_by_side])
	if winner == "enemy":
		print("[Combat] Enemy won => combat_ended, stopping manager")
		emit_signal("combat_ended", winner, defeated_node)
		stop()
	else:
		var fresh_medical: bool = not medical_phase
		if fresh_medical:
			print("[Combat] Player side won => medical_phase=true, enemies_eliminated")
		else:
			print("[Combat] Player side won => medical_phase refresh (teardown)")
		medical_phase = true
		medical_phase_winner = winner
		_halt_losing_side_combat()
		if fresh_medical:
			emit_signal("enemies_eliminated", winner)


## Player-win medical phase: cancel losing-side combat events and abort in-flight melee (no post-victory strikes).
func _halt_losing_side_combat() -> void:
	_MedicalPhase.halt_losing_side_combat(self)

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

## Ensures vacancy reconcile before listing actions. With dirty-only mode, marks **all** lines first so this stays a full pass (covers slot writes that skipped `notify_formation_changed`); per-frame tick uses dirty set only.
func get_available_actions(combatant_id: int) -> Array:
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		mark_all_formations_vacancy_dirty()
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(self)
	var changed_fids: Array = _FormationFlow.reconcile_vacancy_plugs(self)
	_FormationFlow.finish_vacancy_reconcile_follow_up(self, changed_fids, snap, true)
	var c_list: Variant = _get_by_id(combatant_id)
	if c_list is Dictionary:
		_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c_list as Dictionary)
	return _ActionsBuilder.build(self, combatant_id)


## Set tactical doctrine for one formation (player / enemy). Clears commitments on that line.
func set_formation_doctrine(formation_id: String, doctrine: String) -> void:
	var fid: String = str(formation_id)
	formation_doctrine[fid] = _Doctrine.normalize(doctrine)
	_Doctrine.clear_commitments_for_side(self, fid)
	var fd: Dictionary = _FormationSlots.formation_record_for_manager(self, fid)
	var coh: float = float(fd.get("line_cohesion", 1.0))
	var pst: String = str(fd.get("engagement_posture", ""))
	notify_engagement_state_changed(fid, coh, pst)


func get_formation_doctrine(formation_id: String) -> String:
	return _Doctrine.doctrine_for_fid(self, str(formation_id))


## Tier 1.9: effective depth-spear listing mult for **`key`** (`CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_*`) after encounter + preset merge at **`start()`**.
func get_depth_polearm_ai_doctrine_mult(formation_id: String, key: String) -> float:
	var fid: String = str(formation_id)
	var by_fid: Variant = depth_polearm_ai_doctrine_mults_by_fid.get(fid)
	if by_fid != null and by_fid is Dictionary:
		var d: Dictionary = by_fid as Dictionary
		if d.has(key):
			return float(d[key])
	var fallback: Dictionary = CombatConstants.default_depth_polearm_ai_doctrine_mults_dict()
	return float(fallback.get(key, 1.0))


func _process(delta: float) -> void:
	_ProcessTick.tick(self, delta)

## Resolves one chosen action. **Combat targeting is AI-driven:** `turn_ready` / `EVENT_ACTION_READY` build `get_available_actions`
## then `CombatAIActionPicker.pick` chooses move+target (player and enemy); there is no parallel human target-selection path.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var c_resolve: Variant = _get_by_id(attacker_id)
	if c_resolve is Dictionary:
		_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c_resolve as Dictionary)
	_ResolveAction.resolve(self, attacker_id, target_id, move_id, options)

func _execute_attack(attacker_id: int) -> void:
	if _MedicalPhase.combat_resolution_blocked(self):
		return
	var atk_exec = _get_by_id(attacker_id)
	if atk_exec != null and _MobilityRetreat.cannot_commit_melee(atk_exec):
		return
	var result: Dictionary = _AttackResolver.resolve_attack(self, attacker_id)
	_AttackResultApplier.apply_result(self, attacker_id, result)
	# Phase 3: Plug on death — when target died, update formation (slot_obstacles, promote rank 1 if rank 0 died).
	var tgt_id: int = result.get("target_id", -1)
	if tgt_id >= 0:
		var tgt = _get_by_id(tgt_id)
		if tgt != null and not _EntityAccess.alive_bool(tgt):
			_on_combatant_died(tgt)
	# Option D: CombatManager owns flow. After parry, defender gets EVENT_ACTION_READY.
	var action: String = result.get("action", "")
	if action in ["parry_deflect", "parry_partial"] and tgt_id >= 0:
		var tgt = _get_by_id(tgt_id)
		if (
			tgt != null
			and _EntityAccess.alive_bool(tgt)
			and _EntityAccess.state_str(tgt) == CombatConstants.STATE_WAITING
			and not _MobilityRetreat.cannot_commit_melee(tgt)
			and not (_MedicalPhase.combat_resolution_blocked(self) and _MedicalPhase.is_losing_side(self, tgt))
		):
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
	_TargetScoring.clear_all_targeting_state_for_dead_defender(self, _EntityAccess.id_int(c))
	_Footwork.clear_position_offset(c)
	_CounterTempo.clear_window(c)
	_Attention.clear_focus_and_yomi(c)
	c.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
	_FormationFlow.on_combatant_died(self, c)

func _get_by_id(id: int):
	for c in combatants:
		if _EntityAccess.id_int(c) == id:
			return c
	return null

func _find_first_opponent(side: String):
	return _StandingHelper.get_first_opponent(combatants, side)

func _check_for_winner() -> String:
	return _StandingHelper.get_winner(combatants)
