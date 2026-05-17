class_name MedicalPhaseController
extends RefCounted

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, and ally medical actions.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node) -> Node (or use CombatantEntityAccess).

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")

## Queued events suppressed for the losing side once **`medical_phase`** is active.
const POST_VICTORY_BLOCKED_EVENT_TYPES: Array[String] = [
	CombatConstants.EVENT_MELEE_ATTACK,
	CombatConstants.EVENT_ACTION_READY,
	CombatConstants.EVENT_RECOVERY_END,
	CombatConstants.EVENT_SWAP_RANK_RESOLVE,
	CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
	CombatConstants.EVENT_ROTATE_FILE_RESOLVE,
]

# AI / phase gating: consider medical when blood or time-to-death in danger zone.
const MEDICAL_DANGER_BLOOD_THRESHOLD: float = 55.0
const MEDICAL_DANGER_SECONDS: float = 90.0
const IMMEDIATE_PERIL_BLOOD_THRESHOLD: float = 42.0
const IMMEDIATE_PERIL_SECONDS: float = 45.0
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

## True once player-side victory: no new combat resolutions (medical triage only).
static func combat_resolution_blocked(manager: Node) -> bool:
	return manager != null and bool(manager.medical_phase)


static func is_winner_side(manager: Node, c: Dictionary) -> bool:
	if manager == null or c == null or c.is_empty() or not manager.medical_phase:
		return false
	return _EntityAccess.side_str(c) == manager.medical_phase_winner


static func is_losing_side(manager: Node, c: Dictionary) -> bool:
	if manager == null or c == null or c.is_empty():
		return false
	if not manager.medical_phase:
		return false
	return not is_winner_side(manager, c)


static func is_losing_side_id(manager: Node, combatant_id: int) -> bool:
	if manager == null or combatant_id < 0 or not manager.has_method("_get_by_id"):
		return false
	var c: Dictionary = _EntityAccess.combatant_dict_or_empty(manager._get_by_id(combatant_id))
	return is_losing_side(manager, c)


## True when an event should not be queued for the losing side (or a pair touching them) during medical phase.
static func should_block_scheduled_event(manager: Node, ev: Dictionary) -> bool:
	if manager == null or not manager.medical_phase:
		return false
	var ev_type: String = str(ev.get("type", ""))
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
			var pid: int = int((dr as Dictionary).get("partner_id", -1))
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
		if typeof(ev) != TYPE_DICTIONARY:
			return false
		return not should_block_scheduled_event(manager, ev as Dictionary)
	)


## Player-win medical phase: cancel losing-side combat, abort wind-ups, idle combat states.
static func halt_losing_side_combat(manager: Node) -> void:
	if manager == null or not manager.medical_phase:
		return
	var winner: String = manager.medical_phase_winner
	for c in manager.combatants:
		if _EntityAccess.side_str(c) == winner:
			continue
		var cid: int = _EntityAccess.id_int(c)
		_EventScheduler.cancel_pending_combat_events_for_combatant(manager, cid)
		var st: String = _EntityAccess.state_str(c)
		if st == CombatConstants.STATE_WIND_UP:
			_CounterTempo.abort_attacker_wind_up(manager, cid)
			_EventScheduler.cancel_pending_recovery_end(manager, cid)
			c.state = CombatConstants.STATE_WAITING
			c.state_timer = 0.0
			c.state_duration = 0.0
			c.gauge = 0.0
			continue
		var pa: Dictionary = _EntityAccess.nested_dictionary_read(c, "pending_attack")
		if not pa.is_empty():
			_WindUpStarter.clear_incoming_attack_telegraph_from_pa(manager, pa)
			c.pending_attack = {}
		if st in [
			CombatConstants.STATE_RECOVERING,
			CombatConstants.STATE_SWAP_RANK,
			CombatConstants.STATE_FALLING_BACK,
			CombatConstants.STATE_MEDICAL_WIND_UP,
		]:
			c.state = CombatConstants.STATE_WAITING
			c.state_timer = 0.0
			c.state_duration = 0.0
			c.gauge = 0.0
		c["pending_medical"] = {}
		c.erase("formation_move_partner_id")
		c.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
		c.erase("parry_was_bind")
		c.erase("parry_against_id")
		c.erase("parry_bonus_until")
		_CounterTempo.clear_window(c)
		_CounterTempo.clear_riposte_chain(c)
	for c in manager.combatants:
		if _EntityAccess.side_str(c) != winner:
			continue
		_CounterTempo.clear_window(c)
		_CounterTempo.clear_riposte_chain(c)
	purge_blocked_events_from_queue(manager)


## Same threshold as bleed-out death (`CoreEntity._get_blood_loss_death_threshold` / `EntityWounds`).
static func _blood_loss_death_threshold_for_entity(entity: Node) -> float:
	return _EntityAccess.entity_blood_loss_death_threshold(entity)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated.
static func can_end_medical_phase(manager: Node) -> bool:
	if not manager.medical_phase:
		return false
	for c in manager.combatants:
		if (
			not _EntityAccess.alive_bool(c)
			or _EntityAccess.side_str(c) != manager.medical_phase_winner
			or _EntityAccess.scene_node(c) == null
		):
			continue
		if is_in_medical_danger(manager, c):
			return false
		if has_untreated_wounds(manager, c):
			return false
	return true

## True if combatant has any wounded part not comprehensively treated (bandaged, packed, or tourniqueted).
static func has_untreated_wounds(manager: Node, c: Dictionary) -> bool:
	var wounded: Array = _EntityAccess.entity_get_wounded_parts(manager, c)
	if wounded.is_empty():
		return false
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
	var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
	var tourniqueted: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
	for part in wounded:
		if bandaged.get(part, false) or packed.get(part, false) or tourniqueted.has(part):
			continue
		return true
	return false

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
	if buffer > 0.0 and perm_rate > 0.0:
		var safe_rate: float = buffer * _Bleeding.CLOTTING_SAFE_EFFECTIVE_RATE / _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if perm_rate <= safe_rate:
			return false
	var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return false
	var time_to_death: float = (bv - death_thresh) / loss_per_sec
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
	var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return false
	var death_thresh_im: float = _blood_loss_death_threshold_for_entity(entity)
	var time_to_death: float = (bv - death_thresh_im) / loss_per_sec
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
	if buffer > 0.0:
		var safe_rate: float = buffer * _Bleeding.CLOTTING_SAFE_EFFECTIVE_RATE / _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if perm_rate <= safe_rate:
			return true
	var loss_per_sec: float = perm_rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return true
	var time_to_death: float = (bv - death_thresh_pp) / loss_per_sec
	return time_to_death > IMMEDIATE_PERIL_SECONDS * 2.0

## 0..1: higher when more hurt (lower blood, shorter time to death). Includes randomness.
static func get_medical_urgency(manager: Node, c: Dictionary) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	var death_thresh_u: float = _blood_loss_death_threshold_for_entity(entity)
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_thresh_u
	var urgency_blood: float = 1.0 if bv <= death_thresh_u else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - bv) / maxf(0.01, range_bv), 0.0, 1.0)
	var urgency_time: float = 0.0
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate > 0.0:
		var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if loss_per_sec > 0.0:
			var time_to_death: float = (bv - death_thresh_u) / loss_per_sec
			urgency_time = 1.0 if time_to_death <= 0.0 else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
	var raw: float = maxf(urgency_blood, urgency_time)
	raw *= randf_range(MEDICAL_URGENCY_RANDOM_MIN, MEDICAL_URGENCY_RANDOM_MAX)
	return clampf(raw, 0.0, 1.0)

## Same blood/time urgency as `get_medical_urgency` but **no randomness** — used for medical action weights so triage is stable.
static func get_medical_urgency_deterministic(manager: Node, c: Dictionary) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	var death_thresh_ud: float = _blood_loss_death_threshold_for_entity(entity)
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_thresh_ud
	var urgency_blood: float = 1.0 if bv <= death_thresh_ud else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - bv) / maxf(0.01, range_bv), 0.0, 1.0)
	var urgency_time: float = 0.0
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate > 0.0:
		var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if loss_per_sec > 0.0:
			var time_to_death: float = (bv - death_thresh_ud) / loss_per_sec
			urgency_time = 1.0 if time_to_death <= 0.0 else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
	return clampf(maxf(urgency_blood, urgency_time), 0.0, 1.0)

## Higher = intervene on this part before milder wounds (bleed rate + severity + arterial/stump + tourniquet indication).
static func get_part_intervention_threat(manager: Node, c: Dictionary, part: String) -> float:
	if part.is_empty():
		return 0.0
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var rate: float = _EntityAccess.entity_bleeding_rate_for_part(manager, c, part)
	var bonus: float = 0.0
	if "wounds" in entity and entity.wounds is Dictionary and entity.wounds.has(part):
		for injury in entity.wounds[part]:
			if bool(injury.get("is_arterial", false)):
				bonus += 2.25
			if bool(injury.get("is_stump", false)):
				bonus += 4.5
			var sev: String = str(injury.get("severity", _Bleeding.SEVERITY_MODERATE))
			if sev == _Bleeding.SEVERITY_CRITICAL:
				bonus += 1.6
			elif sev == _Bleeding.SEVERITY_SEVERE:
				bonus += 0.85
	if _EntityAccess.entity_is_tourniquet_indicated_for_part(manager, c, part):
		bonus += 1.15
	return rate * 3.5 + bonus

## Returns list of { move_id, target_part } for medical actions the performer can apply to the ally's part.
static func get_ally_medical_actions(manager: Node, performer: Dictionary, ally: Dictionary, part: String) -> Array:
	var out: Array = []
	var fp_raw: Variant = ally.get("failed_medical_parts", null)
	var failed_parts: Array = (fp_raw as Array) if fp_raw is Array else []
	var skip_redress: bool = has_left_immediate_peril_permanently(manager, ally) and part in failed_parts
	# Bandage / pack / tourniquet stay available while someone holds direct pressure on this part (classic first aid).
	if not skip_redress and _EntityAccess.entity_can_apply_bandage(manager, ally, part):
		out.append({ "move_id": "bandage_self", "target_part": part })
	if not skip_redress and _EntityAccess.entity_can_apply_packing(manager, ally, part):
		out.append({ "move_id": "pack_wound", "target_part": part })
	if _EntityAccess.entity_has_direct_pressure_on_part(manager, ally, part):
		pass
	elif (
		_EntityAccess.scene_can_apply_direct_pressure(performer, "")
		and not _EntityAccess.is_applying_direct_pressure_scene(performer)
	):
		if (
			_EntityAccess.id_int(performer) == _EntityAccess.id_int(ally)
			and not _EntityAccess.entity_can_apply_direct_pressure(manager, ally, part)
		):
			pass
		else:
			out.append({ "move_id": "apply_direct_pressure", "target_part": part })
	if (
		not skip_redress
		and _EntityAccess.entity_can_apply_tourniquet(manager, ally, part)
		and _EntityAccess.entity_is_tourniquet_indicated_for_part(manager, ally, part)
	):
		out.append({ "move_id": "apply_tourniquet", "target_part": part })
	return out

