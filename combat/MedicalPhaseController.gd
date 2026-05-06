class_name MedicalPhaseController
extends RefCounted

## Medical phase queries: danger, urgency, untreated wounds, end-of-phase, and ally medical actions.
## Manager must have: combatants (Array), medical_phase (bool), medical_phase_winner (String), get_health_entity(node) -> Node (or use CombatantEntityAccess).

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

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

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated.
static func can_end_medical_phase(manager: Node) -> bool:
	if not manager.medical_phase:
		return false
	for c in manager.combatants:
		if not c.alive or c.side != manager.medical_phase_winner or c.node == null:
			continue
		if is_in_medical_danger(manager, c):
			return false
		if has_untreated_wounds(manager, c):
			return false
	return true

## True if combatant has any wounded part not comprehensively treated (bandaged, packed, or tourniqueted).
static func has_untreated_wounds(manager: Node, c: Dictionary) -> bool:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return false
	if not entity.has_method("get_wounded_parts"):
		return false
	var wounded: Array = entity.get_wounded_parts()
	if wounded.is_empty():
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
	var buffer: float = bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	if buffer > 0.0 and perm_rate > 0.0:
		var safe_rate: float = buffer * _Bleeding.CLOTTING_SAFE_EFFECTIVE_RATE / _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if perm_rate <= safe_rate:
			return false
	var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return false
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
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
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
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
	var buffer: float = bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	if buffer > 0.0:
		var safe_rate: float = buffer * _Bleeding.CLOTTING_SAFE_EFFECTIVE_RATE / _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if perm_rate <= safe_rate:
			return true
	var loss_per_sec: float = perm_rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return true
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
	return time_to_death > IMMEDIATE_PERIL_SECONDS * 2.0

## 0..1: higher when more hurt (lower blood, shorter time to death). Includes randomness.
static func get_medical_urgency(manager: Node, c: Dictionary) -> float:
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
	var death_thresh: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_thresh
	var urgency_blood: float = 1.0 if bv <= death_thresh else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - bv) / maxf(0.01, range_bv), 0.0, 1.0)
	var urgency_time: float = 0.0
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate > 0.0:
		var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if loss_per_sec > 0.0:
			var time_to_death: float = (bv - death_thresh) / loss_per_sec
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
	var death_thresh: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_thresh
	var urgency_blood: float = 1.0 if bv <= death_thresh else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - bv) / maxf(0.01, range_bv), 0.0, 1.0)
	var urgency_time: float = 0.0
	var rate: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
	if rate > 0.0:
		var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if loss_per_sec > 0.0:
			var time_to_death: float = (bv - death_thresh) / loss_per_sec
			urgency_time = 1.0 if time_to_death <= 0.0 else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
	return clampf(maxf(urgency_blood, urgency_time), 0.0, 1.0)

## Higher = intervene on this part before milder wounds (bleed rate + severity + arterial/stump + tourniquet indication).
static func get_part_intervention_threat(manager: Node, c: Dictionary, part: String) -> float:
	if part.is_empty():
		return 0.0
	var entity: Node = _EntityAccess.get_entity_from_manager(manager, c)
	if entity == null:
		return 0.0
	var rate: float = 0.0
	if entity.has_method("get_bleeding_rate_for_part"):
		rate = float(entity.get_bleeding_rate_for_part(part))
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
	if entity.has_method("is_tourniquet_indicated_for_part") and entity.is_tourniquet_indicated_for_part(part):
		bonus += 1.15
	return rate * 3.5 + bonus

## Returns list of { move_id, target_part } for medical actions the performer can apply to the ally's part.
static func get_ally_medical_actions(manager: Node, performer: Dictionary, ally: Dictionary, part: String) -> Array:
	var out: Array = []
	var target_entity: Node = _EntityAccess.get_entity_from_manager(manager, ally)
	var performer_has_arm: bool = performer.node.can_apply_direct_pressure("") if (performer.node != null and performer.node.has_method("can_apply_direct_pressure")) else false
	var failed_parts: Array = ally.get("failed_medical_parts", [])
	var skip_redress: bool = has_left_immediate_peril_permanently(manager, ally) and part in failed_parts
	# Bandage / pack / tourniquet stay available while someone holds direct pressure on this part (classic first aid).
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_bandage") and target_entity.can_apply_bandage(part):
		out.append({ "move_id": "bandage_self", "target_part": part })
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_packing") and target_entity.can_apply_packing(part):
		out.append({ "move_id": "pack_wound", "target_part": part })
	if target_entity != null and target_entity.has_method("has_direct_pressure_on_part") and target_entity.has_direct_pressure_on_part(part):
		pass
	elif performer_has_arm and performer.node.has_method("is_applying_direct_pressure") and not performer.node.is_applying_direct_pressure():
		if performer.id == ally.id and target_entity != null and not target_entity.can_apply_direct_pressure(part):
			pass
		else:
			out.append({ "move_id": "apply_direct_pressure", "target_part": part })
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_tourniquet") and target_entity.can_apply_tourniquet(part):
		if target_entity.has_method("is_tourniquet_indicated_for_part") and target_entity.is_tourniquet_indicated_for_part(part):
			out.append({ "move_id": "apply_tourniquet", "target_part": part })
	return out

