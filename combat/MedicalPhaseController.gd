class_name MedicalPhaseController
extends RefCounted

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, ally medical actions, campaign **`batch_resolve_on_campaign_exit`**.
## Footing: halting wind-up on phase entry ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â€šÂ¬Ãƒâ€šÃ‚Â ' **`CombatFootwork.clear_on_exchange_end`** per combatant Ãƒâ€šÃ‚Â· **`return_to_waiting`** on idle reset ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â" LIVE_PATHS **`#wf-tier-44-pa`** (clear). Does **not** change **`weapon_form`** / home guard.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node) -> Node (or use CombatantEntityAccess).

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _MedicalCoord := preload("res://combat/CombatMedicalCoordination.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")

# Runtime preload Ã¢â‚¬â€ circular dependency (CompanyState Ã¢â€ â€™ CampaignEncounterBridge Ã¢â€ â€™ CombatantStatsSync Ã¢â€ â€™ MedicalPhaseController).
static var _CompanyState: Variant = null

static func _get_company_state() -> GDScript:
	if MedicalPhaseController._CompanyState == null:
		MedicalPhaseController._CompanyState = load("res://world/CompanyState.gd")
	return MedicalPhaseController._CompanyState

# Runtime preload Ã¢â‚¬â€ circular dependency (CounterTempo preloads MedicalPhaseController).
static var _counter_tempo_cache: Variant = null

static func _get_counter_tempo() -> GDScript:
	if _counter_tempo_cache == null:
		_counter_tempo_cache = load("res://combat/CounterTempo.gd")
	return _counter_tempo_cache
# Runtime preload — circular dependency (AttackWindUpStarter preloads MedicalPhaseController).
static var _wind_up_starter_cache: Variant = null

static func _get_wind_up_starter() -> GDScript:
	if _wind_up_starter_cache == null:
		_wind_up_starter_cache = load("res://combat/AttackWindUpStarter.gd")
	return _wind_up_starter_cache
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
# Runtime preload ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â circular dependency (CombatProcessTick preloads MedicalPhaseController).
static var _process_tick_cache: Variant = null

static func _get_process_tick() -> GDScript:
	if _process_tick_cache == null:
		_process_tick_cache = load("res://combat/CombatProcessTick.gd")
	return _process_tick_cache

const _Footwork := preload("res://combat/CombatFootwork.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _WindUpHandler := preload("res://combat/MedicalWindUpHandler.gd")
const _Proficiency := preload("res://core/EntityProficiency.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _CombatConstantsMedical := preload("res://combat/CombatConstantsMedical.gd")

## Set on **`CombatManager`** while fast-forwarding post-victory triage (player picks ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â€šÂ¬Ãƒâ€šÃ‚Â ' AI).
const MANAGER_META_MEDICAL_FAST_FORWARD := "_medical_phase_fast_forward"
const INSTANT_FAST_FORWARD_MAX_SECONDS: float = 7200.0
## Harness-only cap for sim_cap termination tests (`instant_complete_on_early_exit(mgr, cap)`).
const INSTANT_FAST_FORWARD_INTERACTIVE_MAX_SECONDS: float = 600.0
## Wall-clock budget per frame while interactive fast-forward runs on **`CombatManager`**.
const INTERACTIVE_FAST_FORWARD_FRAME_BUDGET_US: int = 22000
const INSTANT_FAST_FORWARD_STAGNANT_LIMIT: int = 48
const INSTANT_FAST_FORWARD_MAX_ITERATIONS: int = 100000
const INSTANT_FAST_FORWARD_MIN_STEP_S: float = 0.001
## Idle tick when queue has no resolve_at but triage work remains (avoids sim_s=0 stall).
const INSTANT_FAST_FORWARD_IDLE_STEP_S: float = 1.0
const INSTANT_FAST_FORWARD_YIELD_EVERY_TICKS: int = 12
## Campaign contract early exit: best-effort dress passes (fighters ÃƒÆ’Ã†â€™Ãƒâ€šÃ†â€™ -  wounds); not used for soak tick-replay.
const CAMPAIGN_BATCH_DRESS_MAX_ROUNDS: int = 256

## Queued events suppressed for the losing side once **`medical_phase`** is active.
const POST_VICTORY_BLOCKED_EVENT_TYPES: Array[String] = [
	CombatConstants.EVENT_MELEE_ATTACK,
	CombatConstants.EVENT_ACTION_READY,
	CombatConstants.EVENT_RECOVERY_END,
	CombatConstants.EVENT_SWAP_RANK_RESOLVE,
	CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
	CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
]

# AI / phase gating ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â" ATLS bands in BleedingConstants (docs/LIVE_PATHS.md#bleeding-units).
const MEDICAL_DANGER_BLOOD_THRESHOLD: float = _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
const MEDICAL_DANGER_SECONDS: float = _Bleeding.MEDICAL_TRIAGE_DANGER_SECONDS
const IMMEDIATE_PERIL_BLOOD_THRESHOLD: float = _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING
const IMMEDIATE_PERIL_SECONDS: float = _Bleeding.MEDICAL_TRIAGE_PERIL_SECONDS
const MEDICAL_URGENCY_WEIGHT_MAX: float = 6.0
const MEDICAL_URGENCY_RANDOM_MIN: float = 0.8
const MEDICAL_URGENCY_RANDOM_MAX: float = 1.2
# Medical AI (`CombatAIActionPicker`): deterministic triage + skill-shaped procedure choice.
const MEDICAL_AI_PART_THREAT_MULT := 2.8
const MEDICAL_AI_ADVANCED_SKILL_EXP := 1.7
const MEDICAL_AI_PRESSURE_LOW_SKILL_MULT := 1.42
const MEDICAL_AI_PRESSURE_HIGH_SKILL_MULT := 0.66
const MEDICAL_AI_EFF_CLAMP_MIN := 0.3
const MEDICAL_AI_EFF_CLAMP_MAX := 1.5
# TCCC hemorrhage-control ladder (relative weights; illegal options already omitted from listings).
const MEDICAL_AI_WEIGHT_PRESSURE_ACTIVE_BLEED: float = 5.0
const MEDICAL_AI_WEIGHT_TOURNIQUET_INDICATED: float = 4.5
const MEDICAL_AI_WEIGHT_PACK_BEFORE_PRESSURE: float = 0.25
const MEDICAL_AI_WEIGHT_BANDAGE_BEFORE_HEMOSTASIS: float = 0.20
const MEDICAL_AI_WEIGHT_PENDING_RETRY_PERIL: float = 4.0
const MEDICAL_AI_WEIGHT_PENDING_RETRY: float = 3.0
const MEDICAL_AI_WEIGHT_FAILED_PART_RETRY: float = 2.8
## Out of immediate peril: prefer definitive dressings (bandage/pack) over stabilize-only holds.
const MEDICAL_AI_WEIGHT_STABILIZE_OUT_OF_PERIL: float = 0.32
const MEDICAL_AI_WEIGHT_DRESSING_OUT_OF_PERIL: float = 2.6
## Listing/resolve overlap guard ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â" redundant pressure or another medicÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬ÂÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â‚¬Å¾Ãƒâ€šÃ‚Â¢s wind-up on the same part.
const MEDICAL_AI_WEIGHT_COORDINATION_BLOCKED: float = 0.001
## Second pair of hands on an ally-held wound (stack assist only; no takeover).
const MEDICAL_AI_WEIGHT_TREATMENT_ASSIST_PRESSURE: float = 3.5

## True once player-side victory: no new combat resolutions (medical triage only).
static func combat_resolution_blocked(manager: Node) -> bool:
	return manager != null and manager.medical_phase


## Post-victory medical phase: bleed-out / standing-count cannot reverse `medical_phase_winner`.
static func should_apply_phase_end(manager: Node, victor: String) -> bool:
	if manager == null or victor.is_empty():
		return false
	var _crc = manager.get("combat_resolution_closed")
	if (_crc as bool) == true and manager.medical_phase != true:
		return false
	if manager.medical_phase != true:
		return true
	return victor == str(manager.medical_phase_winner)


static func is_winner_side(manager: Node, c: Dictionary) -> bool:
	if manager == null or c == null or c.is_empty() or not manager.medical_phase:
		return false
	return _EntityAccess.is_on_side(c, str(manager.medical_phase_winner))


static func is_losing_side(manager: Node, c: Dictionary) -> bool:
	if manager == null or c == null or c.is_empty():
		return false
	if not manager.medical_phase:
		return false
	return not is_winner_side(manager, c)


static func is_losing_side_id(manager: Node, combatant_id: int) -> bool:
	if manager == null or combatant_id < 0:
		return false
	var c: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	return is_losing_side(manager, c)


## True when an event should not be queued for the losing side (or a pair touching them) during medical phase.
static func should_block_scheduled_event(manager: Node, ev: Dictionary) -> bool:
	if manager == null or not manager.medical_phase:
		return false
	var ev_type: String = ev.get("type", "")
	if ev_type not in POST_VICTORY_BLOCKED_EVENT_TYPES:
		return false
	var cid: int = int(ev.get("combatant_id", -1))
	if is_losing_side_id(manager, cid):
		return true
	if (
		ev_type == CombatConstants.EVENT_SWAP_RANK_RESOLVE
		or ev_type == CombatConstants.EVENT_ROTATE_FILE_RESOLVE
	):
		var dr: Variant = ev.get("data", null)
		if dr is Dictionary:
			var pid: int = int(dr.get("partner_id", -1))
			if is_losing_side_id(manager, pid):
				return true
	return false


## Formation resolve handlers: skip grid mutations for the losing side during medical phase.
static func should_skip_formation_resolve(manager: Node, initiator_id: int, partner_id: int = -1) -> bool:
	if not manager.medical_phase:
		return false
	if is_losing_side_id(manager, initiator_id):
		return true
	if partner_id >= 0 and is_losing_side_id(manager, partner_id):
		return true
	return false


## Remove any queued post-victory combat events for the losing side (and pairs touching them).
static func purge_blocked_events_from_queue(manager: Node) -> void:
	if manager == null or not manager.medical_phase:
		return
	manager.event_queue = manager.event_queue.filter(func(ev: Variant) -> bool:
		if ev is not Dictionary:
			return false
		return not should_block_scheduled_event(manager, ev)
	)


static func _reset_fled_and_combat_absent(c: Dictionary) -> void:
	c.erase("combat_absent")
	if _EntityAccess.state_str(c) == CombatConstants.STATE_FLED:
		_Footwork.return_to_waiting(c)
		c.state_timer = 0.0
		c.state_duration = 0.0


## Player-win medical phase: cancel losing-side combat, abort wind-ups, idle combat states.
static func halt_losing_side_combat(manager: Node) -> void:
	if manager == null or not manager.medical_phase:
		return
	var winner: String = manager.medical_phase_winner
	for c in manager.combatants:
		if _EntityAccess.is_on_side(c, winner):
			continue
		var cid: int = _EntityAccess.id_int(c)
		_EventScheduler.cancel_pending_combat_events_for_combatant(manager, cid)
		var st: String = _EntityAccess.state_str(c)
		if st == CombatConstants.STATE_WIND_UP:
			_get_counter_tempo().abort_attacker_wind_up(manager, cid)
			_EventScheduler.cancel_pending_recovery_end(manager, cid)
			_Footwork.return_to_waiting(c)
			c.gauge = 0.0
			continue
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		if not pa.is_empty():
			_get_wind_up_starter().clear_incoming_attack_telegraph_from_pa(manager, pa)
			_Footwork.clear_on_exchange_end(c)
			c.pending_attack = {}
		if st in [
			CombatConstants.STATE_RECOVERING,
			CombatConstants.STATE_SWAP_RANK,
			CombatConstants.STATE_FALLING_BACK,
			CombatConstants.STATE_MEDICAL_WIND_UP,
		]:
			_Footwork.return_to_waiting(c)
			c.gauge = 0.0
		c["pending_medical"] = {}
		c.erase("formation_move_partner_id")
		c.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
		c.erase("parry_was_bind")
		c.erase("parry_against_id")
		c.erase("parry_bonus_until")
		_get_counter_tempo().clear_window(c)
		_get_counter_tempo().clear_riposte_chain(c)
		_FlurryBind.clear(c)
		if c.get("combat_absent", false) or _EntityAccess.state_str(c) == CombatConstants.STATE_FLED:
			c["combat_absent"] = true
			c.state = CombatConstants.STATE_FLED
			_Footwork.reconcile_idle_offset(c)
	for c in manager.combatants:
		if not _EntityAccess.is_on_side(c, winner):
			continue
		_get_counter_tempo().clear_window(c)
		_get_counter_tempo().clear_riposte_chain(c)
		var had_fled: bool = (
			c.get("combat_absent", false)
			or _EntityAccess.state_str(c) == CombatConstants.STATE_FLED
		)
		_reset_fled_and_combat_absent(c)
		# Fled winners: triage needs them on-field (`is_alive_in_combat`); suspend bleed ticks only
		# (they left before victory ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â" wounds should not drain during post-victory medical phase).
		if had_fled:
			c[CombatConstants.COMBATANT_KEY_SUSPEND_BLEED_TICK] = true
	purge_blocked_events_from_queue(manager)


## Same threshold as bleed-out death (`CoreEntity._get_blood_loss_death_threshold` / `EntityWounds`).
static func _blood_loss_death_threshold_for_entity(entity: Node) -> float:
	return _EntityAccess.entity_blood_loss_death_threshold(entity)


## Max permanent bleed rate (abstract HP/s) that stays within clotting-safe buffer before death threshold.
static func _max_safe_permanent_bleed_rate(buffer_above_death: float) -> float:
	if buffer_above_death <= 0.0:
		return 0.0
	return (
		buffer_above_death
		* _Bleeding.CLOTTING_SAFE_EFFECTIVE_RATE
		/ _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	)


## Shared blood-volume + time-to-death urgency (x = blood band, y = time band).
static func _medical_urgency_components(
	blood_volume: float, death_threshold: float, bleed_rate: float
) -> Vector2:
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_threshold
	var urgency_blood: float = (
		1.0
		if blood_volume <= death_threshold
		else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - blood_volume) / maxf(0.01, range_bv), 0.0, 1.0)
	)
	var urgency_time: float = 0.0
	if bleed_rate > 0.0:
		var time_to_death: float = _Bleeding.seconds_to_exsanguination_at_death_threshold(
			bleed_rate, blood_volume, death_threshold, 1.0
		)
		if time_to_death < INF:
			urgency_time = (
				1.0
				if time_to_death <= 0.0
				else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
			)
	return Vector2(urgency_blood, urgency_time)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated.
static func can_end_medical_phase(manager: Node) -> bool:
	if not manager.medical_phase:
		return false
	for c in manager.combatants:
		if (
			not _EntityAccess.is_living_on_side(c, str(manager.medical_phase_winner))
			or _EntityAccess.scene_node(c) == null
		):
			continue
		if is_in_medical_danger(manager, c):
			return false
		if has_untreated_wounds(manager, c):
			return false
	return true


const _WINNER_TRIAGE_BUSY_STATES: Array[String] = [
	CombatConstants.STATE_WIND_UP,
	CombatConstants.STATE_MEDICAL_WIND_UP,
	CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
	CombatConstants.STATE_RECOVERING,
	CombatConstants.STATE_SWAP_RANK,
	CombatConstants.STATE_FALLING_BACK,
	CombatConstants.STATE_COWERING,
]


## True while any living winner-side fighter is mid-triage (procedure, gauge fill, or turn-ready with work left).
static func winner_side_triage_busy(manager: Node, combatants_scan: Array = []) -> bool:
	if manager == null or not manager.medical_phase:
		return false
	var winner_side: String = str(manager.medical_phase_winner)
	var scan: Array = combatants_scan if not combatants_scan.is_empty() else manager.combatants
	var can_end: bool = can_end_medical_phase(manager)
	for raw in scan:
		if raw is not Dictionary:
			continue
		var c: Dictionary = raw
		if not _EntityAccess.alive_bool(c, true):
			continue
		if _EntityAccess.side_str(c) != winner_side:
			continue
		var st: String = _EntityAccess.state_str(c)
		if st in _WINNER_TRIAGE_BUSY_STATES:
			return true
		if st == CombatConstants.STATE_WAITING:
			if _EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
				return true
			if not can_end:
				return true
	return false


## True if combatant has any wounded part not comprehensively treated (bandaged, packed, or tourniqueted).
static func winner_side_untreated_part_count(manager: Node) -> int:
	if manager == null:
		return 0
	var total: int = 0
	for c in manager.combatants:
		if not is_winner_side(manager, c):
			continue
		var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
		if entity == null:
			continue
		total += _EntityWounds.sorted_untreated_part_names(entity).size()
	return total


static func has_untreated_wounds(manager: Node, c: Dictionary) -> bool:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	return _EntityAccess.entity_has_untreated_wounds(entity)

## True when blood volume or estimated time to blood-loss death is in danger zone (consider medical).
static func is_in_medical_danger(manager: Node, c: Dictionary) -> bool:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	if bv <= MEDICAL_DANGER_BLOOD_THRESHOLD:
		return true
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate <= 0.0:
		return false
	var perm_rate: float = _EntityAccess.get_permanent_bleeding_rate_from_node(entity, rate)
	var death_thresh: float = _blood_loss_death_threshold_for_entity(entity)
	var buffer: float = bv - death_thresh
	if buffer > 0.0 and perm_rate > 0.0 and perm_rate <= _max_safe_permanent_bleed_rate(buffer):
		return false
	var time_to_death: float = _Bleeding.seconds_to_exsanguination_at_death_threshold(
		rate, bv, death_thresh, 1.0
	)
	return time_to_death <= MEDICAL_DANGER_SECONDS

## Stricter than is_in_medical_danger: about to bleed out; must self-treat first.
static func is_in_immediate_peril(manager: Node, c: Dictionary) -> bool:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	if bv <= IMMEDIATE_PERIL_BLOOD_THRESHOLD:
		return true
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate <= 0.0:
		return false
	var death_thresh_im: float = _blood_loss_death_threshold_for_entity(entity)
	var time_to_death: float = _Bleeding.seconds_to_exsanguination_at_death_threshold(
		rate, bv, death_thresh_im, 1.0
	)
	return time_to_death <= IMMEDIATE_PERIL_SECONDS

## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).
static func has_left_immediate_peril_permanently(manager: Node, c: Dictionary) -> bool:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	var perm_rate: float = _EntityAccess.get_permanent_bleeding_rate_from_node(entity, 0.0)
	if perm_rate <= _Bleeding.BLEEDING_RATE_EPSILON:
		return true
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	var death_thresh_pp: float = _blood_loss_death_threshold_for_entity(entity)
	var buffer: float = bv - death_thresh_pp
	if buffer > 0.0 and perm_rate <= _max_safe_permanent_bleed_rate(buffer):
		return true
	var time_to_death: float = _Bleeding.seconds_to_exsanguination_at_death_threshold(
		perm_rate, bv, death_thresh_pp, 1.0
	)
	if time_to_death >= INF:
		return true
	return time_to_death > IMMEDIATE_PERIL_SECONDS * 2.0


## True while **`instant_complete_on_early_exit`** simulates elapsed triage time (player side uses AI picks).
static func medical_fast_forward_active(manager: Node) -> bool:
	return (
		manager != null
		and manager.has_meta(MANAGER_META_MEDICAL_FAST_FORWARD)
		and bool(manager.get_meta(MANAGER_META_MEDICAL_FAST_FORWARD))
	)


## During fast-forward, player-side medical turns resolve via the same AI picker as enemies.
static func resolve_player_medical_turn_during_fast_forward(manager: Node, combatant_id: int) -> void:
	if manager == null or combatant_id < 0:
		return
	var actions: Array = manager.get_available_actions(combatant_id)
	_AIPicker.resolve_picked_turn_or_skip(manager, combatant_id, actions, "player")


## Campaign contract only: finish in-progress wind-ups + best-effort dress without tick-replay.
static func batch_resolve_on_campaign_exit(manager: Node) -> void:
	if manager == null or not manager.medical_phase or can_end_medical_phase(manager):
		return
	var parts_before: int = winner_side_untreated_part_count(manager)
	_batch_complete_in_progress_windups(manager)
	_batch_scrub_winner_busy_states_for_exit(manager)
	_batch_best_effort_dress_winner_side(manager)
	_log_batch_resolve_result(manager, parts_before)


static func _batch_complete_in_progress_windups(manager: Node) -> void:
	for c in manager.combatants:
		if c is not Dictionary:
			continue
		if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_MEDICAL_WIND_UP:
			continue
		var pm_raw: Variant = c.get("pending_medical", null)
		if pm_raw is not Dictionary:
			continue
		var pm: Dictionary = pm_raw
		if pm.is_empty():
			continue
		_WindUpHandler.complete(manager, c, pm)
		c["pending_medical"] = {}


static func _batch_scrub_winner_busy_states_for_exit(manager: Node) -> void:
	var _BUSY_EXIT_STATES: Array[String] = [
		CombatConstants.STATE_RECOVERING,
		CombatConstants.STATE_MEDICAL_WIND_UP,
	]
	for c in manager.combatants:
		if c is not Dictionary:
			continue
		if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
			continue
		var st: String = _EntityAccess.state_str(c)
		if st in _BUSY_EXIT_STATES:
			_Footwork.return_to_waiting(c)
			c.gauge = 100.0
		elif st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
			if c.get("receiving_medical_count", 0) <= 0:
				_Footwork.return_to_waiting(c)
				c.gauge = 100.0


static func _batch_best_effort_dress_winner_side(manager: Node) -> void:
	var rounds: int = 0
	while rounds < CAMPAIGN_BATCH_DRESS_MAX_ROUNDS and winner_side_untreated_part_count(manager) > 0:
		rounds += 1
		var targets: Array = _batch_collect_urgent_untreated_parts(manager)
		if targets.is_empty():
			break
		var progressed: bool = false
		for entry in targets:
			if entry is not Dictionary:
				continue
			var target_id: int = entry.get("target_id", -1)
			var part: String = entry.get("part", "")
			if target_id < 0 or part.is_empty():
				continue
			var performer_id: int = _batch_pick_performer_for_part(manager, target_id, part)
			if performer_id < 0:
				continue
			var actions: Array = _batch_medical_actions_for_part(manager, performer_id, target_id, part)
			actions = _MedicalCoord.filter_actions_for_pick(manager, performer_id, actions)
			if actions.is_empty():
				continue
			var choice: Dictionary = _AIPicker.pick_highest_medical(actions, performer_id, manager)
			if choice.is_empty():
				continue
			if _batch_apply_medical_action(
				manager,
				performer_id,
				int(choice.get("target_id", target_id)),
				choice.get("move_id", ""),
				str(choice.get("target_part", part))
			):
				progressed = true
				break
		if not progressed:
			break


static func _batch_collect_urgent_untreated_parts(manager: Node) -> Array:
	var out: Array = []
	for c in manager.combatants:
		if c is not Dictionary:
			continue
		if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
			continue
		if not has_untreated_wounds(manager, c):
			continue
		var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
		if entity == null:
			continue
		var cid: int = _EntityAccess.id_int(c)
		for part in _EntityWounds.sorted_untreated_part_names(entity):
			var urgency: float = get_medical_urgency_deterministic(manager, c)
			urgency += get_part_intervention_threat(manager, c, part)
			out.append({"target_id": cid, "part": part, "urgency": urgency})
	out.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a.get("urgency", 0.0) > b.get("urgency", 0.0)
	)
	return out


static func _batch_performer_available(manager: Node, c: Dictionary) -> bool:
	if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
		return false
	var st: String = _EntityAccess.state_str(c)
	return (
		st == CombatConstants.STATE_WAITING
		or st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION
		or st == CombatConstants.STATE_RECOVERING
	)


static func _batch_pick_performer_for_part(manager: Node, target_id: int, part: String) -> int:
	for c in manager.combatants:
		if c is not Dictionary:
			continue
		if not _batch_performer_available(manager, c):
			continue
		var performer_id: int = _EntityAccess.id_int(c)
		var actions: Array = _batch_medical_actions_for_part(manager, performer_id, target_id, part)
		if _MedicalCoord.filter_actions_for_pick(manager, performer_id, actions).is_empty():
			continue
		return performer_id
	return -1


static func _batch_medical_actions_for_part(
	manager: Node, performer_id: int, target_id: int, part: String
) -> Array:
	var performer: Dictionary = _EntityAccess.manager_get_combatant(manager, performer_id)
	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if performer.is_empty() or target.is_empty():
		return []
	var out: Array = []
	for raw_act in get_ally_medical_actions(manager, performer, target, part):
		if raw_act is not Dictionary:
			continue
		var act: Dictionary = raw_act
		out.append(
			{
				"target_id": target_id,
				"move_id": act.get("move_id", ""),
				"target_part": str(act.get("target_part", part)),
			}
		)
	return out


static func _batch_apply_medical_action(
	manager: Node,
	performer_id: int,
	target_id: int,
	move_id: String,
	part: String
) -> bool:
	if part.is_empty() or move_id.is_empty():
		return false
	if not _MedicalCoord.medical_action_allowed(manager, performer_id, target_id, part, move_id):
		return false
	var performer: Dictionary = _EntityAccess.manager_get_combatant(manager, performer_id)
	var target: Dictionary = _EntityAccess.manager_get_combatant(manager, target_id)
	if performer.is_empty() or target.is_empty():
		return false
	if move_id == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
		return _batch_apply_direct_pressure(manager, performer, target, performer_id, target_id, part)
	var wind_raw: Variant = _CombatConstantsMedical.MEDICAL_WIND_UP_CONFIG.get(move_id, {})
	var wind_up_cfg: Dictionary = wind_raw if wind_raw is Dictionary else {}
	var target_method: String = wind_up_cfg.get("target_method", "")
	if target_method.is_empty():
		return false
	var tgt_entity: Node = _EntityAccess.get_entity_from_manager(manager, target)
	var perf_entity: Node = _EntityAccess.get_entity_from_manager(manager, performer)
	if tgt_entity == null or perf_entity == null:
		return false
	var had_treatment_assist: bool = (
		tgt_entity.get("direct_pressure_assist_held_by") != null
		and tgt_entity.direct_pressure_assist_held_by != null
	)
	var eff: float = _EntityAccess.get_medical_effectiveness_from_node(perf_entity)
	if had_treatment_assist:
		eff += CombatConstants.MEDICAL_ASSISTED_TREATMENT_EFFICIENCY_BONUS
		eff = clampf(eff, 0.0, 1.5)
	var result: Variant = _EntityAccess.entity_invoke_medical_method(tgt_entity, target_method, part, eff)
	if result == null:
		return false
	var ok: bool = _batch_medical_procedure_succeeded(result)
	var who_m: String = _EntityAccess.get_display_name(performer)
	var med_log: String = move_id if target_id == performer_id else "%s (ally)" % move_id
	var outcome: String = _batch_outcome_for_method(target_method, result, wind_up_cfg, move_id)
	_CombatDebug.medical_session(
		"Medical batch: %s %s on %s => %s" % [who_m, med_log, part, outcome]
	)
	var world: Node2D = _get_company_state().resolve_world_from_battle(manager)
	if world != null:
		_get_company_state().on_battle_medical_complete(world, target_method, ok)
	if ok:
		var failed: Array = _EntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
		var idx: int = failed.find(part)
		if idx >= 0:
			failed.remove_at(idx)
		# XCamp-4: proficiency gains for batch medical actions.
		if _get_company_state().read_stub_proficiency_enabled():
			_Proficiency.award_stat_gain(perf_entity, "intelligence", _Proficiency.GAIN_MEDICAL_ACTION_BASE * _get_batch_item_mult(move_id))
			if perf_entity != tgt_entity and tgt_entity.has("_proficiency_bonus"):
				_Proficiency.award_stat_gain(tgt_entity, "endurance", _Proficiency.GAIN_BLOOD_PERIL_BASE * _Proficiency.GAIN_MEDICAL_PATIENT_END_MULT)
	else:
		var failed_mut: Array = _EntityAccess.nested_array_for_mutation(target, "failed_medical_parts")
		if part not in failed_mut:
			failed_mut.append(part)
	return ok


static func _batch_apply_direct_pressure(
	manager: Node,
	performer: Dictionary,
	target: Dictionary,
	performer_id: int,
	target_id: int,
	part: String
) -> bool:
	var applied: bool = false
	if target_id == performer_id:
		applied = _EntityAccess.entity_apply_direct_pressure(manager, target, part)
	elif _MedicalCoord.can_stack_assist_pressure(manager, performer_id, target_id, part):
		applied = _EntityAccess.entity_stack_assist_pressure_during_ally_treatment(
			manager, target, performer, part
		)
	elif _EntityAccess.entity_apply_direct_pressure_from_ally(manager, target, performer, part):
		applied = true
		_EntityAccess.link_performer_direct_pressure_on_ally(
			manager,
			performer,
			_EntityAccess.get_entity_from_manager(manager, target),
			part
		)
	if applied:
		_CombatDebug.medical_session(
			"Medical batch: %s apply_direct_pressure on %s => held"
			% [_EntityAccess.get_display_name(performer), part]
		)
		# XCamp-4: proficiency gains for batch direct pressure.
		if _get_company_state().read_stub_proficiency_enabled():
			var perf_entity = _EntityAccess.get_entity_from_manager(manager, performer)
			var tgt_entity = _EntityAccess.get_entity_from_manager(manager, target)
			if perf_entity != null and perf_entity.has("_proficiency_bonus"):
				_Proficiency.award_stat_gain(perf_entity, "intelligence", _Proficiency.GAIN_MEDICAL_ACTION_BASE * _Proficiency.GAIN_DIRECT_PRESSURE_INT_MULT)
			if tgt_entity != null and tgt_entity.has("_proficiency_bonus"):
				_Proficiency.award_stat_gain(tgt_entity, "endurance", _Proficiency.GAIN_BLOOD_PERIL_BASE * _Proficiency.GAIN_DIRECT_PRESSURE_PATIENT_END_MULT)
	return applied


static func _batch_medical_procedure_succeeded(result: Variant) -> bool:
	if result == true:
		return true
	if result is Dictionary:
		return result.get("success", false)
	return false


static func _batch_outcome_for_method(
	target_method: String, result: Variant, wind_up_cfg: Dictionary, med_id: String
) -> String:
	var ok: bool = _batch_medical_procedure_succeeded(result)
	var outcome := CombatConstants.medical_outcome_string(target_method, ok)
	if outcome != "":
		return outcome
	return str(wind_up_cfg.get("outcome", med_id))


## Returns the medical item type multiplier for batch resolve proficiency gains.
static func _get_batch_item_mult(move_id: String) -> float:
	match move_id:
		_CombatConstants.MOVE_ID_BANDAGE_SELF, _CombatConstants.MOVE_TARGET_APPLY_BANDAGE:
			return _Proficiency.get_medical_item_mult("bandage")
		_CombatConstants.MOVE_ID_PACK_WOUND, _CombatConstants.MOVE_TARGET_APPLY_PACKING, _CombatConstants.MOVE_TARGET_APPLY_STABILIZE, _CombatConstants.MOVE_ID_STABILIZE_WOUND:
			return _Proficiency.get_medical_item_mult("pack")
		_CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
			return _Proficiency.get_medical_item_mult("tourniquet")
		_:
			return 1.0


static func _log_batch_resolve_result(manager: Node, parts_before: int) -> void:
	var parts_after: int = winner_side_untreated_part_count(manager)
	var can_end: bool = can_end_medical_phase(manager)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_combat(
			(
				"medical_batch_resolve parts_before=%d parts_after=%d can_end=%s"
				% [parts_before, parts_after, str(can_end).to_lower()]
			)
		)
	elif not can_end:
		_CombatDebug.combat_session(
			"batch_resolve_medical_phase parts_before=%d parts_after=%d can_end=false"
			% [parts_before, parts_after]
		)


## When the player ends battle during medical phase, advance **`combat_clock`** through the tick pipeline until triage finishes.
static func instant_complete_on_early_exit(manager: Node, max_sim_seconds: float = -1.0) -> void:
	var sim_state: Dictionary = fast_forward_prepare(manager, max_sim_seconds)
	if sim_state.is_empty():
		return
	var break_reason: String = _fast_forward_drive_sync(manager, sim_state)
	fast_forward_finalize(manager, sim_state, break_reason)


static func fast_forward_prepare(manager: Node, max_sim_seconds: float) -> Dictionary:
	if manager == null or not manager.medical_phase or can_end_medical_phase(manager):
		return {}
	manager.set_meta(MANAGER_META_MEDICAL_FAST_FORWARD, true)
	return {
		"sim_seconds": 0.0,
		"stagnant_steps": 0,
		"total_iterations": 0,
		"sim_cap": _instant_complete_sim_cap(max_sim_seconds),
	}


static func _fast_forward_drive_sync(manager: Node, sim_state: Dictionary) -> String:
	var break_reason: String = "sim_cap"
	while true:
		var chunk: Dictionary = fast_forward_advance_chunk(
			manager,
			sim_state,
			float(sim_state["sim_cap"]),
			INSTANT_FAST_FORWARD_MAX_ITERATIONS
		)
		if chunk.get("continue_loop", false) != true:
			break_reason = str(chunk.get("break_reason", "sim_cap"))
			break
	return break_reason


static func fast_forward_advance_chunk(
	manager: Node,
	sim_state: Dictionary,
	sim_cap: float,
	max_chunk_iters: int
) -> Dictionary:
	if manager == null or not manager.medical_phase:
		return {
			"continue_loop": false,
			"break_reason": "medical_phase_cleared",
		}
	var iters_run: int = 0
	while (
		manager.medical_phase
		and not can_end_medical_phase(manager)
		and float(sim_state["sim_seconds"]) < sim_cap
		and iters_run < max_chunk_iters
	):
		iters_run += 1
		var total_iterations: int = sim_state.get("total_iterations", 0) + 1
		sim_state["total_iterations"] = total_iterations
		if total_iterations > INSTANT_FAST_FORWARD_MAX_ITERATIONS:
			return {
				"continue_loop": false,
				"break_reason": "iteration_cap",
			}
		var step: Dictionary = _instant_complete_fast_forward_step(manager, sim_state)
		if step.get("continue_loop", true) != true:
			return {
				"continue_loop": false,
				"break_reason": "stagnant",
			}
	if can_end_medical_phase(manager):
		return {
			"continue_loop": false,
			"break_reason": "complete",
		}
	if float(sim_state["sim_seconds"]) >= sim_cap:
		return {
			"continue_loop": false,
			"break_reason": "sim_cap",
		}
	return {
		"continue_loop": true,
		"break_reason": "",
	}


## Run fast-forward steps until **`budget_usec`** elapses or the pass ends (interactive time-slice).
static func fast_forward_advance_time_slice(
	manager: Node,
	sim_state: Dictionary,
	sim_cap: float,
	budget_usec: int
) -> Dictionary:
	if manager == null or not manager.medical_phase:
		return {
			"continue_loop": false,
			"break_reason": "medical_phase_cleared",
		}
	var slice_start_usec: int = Time.get_ticks_usec()
	while (
		manager.medical_phase
		and not can_end_medical_phase(manager)
		and float(sim_state["sim_seconds"]) < sim_cap
	):
		if Time.get_ticks_usec() - slice_start_usec >= budget_usec:
			return {
				"continue_loop": true,
				"break_reason": "",
			}
		var total_iterations: int = sim_state.get("total_iterations", 0) + 1
		sim_state["total_iterations"] = total_iterations
		if total_iterations > INSTANT_FAST_FORWARD_MAX_ITERATIONS:
			return {
				"continue_loop": false,
				"break_reason": "iteration_cap",
			}
		var step: Dictionary = _instant_complete_fast_forward_step(manager, sim_state)
		if step.get("continue_loop", true) != true:
			return {
				"continue_loop": false,
				"break_reason": "stagnant",
			}
	if can_end_medical_phase(manager):
		return {
			"continue_loop": false,
			"break_reason": "complete",
		}
	if float(sim_state["sim_seconds"]) >= sim_cap:
		return {
			"continue_loop": false,
			"break_reason": "sim_cap",
		}
	return {
		"continue_loop": true,
		"break_reason": "",
	}


static func fast_forward_finalize(
	manager: Node,
	sim_state: Dictionary,
	break_reason: String
) -> void:
	if manager == null or not is_instance_valid(manager):
		return
	_clear_instant_complete_fast_forward_meta(manager)
	_log_instant_complete_result(manager, sim_state, break_reason)


static func _instant_complete_sim_cap(max_sim_seconds: float) -> float:
	return (
		INSTANT_FAST_FORWARD_MAX_SECONDS
		if max_sim_seconds < 0.0
		else maxf(max_sim_seconds, INSTANT_FAST_FORWARD_MIN_STEP_S)
	)


static func _clear_instant_complete_fast_forward_meta(manager: Node) -> void:
	if manager.has_meta(MANAGER_META_MEDICAL_FAST_FORWARD):
		manager.remove_meta(MANAGER_META_MEDICAL_FAST_FORWARD)


## One fast-forward iteration. Mutates **`sim_state`** (`sim_seconds`, `stagnant_steps`).
static func _instant_complete_fast_forward_step(manager: Node, sim_state: Dictionary) -> Dictionary:
	_ensure_winner_recovery_end_events(manager)
	var dt: float = _next_fast_forward_delta(manager)
	var stagnant_steps: int = sim_state.get("stagnant_steps", 0)
	var sim_seconds: float = sim_state.get("sim_seconds", 0.0)
	if dt <= 0.0:
		if _resolve_stalled_winner_turns(manager):
			# Advance clock on turn picks; otherwise sim_s never moves and the loop can spin forever.
			_get_process_tick().tick(manager, INSTANT_FAST_FORWARD_MIN_STEP_S)
			sim_seconds += INSTANT_FAST_FORWARD_MIN_STEP_S
			sim_state["sim_seconds"] = sim_seconds
			sim_state["stagnant_steps"] = 0
			return {"continue_loop": true, "stepped": true}
		if winner_side_untreated_part_count(manager) > 0:
			_get_process_tick().tick(manager, INSTANT_FAST_FORWARD_IDLE_STEP_S)
			sim_seconds += INSTANT_FAST_FORWARD_IDLE_STEP_S
			sim_state["sim_seconds"] = sim_seconds
			sim_state["stagnant_steps"] = 0
			return {"continue_loop": true, "stepped": true}
		stagnant_steps += 1
		sim_state["stagnant_steps"] = stagnant_steps
		if stagnant_steps >= INSTANT_FAST_FORWARD_STAGNANT_LIMIT:
			if _unstick_medical_turns(manager):
				sim_state["stagnant_steps"] = 0
				return {"continue_loop": true, "stepped": false}
			return {"continue_loop": false, "stepped": false}
		# Nudge clock while waiting for wind-ups / recovery to produce the next delta.
		_get_process_tick().tick(manager, INSTANT_FAST_FORWARD_MIN_STEP_S)
		sim_state["sim_seconds"] = sim_seconds + INSTANT_FAST_FORWARD_MIN_STEP_S
		return {"continue_loop": true, "stepped": true}
	sim_state["stagnant_steps"] = 0
	_get_process_tick().tick(manager, dt)
	sim_state["sim_seconds"] = sim_seconds + dt
	return {"continue_loop": true, "stepped": true}


static func _log_instant_complete_result(
	manager: Node,
	sim_state: Dictionary,
	break_reason: String = "sim_cap"
) -> void:
	var sim_seconds: float = sim_state.get("sim_seconds", 0.0)
	var total_iterations: int = sim_state.get("total_iterations", 0)
	var can_end: bool = can_end_medical_phase(manager)
	var reason: String = break_reason if not break_reason.is_empty() else "sim_cap"
	if _OperationalLog.is_play_session_active():
		if can_end:
			_OperationalLog.play_combat(
				(
					"medical_fast_forward complete sim_s=%.1f can_end=true parts_left=%d "
					+ "iters=%d reason=%s"
				)
				% [sim_seconds, winner_side_untreated_part_count(manager), total_iterations, reason]
			)
		else:
			_OperationalLog.play_combat(
				(
					"medical_fast_forward incomplete sim_s=%.1f can_end=false parts_left=%d "
					+ "iters=%d reason=%s ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â field care may still be needed"
				)
				% [sim_seconds, winner_side_untreated_part_count(manager), total_iterations, reason]
			)
	elif not can_end:
		_CombatDebug.combat_session(
			"fast_forward_medical_phase sim_s=%.1f can_end=false iters=%d reason=%s"
			% [sim_seconds, total_iterations, reason]
		)


static func _next_fast_forward_delta(manager: Node) -> float:
	var clock: float = _EntityAccess.combat_clock_float(manager)
	var best: float = INF
	for raw in manager.event_queue:
		if raw is not Dictionary:
			continue
		var ev: Dictionary = raw
		if should_block_scheduled_event(manager, ev):
			continue
		var resolve_at: float = float(ev.get("resolve_at", INF))
		if resolve_at > clock:
			best = minf(best, resolve_at - clock)
	for c in manager.combatants:
		if not is_winner_side(manager, c):
			continue
		var st: String = _EntityAccess.state_str(c)
		if st == CombatConstants.STATE_MEDICAL_WIND_UP:
			var wind_rem: float = c.get("state_duration", 0.0) - c.get("state_timer", 0.0)
			if wind_rem > 0.0:
				best = minf(best, wind_rem)
			else:
				best = minf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)
		elif st == CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION:
			var cd: float = c.get("receiving_care_action_cooldown", 0.0)
			if cd > 0.0:
				best = minf(best, cd)
			else:
				best = minf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)
		elif st == CombatConstants.STATE_WAITING:
			if _EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
				best = minf(best, INSTANT_FAST_FORWARD_IDLE_STEP_S)
	if best == INF:
		if winner_side_untreated_part_count(manager) > 0:
			return INSTANT_FAST_FORWARD_IDLE_STEP_S
		return 0.0
	return maxf(best, INSTANT_FAST_FORWARD_MIN_STEP_S)


static func _has_pending_recovery_end(manager: Node, combatant_id: int) -> bool:
	for raw in manager.event_queue:
		if raw is not Dictionary:
			continue
		var ev: Dictionary = raw
		if (
			ev.get("type", "") == CombatConstants.EVENT_RECOVERY_END
			and int(ev.get("combatant_id", -1)) == combatant_id
		):
			return true
	return false


static func _ensure_winner_recovery_end_events(manager: Node) -> void:
	for c in manager.combatants:
		if not is_winner_side(manager, c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_RECOVERING:
			continue
		var cid: int = _EntityAccess.id_int(c)
		if _has_pending_recovery_end(manager, cid):
			continue
		var remaining: float = maxf(
			0.0, c.get("state_duration", 0.0) - c.get("state_timer", 0.0)
		)
		_EntityAccess.manager_schedule_event(
			manager,
			{
				"type": CombatConstants.EVENT_RECOVERY_END,
				"combatant_id": cid,
				"resolve_at": _EntityAccess.combat_clock_plus(manager, remaining),
				"data": {},
			}
		)


## Unstick winner turns stuck at partial gauge or empty pick during fast-forward triage.
static func _unstick_medical_turns(manager: Node) -> bool:
	var unstick: bool = false
	for c in manager.combatants:
		if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
			c.gauge = 100.0
			unstick = true
	if _resolve_stalled_winner_turns(manager):
		return true
	return unstick


static func _resolve_stalled_winner_turns(manager: Node) -> bool:
	var acted: bool = false
	for c in manager.combatants:
		if not is_winner_side(manager, c) or not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
			continue
		if _EntityAccess.gauge_float(c) < CombatConstants.GAUGE_FULL_THRESHOLD:
			continue
		var cid: int = _EntityAccess.id_int(c)
		var actions: Array = manager.get_available_actions(cid)
		actions = _MedicalCoord.filter_actions_for_pick(manager, cid, actions)
		if actions.is_empty():
			continue
		_AIPicker.resolve_picked_turn_or_skip(manager, cid, actions, "player")
		acted = true
	return acted


## 0..1: higher when more hurt (lower blood, shorter time to death). Includes randomness.
static func get_medical_urgency(manager: Node, c: Dictionary) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var comps: Vector2 = _medical_urgency_components(
		_EntityAccess.get_blood_volume_from_node(entity),
		_blood_loss_death_threshold_for_entity(entity),
		_EntityAccess.get_total_bleeding_rate_from_node(entity)
	)
	var raw: float = maxf(comps.x, comps.y)
	raw *= randf_range(MEDICAL_URGENCY_RANDOM_MIN, MEDICAL_URGENCY_RANDOM_MAX)
	return clampf(raw, 0.0, 1.0)

## Same blood/time urgency as `get_medical_urgency` but **no randomness** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â used for medical action weights so triage is stable.
static func get_medical_urgency_deterministic(manager: Node, c: Dictionary) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var comps: Vector2 = _medical_urgency_components(
		_EntityAccess.get_blood_volume_from_node(entity),
		_blood_loss_death_threshold_for_entity(entity),
		_EntityAccess.get_total_bleeding_rate_from_node(entity)
	)
	return clampf(maxf(comps.x, comps.y), 0.0, 1.0)

## Higher = intervene on this part before milder wounds (bleed rate + severity + arterial/stump + tourniquet indication).
static func get_part_intervention_threat(manager: Node, c: Dictionary, part: String) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	return _EntityWounds.get_part_intervention_threat(entity, part)

static func _append_pressure_action_if_needed(
	manager: Node,
	performer: Dictionary,
	ally: Dictionary,
	part: String,
	has_pressure: bool,
	actively_bleeding: bool,
	out: Array
) -> void:
	if not actively_bleeding:
		return
	if (
		not _EntityAccess.scene_can_apply_direct_pressure_api(performer)
		or _EntityAccess.is_applying_direct_pressure_scene(performer)
	):
		return
	if (
		_EntityAccess.id_int(performer) == _EntityAccess.id_int(ally)
		and not _EntityAccess.entity_can_apply_direct_pressure(manager, ally, part)
	):
		return
	var performer_id: int = _EntityAccess.id_int(performer)
	var ally_id: int = _EntityAccess.id_int(ally)
	if has_pressure:
		if _MedicalCoord.can_stack_assist_pressure(manager, performer_id, ally_id, part):
			out.append({
				"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, "target_part": part
			})
		return
	if not _MedicalCoord.medical_action_allowed(
		manager, performer_id, ally_id, part, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
	):
		return
	out.append({"move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, "target_part": part})


## Returns list of { move_id, target_part } for medical actions the performer can apply to the ally's part.
## TCCC: dressings only when bleed is controlled or compression is on the part.
static func dressings_allowed_for_part(manager: Node, ally: Dictionary, part: String) -> bool:
	if part.is_empty():
		return false
	var bleed_rate: float = _EntityAccess.entity_bleeding_rate_for_part(manager, ally, part)
	var actively_bleeding: bool = bleed_rate > _Bleeding.BLEEDING_RATE_EPSILON
	var has_pressure: bool = _EntityAccess.entity_has_direct_pressure_on_part(manager, ally, part)
	return not actively_bleeding or has_pressure


static func get_ally_medical_actions(manager: Node, performer: Dictionary, ally: Dictionary, part: String) -> Array:
	var out: Array = []
	var has_pressure: bool = _EntityAccess.entity_has_direct_pressure_on_part(manager, ally, part)
	var bleed_rate: float = _EntityAccess.entity_bleeding_rate_for_part(manager, ally, part)
	var actively_bleeding: bool = bleed_rate > _Bleeding.BLEEDING_RATE_EPSILON
	var tq_indicated: bool = _EntityAccess.entity_is_tourniquet_indicated_for_part(manager, ally, part)
	var tq_can: bool = _EntityAccess.entity_can_apply_tourniquet(manager, ally, part)
	var junctional: bool = part in _Bleeding.PACKING_PARTS

	# Life-threatening limb: pressure (if needed) ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â€šÂ¬Ãƒâ€šÃ‚Â ' tourniquet before slow dressings.
	if tq_indicated and tq_can:
		_append_pressure_action_if_needed(
			manager, performer, ally, part, has_pressure, actively_bleeding, out
		)
		out.append({ "move_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET, "target_part": part })
		return _MedicalCoord.filter_ally_medical_actions(manager, performer, ally, out)

	# Junctional (head/chest): hold pressure before packing cavity.
	if (
		junctional
		and actively_bleeding
		and not has_pressure
		and _EntityAccess.entity_can_apply_packing(manager, ally, part)
	):
		_append_pressure_action_if_needed(
			manager, performer, ally, part, has_pressure, actively_bleeding, out
		)
		if not out.is_empty():
			return _MedicalCoord.filter_ally_medical_actions(manager, performer, ally, out)

	# Default menu: pressure before dressings while actively bleeding (TCCC); pack/bandage once compression is held.
	if not has_pressure:
		_append_pressure_action_if_needed(
			manager, performer, ally, part, has_pressure, actively_bleeding, out
		)
	var dressings_ok: bool = dressings_allowed_for_part(manager, ally, part)
	if (
		dressings_ok
		and has_pressure
		and actively_bleeding
		and _battle_med_supplies_available(manager)
		and _EntityAccess.entity_can_apply_stabilize(manager, ally, part)
	):
		out.append({ "move_id": CombatConstants.MOVE_ID_STABILIZE_WOUND, "target_part": part })
	if dressings_ok and _EntityAccess.entity_can_apply_bandage(manager, ally, part):
		out.append({ "move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_part": part })
	if dressings_ok and _EntityAccess.entity_can_apply_packing(manager, ally, part):
		out.append({ "move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_part": part })
	if tq_can and tq_indicated:
		out.append({ "move_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET, "target_part": part })
	return _MedicalCoord.filter_ally_medical_actions(manager, performer, ally, out)


static func _battle_med_supplies_available(manager: Node) -> bool:
	var world: Node2D = _get_company_state().resolve_world_from_battle(manager)
	return world != null and _get_company_state().get_medical_supplies(world) >= 1


## TCCC escalation ladder for a wound part. Returns the ordered list of valid medical actions
## (bandage ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â€šÂ¬Ãƒâ€šÃ‚Â ' pack ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ¢â€šÂ¬Ãƒâ€šÃ‚Â ' tourniquet), filtered to only actions that pass `medical_action_allowed()`.
## The bandage variant used depends on `performer_id == tgt_id` (self vs ally).
static func escalation_path_for_part(
	tgt_id: int, performer_id: int, part: String, manager: Node
) -> Array[String]:
	var path: Array[String] = []
	# Step 1: bandage (same move ID for self and ally; distinguished by target_id in listing).
	if _MedicalCoord.medical_action_allowed(manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_BANDAGE_SELF):
		path.append(CombatConstants.MOVE_ID_BANDAGE_SELF)
	# Step 2: pack (shared move ID for self and ally).
	if _MedicalCoord.medical_action_allowed(manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_PACK_WOUND):
		path.append(CombatConstants.MOVE_ID_PACK_WOUND)
	# Step 3: tourniquet (shared move ID for self and ally).
	if _MedicalCoord.medical_action_allowed(manager, performer_id, tgt_id, part, CombatConstants.MOVE_ID_APPLY_TOURNIQUET):
		path.append(CombatConstants.MOVE_ID_APPLY_TOURNIQUET)
	return path

                       
