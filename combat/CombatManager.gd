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

## Combat orchestrator — turn loop, register combatants, vacancy/ZoC. WF spawn: **`CombatWeaponForm.seed_combatant_form`** at **`register_combatant`** + post-**`start()`** re-seed — LIVE_PATHS **`#spawn--reset-path-wf-1a`** · **`#wf-assign-form-contract`**. PA scrub: **`start()`** loop + **`_on_combatant_died`** — **`#wf-tier-44-pa`** (clear).

## Player side became ready to act; UI / TurnReadyHandler listen on `turn_ready`. Subsystems call this instead of `emit_signal` on the manager node.
func notify_turn_ready(combatant_id: int) -> void:
	emit_signal("turn_ready", combatant_id)

## Formation slots/ranks changed for `formation_id` (plug, pair resolve, rotate, death). Subsystems call this instead of `emit_signal` on the manager node.
## Vacancy reconcile: dirty-only (see `COMBAT_VACANCY_RECONCILE_DIRTY_ONLY`) or all formations each call. Then `_recompute_zoc_and_distance()` via follow-up if anything promoted.
## Emits `formation_changed` for the triggering side and for any other formation that changed.
## Snapshot → vacancy reconcile → ZoC/back-rank follow-up. Returns formation ids that changed.
func vacancy_reconcile_pass(emit_formation_changed_signals: bool) -> Array:
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(self)
	var changed_fids: Array = _FormationFlow.reconcile_vacancy_plugs(self)
	_FormationFlow.finish_vacancy_reconcile_follow_up(self, changed_fids, snap, emit_formation_changed_signals)
	return changed_fids


func notify_formation_changed(formation_id: String) -> void:
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		mark_formation_vacancy_dirty(formation_id)
	var reconciled_fids: Array = vacancy_reconcile_pass(false)
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


## `echo_to_fp`: when false, still emits **`combat_ui_hint`** for the battle log but skips **`FP_COMBAT: ui_hint`** (formation/hold lines use **`turn_ready_formation_line`** / gauge tooltip instead).
func notify_combat_ui_hint(message: String, echo_to_fp: bool = true) -> void:
	var m: String = str(message).strip_edges()
	if m.is_empty():
		return
	if has_meta(_META_LAST_COMBAT_UI_HINT) and str(get_meta(_META_LAST_COMBAT_UI_HINT, "")) == m:
		return
	set_meta(_META_LAST_COMBAT_UI_HINT, m)
	emit_signal("combat_ui_hint", m)
	if echo_to_fp and _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat("ui_hint %s" % m)


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
## Set on enemy-win `stop()` / `finish_battle()`; blocks duplicate `phase_end` when harness calls `_process()` manually.
var combat_resolution_closed: bool = false
# Event queue (min-heap), combat clock, encounter, formations.
# Hybrid: signals (`formation_changed`, `turn_resolved`, …) decide when to schedule; heap runs events at `resolve_at`.
var event_queue: Array = []
var combat_clock: float = 0.0
var encounter: Dictionary = {}
var formations: Dictionary = {}
## Per `formation_id` (e.g. player / enemy): `CombatConstants.DOCTRINE_*` — hybrid targeting + AI weights.
## Seeded in `start()` via **`CombatFormationSetup.seed_formation_doctrine_from_encounter_and_presets`** (encounter then preset; preset wins). Runtime: **`set_formation_doctrine`**.
var formation_doctrine: Dictionary = {}
## Per `formation_id`: depth-spear AI mults — **`CombatFormationSetup.seed_encounter_overlays_by_formation`** at **`start()`**; read **`get_depth_polearm_ai_doctrine_mult`**.
var depth_polearm_ai_doctrine_mults_by_fid: Dictionary = {}
## Per `formation_id`: rout gates — same seed pass; read **`get_rout_threshold`**.
var rout_thresholds_by_fid: Dictionary = {}
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
const _EngagementOpposition := preload("res://combat/EngagementOpposition.gd")
const _EngagementDiag := preload("res://combat/CombatEngagementDiagnostics.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _CombatantsSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")
const _FormationRout := preload("res://combat/CombatFormationRout.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _Doctrine := preload("res://combat/CombatDoctrine.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _BattleUIConstants := preload("res://ui/BattleUIConstants.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")

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
	if node != null and node.has_method("reset_combat_death_log"):
		node.reset_combat_death_log()
	var id = combatants.size()
	var entity = _EntityAccess.get_health_entity_from_node(self, node)
	var stats = _StatsSync.sync_from_entity_for_register(entity if entity != null else node)
	var camp_stamina: float = 1.0
	if entity != null and entity.has_method("get_campaign_stamina_mult"):
		camp_stamina = entity.get_campaign_stamina_mult()
	var morale_c: float = 1.0
	var stance_pref: String = ""
	if node != null:
		var raw_m: Variant = node.get("morale_cohesion")
		if raw_m != null:
			morale_c = clampf(float(raw_m), 0.0, 1.0)
		var raw_pref: Variant = node.get("stance_preference")
		if raw_pref != null:
			stance_pref = str(raw_pref).strip_edges()
	var leader_flags: Dictionary = _EntityAccess.leader_register_flags_from_node(node, side)
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
		CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0,
		CombatConstants.COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED: -1,
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
		"stance_preference": stance_pref,
		"engagement_role": CombatConstants.ENGAGEMENT_ROLE_LINE,
		"lane_offset": CombatConstants.LANE_OFFSET_DEFAULT,
		"doctrine_target_commit_id": -1,
		"doctrine_commit_until": 0.0,
		"close_block_until_by_target_id": {},
		"is_party_leader": leader_flags.get("is_party_leader", false),
		"is_enemy_leader": leader_flags.get("is_enemy_leader", false),
		"morale_cohesion": morale_c,
		"campaign_stamina_mult": camp_stamina,
	})
	_WeaponForm.seed_combatant_form(self, combatants[id] as Dictionary)
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	# Connect creature_incapacitated: same refresh as health_changed when consciousness drops below threshold
	if entity != null and entity.has_signal("creature_incapacitated"):
		entity.creature_incapacitated.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

## Resets per-combatant engagement fields (combat end, new encounter, medical phase handoff).
func _reset_tactical_engagement_state() -> void:
	for c in combatants:
		c["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_LINE
		c["lane_offset"] = CombatConstants.LANE_OFFSET_DEFAULT
	if not formations.is_empty():
		_FormationEngagement.recompute_all(self)

## Start combat. Optional player_formation and enemy_formation presets: { files, ranks, density, optional **`FORMATION_PRESET_KEY_DOCTRINE`** / **`FORMATION_PRESET_KEY_FLEE_*`**, … } — seeds **`rout_thresholds_by_fid`** and **`depth_polearm_ai_doctrine_mults_by_fid`** per side.
## Clears **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on each combatant (Tier 4.2) so a second **`start()`** on the same manager does not carry feint telegraph from a prior encounter.
## When provided, builds formations and assigns rank/file to combatants (spawn order).
## Phase 4: Set encounter before start() for ZoC flags (e.g. CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE).
func start(player_formation: Dictionary = {}, enemy_formation: Dictionary = {}):
	CombatDebug.clear_flow_log_dedup()
	_OperationalLog.reset_fight_fp_channel_dedupe()
	_WindUpStarter.reset_fp_session_dedup()
	_combat_tick_index = 0
	_vacancy_dirty_fids.clear()
	medical_phase = false
	medical_phase_winner = ""
	event_queue.clear()
	combat_clock = 0.0
	CombatEngagementMode.clear_resolved_mode_cache(self)
	if has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		remove_meta(_TacticalCombat.META_COMBAT_TELEMETRY)
	_EngagementOpposition.clear_opposition_meta(self)
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
		CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM: "",
		CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM: "",
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
	_EngagementOpposition.seed_from_formations(self)
	mark_all_formations_vacancy_dirty()
	for fk in formations.keys():
		formation_doctrine[str(fk)] = CombatConstants.DOCTRINE_DEFAULT
	_FormationSetup.seed_formation_doctrine_from_encounter_and_presets(
		self, encounter, player_formation, enemy_formation
	)
	_FormationSetup.seed_encounter_overlays_by_formation(
		self, encounter, player_formation, enemy_formation
	)
	_reset_tactical_engagement_state()
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
			cd.erase(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK)
			_FlurryBind.clear(cd)
			_MedicalPhase._reset_fled_and_combat_absent(cd)
			_Attention.clear_focus_and_yomi(cd)
			_Footwork.clear_on_exchange_end(cd)
			cd.erase(CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL)
			cd.erase(CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON)
			cd.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
			_WeaponForm.seed_combatant_form(self, cd)
	# III-4 PR2: one-shot reconcile + ZoC/bands before first action-ready (after opposition offset seed).
	vacancy_reconcile_pass(false)
	_recompute_zoc_and_distance()
	_FormationRout.stamp_standing_counts_at_start(self)
	combat_resolution_closed = false
	_connect_turn_resolved_depth_recheck()
	if has_meta("_d001_suppress_winner_check"):
		remove_meta("_d001_suppress_winner_check")
	# Phase 1: Schedule initial EVENT_ACTION_READY (IV-8 initiative stagger when enabled).
	_schedule_initial_action_ready_events()
	set_process(true)
	var alive_p: int = 0
	var alive_e: int = 0
	for c in combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.side_str(c) == "player":
			alive_p += 1
		else:
			alive_e += 1
	var eng_mode: String = CombatEngagementMode.engagement_mode(self)
	var eng_snap: Dictionary = CombatEngagementMode.snapshot(self)
	var eng_line: String = (
		"engagement mode=%s player_front=%d enemy_front=%d"
		% [
			CombatEngagementMode.mode_display_name(eng_mode),
			int(eng_snap.get("player_front", 0)),
			int(eng_snap.get("enemy_front", 0)),
		]
	)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat_manager_started(alive_p, alive_e, formation_doctrine, encounter)
		_OperationalLog.play_combat(eng_line)
	else:
		CombatDebug.combat_session(
			"manager_started alive=%d/%d doctrine=%s" % [alive_p, alive_e, str(formation_doctrine)]
		)
		CombatDebug.combat_session(eng_line)
	if has_meta(_EngagementOpposition.META_OPPOSITION_FILE_OFFSET_BY_SIDE):
		var pf: int = int((formations.get("player", {}) as Dictionary).get("files", 1))
		var ef: int = int((formations.get("enemy", {}) as Dictionary).get("files", 1))
		var opp_line: String = (
			"opposition offset player=%d enemy=%d formation_files=%d/%d"
			% [
				_EngagementOpposition.opposition_file_offset(self, "player"),
				_EngagementOpposition.opposition_file_offset(self, "enemy"),
				pf,
				ef,
			]
		)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_combat(opp_line)
			_EngagementDiag.log_fight_start_summary(self)
		else:
			CombatDebug.combat_session(opp_line)
	_TacticalCombat.seed_engagement_mode_telemetry(self, eng_mode)

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
	_EngagementOpposition.clear_opposition_meta(self)
	_reset_tactical_engagement_state()
	for c in combatants:
		if c is Dictionary:
			(c as Dictionary).erase(CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK)
	event_queue.clear()
	medical_phase = false
	medical_phase_winner = ""
	combat_resolution_closed = true
	if has_meta(_META_LAST_COMBAT_UI_HINT):
		remove_meta(_META_LAST_COMBAT_UI_HINT)
	set_process(false)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated (bandaged, packed, or tourniqueted). Used to gate "End battle" during medical phase.
func can_end_medical_phase() -> bool:
	return _MedicalPhase.can_end_medical_phase(self)

## Called when player ends battle during medical phase (soak: tick-replay; campaign: batch_resolve). Emits combat_ended and stops.
func finish_battle() -> void:
	var ran_fast_forward := _run_medical_fast_forward_on_exit_sync()
	_emit_finish_battle_and_stop(ran_fast_forward)


## Yields one frame after campaign batch_resolve; soak uses time-sliced tick-replay between frames.
func finish_battle_interactive() -> void:
	var ran_fast_forward := await _run_medical_fast_forward_on_exit_async()
	_emit_finish_battle_and_stop(ran_fast_forward)


func _run_medical_fast_forward_on_exit_sync() -> bool:
	if not medical_phase or can_end_medical_phase():
		return false
	set_process(false)
	if _is_campaign_contract_battle():
		_MedicalPhase.batch_resolve_on_campaign_exit(self)
	else:
		for _pass in range(3):
			_MedicalPhase.instant_complete_on_early_exit(self)
			if can_end_medical_phase():
				break
	_notify_incomplete_campaign_medical_fast_forward_if_needed()
	return true


func _run_medical_fast_forward_on_exit_async() -> bool:
	if not medical_phase or can_end_medical_phase():
		return false
	set_process(false)
	if _is_campaign_contract_battle():
		_MedicalPhase.batch_resolve_on_campaign_exit(self)
		if is_inside_tree():
			await get_tree().process_frame
	else:
		for pass_idx in range(3):
			await _run_interactive_medical_fast_forward_pass(-1.0)
			if can_end_medical_phase():
				break
			if _OperationalLog.is_play_session_active() and pass_idx + 1 < 3:
				_OperationalLog.play_combat(
					"medical_fast_forward pass=%d/%d can_end=false parts_left=%d"
					% [
						pass_idx + 1,
						3,
						_MedicalPhase.winner_side_untreated_part_count(self),
					]
				)
			if is_inside_tree():
				await get_tree().process_frame
	_notify_incomplete_campaign_medical_fast_forward_if_needed()
	return true


## Time-sliced fast-forward on **`CombatManager`** — full sim like sync exit, one frame budget per slice.
func _run_interactive_medical_fast_forward_pass(max_sim_seconds: float = -1.0) -> void:
	var sim_state: Dictionary = _MedicalPhase.fast_forward_prepare(self, max_sim_seconds)
	if sim_state.is_empty():
		return
	var sim_cap: float = float(sim_state["sim_cap"])
	var break_reason: String = "sim_cap"
	while true:
		var slice: Dictionary = _MedicalPhase.fast_forward_advance_time_slice(
			self,
			sim_state,
			sim_cap,
			_MedicalPhase.INTERACTIVE_FAST_FORWARD_FRAME_BUDGET_US
		)
		if not bool(slice.get("continue_loop", false)):
			break_reason = str(slice.get("break_reason", "sim_cap"))
			break
		if is_inside_tree():
			await get_tree().process_frame
	_MedicalPhase.fast_forward_finalize(self, sim_state, break_reason)


func _emit_finish_battle_and_stop(ran_fast_forward: bool) -> void:
	if combat_resolution_closed:
		return
	var can_end: bool = not medical_phase or can_end_medical_phase()
	var is_campaign: bool = _is_campaign_contract_battle()
	var used_batch_resolve: bool = ran_fast_forward and is_campaign
	if _OperationalLog.is_play_session_active() and is_campaign:
		_OperationalLog.play_combat(
			(
				"campaign_medical_exit can_end=%s fast_forward=%s batch_resolve=%s"
				% [
					str(can_end).to_lower(),
					str(ran_fast_forward).to_lower(),
					str(used_batch_resolve).to_lower(),
				]
			)
		)
	elif not _OperationalLog.is_play_session_active():
		CombatDebug.combat_session(
			"finish_battle medical exit winner=%s can_end=%s fast_forward=%s"
			% [medical_phase_winner, str(can_end).to_lower(), str(ran_fast_forward).to_lower()]
		)
	if _OperationalLog.is_play_session_active():
		_F5SoakTrace.flush_deferred_soak_coverage()
	emit_signal("combat_ended", medical_phase_winner, null)
	stop()


func _is_campaign_contract_battle() -> bool:
	return _CompanyState.is_campaign_contract_battle_world(_CompanyState.resolve_world_from_battle(self))


func _notify_incomplete_campaign_medical_fast_forward_if_needed() -> void:
	if can_end_medical_phase() or not _is_campaign_contract_battle():
		return
	if _OperationalLog.is_play_session_active():
		var parts_left: int = _MedicalPhase.winner_side_untreated_part_count(self)
		_OperationalLog.play_world(_CompanyState.format_post_fight_field_care_short_log(parts_left))
	else:
		notify_combat_ui_hint(_BattleUIConstants.CAMPAIGN_MEDICAL_FAST_FORWARD_INCOMPLETE_HINT, false)

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
		delay = CombatConstants.READY_DELAY_SKIP_BACK_RANK_S
		if _DepthPolearm.depth_polearm_lane_open(self, c):
			delay = CombatConstants.READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S
	_schedule_action_ready(combatant_id, delay)

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	if has_meta("_d001_suppress_winner_check"):
		return
	if not _MedicalPhase.should_apply_phase_end(self, winner):
		if not _OperationalLog.is_play_session_active():
			CombatDebug.combat_session(
				"phase_end locked during medical_phase (requested=%s locked=%s)"
				% [winner, medical_phase_winner]
			)
		return
	_reset_tactical_engagement_state()
	var alive_by_side: Dictionary = {}
	var fled_by_side: Dictionary = {}
	for c in combatants:
		var sd: String = _EntityAccess.side_str(c)
		if _EntityAccess.alive_bool(c):
			alive_by_side[sd] = alive_by_side.get(sd, 0) + 1
		if (
			bool(c.get("combat_absent", false))
			or _EntityAccess.state_str(c) == CombatConstants.STATE_FLED
		):
			fled_by_side[sd] = fled_by_side.get(sd, 0) + 1
	var standing_by_side: Dictionary = _StandingHelper.get_standing_by_side(combatants)
	var def_node: String = str(defeated_node.name) if defeated_node != null else "null"
	var fresh_medical: bool = winner == "player" and not medical_phase
	if fresh_medical or winner == "enemy":
		if not _OperationalLog.play_session_is_editor_f5():
			CombatDebug.combat_session(
				"phase_end winner=%s defeated_node=%s alive_by_side=%s standing_by_side=%s fled_by_side=%s"
				% [winner, def_node, alive_by_side, standing_by_side, fled_by_side]
			)
	if winner == "enemy":
		_F5SoakTrace.log_fight_end_summary(winner, false)
	elif fresh_medical:
		_F5SoakTrace.log_fight_end_summary(winner, true)
	if winner == "enemy":
		if not _OperationalLog.is_play_session_active():
			CombatDebug.combat_session("enemy won => combat_ended stopping manager")
		medical_phase = true
		medical_phase_winner = winner
		combat_resolution_closed = true
		emit_signal("combat_ended", winner, defeated_node)
		_halt_losing_side_combat()
		stop()
	else:
		if fresh_medical:
			if not _OperationalLog.is_play_session_active():
				CombatDebug.combat_session("player won => medical_phase enemies_eliminated")
			_F5SoakTrace.note_medical_phase_intro()
		elif not _OperationalLog.is_play_session_active():
			CombatDebug.combat_session("player won => medical_phase refresh (teardown)")
		medical_phase = true
		medical_phase_winner = winner
		combat_resolution_closed = true
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


func _connect_turn_resolved_depth_recheck() -> void:
	var cb := Callable(self, "_on_turn_resolved_same_file_depth_recheck")
	if not turn_resolved.is_connected(cb):
		turn_resolved.connect(cb)


func _on_turn_resolved_same_file_depth_recheck(combatant_id: int) -> void:
	_EventScheduler.reschedule_same_file_depth_after_front_turn(self, combatant_id)
	_EventScheduler.reschedule_same_file_depth_after_reserve_turn(self, combatant_id)

static func _is_medical_move(move_id: String) -> bool:
	return _ResolveAction.is_medical_move(move_id)

func _track_medical_failure_and_maybe_retry(performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	_MedicalCoord.track_failure_and_maybe_retry(self, performer, target, part, target_cid)

func _get_parts_being_treated_on(combatant_id: int) -> Array:
	return _MedicalCoord.get_parts_being_treated_on(self, combatant_id)

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	return _MedicalPhase.get_ally_medical_actions(self, performer, ally, part)

## Ensures vacancy reconcile before listing actions. With dirty-only mode, marks **all** lines first so this stays a full pass (covers slot writes that skipped `notify_formation_changed`); per-frame tick uses dirty set only.
func get_available_actions(combatant_id: int) -> Array:
	if CombatConstants.COMBAT_VACANCY_RECONCILE_DIRTY_ONLY:
		mark_all_formations_vacancy_dirty()
	vacancy_reconcile_pass(true)
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


## Tier 6.2: effective rout gate after encounter + preset merge at **`start()`** (defaults when unset).
func get_rout_threshold(formation_id: String, key: String) -> float:
	var fid: String = str(formation_id)
	var by_fid: Variant = rout_thresholds_by_fid.get(fid)
	if by_fid != null and by_fid is Dictionary:
		var d: Dictionary = by_fid as Dictionary
		if d.has(key):
			return float(d[key])
	match key:
		CombatConstants.ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX:
			return CombatConstants.FORMATION_FLEE_LINE_COHESION_MAX
		CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN:
			return CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN
	return 0.0


func _process(delta: float) -> void:
	_ProcessTick.tick(self, delta)

## Resolves one chosen action. **Combat targeting is AI-driven:** `turn_ready` / `EVENT_ACTION_READY` build `get_available_actions`
## then `CombatAIActionPicker.pick` chooses move+target (player and enemy); there is no parallel human target-selection path.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> bool:
	var c_resolve: Variant = _get_by_id(attacker_id)
	if c_resolve is Dictionary:
		_MobilityRetreat.sync_cowering_state_if_no_functional_arm(c_resolve as Dictionary)
	var committed: bool = _ResolveAction.resolve(self, attacker_id, target_id, move_id, options)
	if committed and c_resolve is Dictionary:
		(c_resolve as Dictionary)["last_committed_move_id"] = move_id
	return committed

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


## III-4 **3e**: depth fighter plug forward into rank-0 during envelop mop-up.
func _start_plug_forward(initiator_id: int, partner_id: int) -> void:
	_FormationFlow.start_plug_forward(self, initiator_id, partner_id)


func _handle_plug_forward_resolve(ev: Dictionary) -> void:
	_FormationFlow.handle_plug_forward_resolve(self, ev)


func _on_combatant_died(c: Dictionary) -> void:
	_TargetScoring.clear_all_targeting_state_for_dead_defender(self, _EntityAccess.id_int(c))
	_Footwork.clear_on_death(c)
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
	if has_meta("_d001_suppress_winner_check"):
		return ""
	return _StandingHelper.get_winner(combatants)
