class_name MapFieldCare
extends RefCounted

## Camp-2.1 map field care (D-bleed add-on): pressure / bandage in Party menu with time cost.

const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")

const FIELD_CARE_SECONDS := 120.0
const FIELD_CARE_HEAL_MULT := 1.25


static func can_offer_field_pressure(world: Node2D, member: Dictionary) -> bool:
	var entity: Node = _entity_for_member(member)
	if entity == null:
		return false
	var part: String = _first_field_care_part(entity)
	if part.is_empty():
		return false
	if entity.has_method("can_apply_direct_pressure") and entity.can_apply_direct_pressure(part):
		return true
	if entity.has_method("can_apply_direct_pressure_from_ally"):
		var performer: Node = _default_performer_entity(world)
		if performer != null and entity.can_apply_direct_pressure_from_ally(part, performer):
			return true
	return false


static func can_offer_field_stabilize(world: Node2D, member: Dictionary) -> bool:
	if _CompanyState.get_medical_supplies(world) < 1:
		return false
	var entity: Node = _entity_for_member(member)
	if entity == null:
		return false
	return not _first_stabilize_part(entity).is_empty()


static func can_offer_field_bandage(world: Node2D, member: Dictionary) -> bool:
	if _CompanyState.get_medical_supplies(world) < 1:
		return false
	var entity: Node = _entity_for_member(member)
	if entity == null:
		return false
	var part: String = _first_field_care_part(entity)
	return not part.is_empty() and entity.has_method("can_apply_bandage") and entity.can_apply_bandage(part)


static func try_field_pressure(world: Node2D, member: Dictionary) -> bool:
	if not can_offer_field_pressure(world, member):
		return false
	var entity: Node = _entity_for_member(member)
	var part: String = _first_field_care_part(entity)
	if part.is_empty():
		return false
	_advance_field_care_time(entity)
	var ok: bool = false
	var performer: Node = _default_performer_entity(world)
	if (
		performer != null
		and entity.has_method("apply_direct_pressure_from_ally")
		and entity.can_apply_direct_pressure_from_ally(part, performer)
	):
		ok = entity.apply_direct_pressure_from_ally(part, performer)
	elif entity.has_method("apply_direct_pressure"):
		ok = entity.apply_direct_pressure(part)
	if ok:
		_CompanyState.refresh_hud(world)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"field_care pressure part=%s target=%s seconds=%.0f"
				% [part, str(member.get("name", "?")), FIELD_CARE_SECONDS]
			)
	return ok


static func try_field_stabilize(world: Node2D, member: Dictionary) -> bool:
	if not can_offer_field_stabilize(world, member):
		return false
	var entity: Node = _entity_for_member(member)
	var part: String = _first_stabilize_part(entity)
	if part.is_empty() or not entity.has_method("apply_stabilize"):
		return false
	if not _CompanyState.consume_medical(world, 1):
		return false
	_advance_field_care_time(entity)
	var eff: float = _CompanyState.compute_medical_supply_factor(world)
	if entity.has_method("get_medical_effectiveness"):
		eff = float(entity.get_medical_effectiveness()) * eff
	# Field stabilize: sustained pressure + camp training — slightly higher floor than battle RNG alone.
	eff = clampf(maxf(eff, 1.15), 0.25, 2.0)
	var ok: bool = entity.apply_stabilize(part, eff)
	if not ok:
		_CompanyState.set_medical_supplies(world, _CompanyState.get_medical_supplies(world) + 1)
		return false
	_CompanyState.refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"field_care stabilize part=%s target=%s seconds=%.0f med_left=%d"
			% [part, str(member.get("name", "?")), FIELD_CARE_SECONDS, _CompanyState.get_medical_supplies(world)]
		)
	return ok


static func try_field_bandage(world: Node2D, member: Dictionary) -> bool:
	if not can_offer_field_bandage(world, member):
		return false
	var entity: Node = _entity_for_member(member)
	var part: String = _first_field_care_part(entity)
	if part.is_empty() or not entity.has_method("apply_bandage"):
		return false
	if not _CompanyState.consume_medical(world, 1):
		return false
	_advance_field_care_time(entity)
	var eff: float = _CompanyState.compute_medical_supply_factor(world)
	if entity.has_method("get_medical_effectiveness"):
		eff = float(entity.get_medical_effectiveness()) * eff
		eff = clampf(eff, 0.25, 1.5)
	var ok: bool = entity.apply_bandage(part, eff)
	if not ok:
		_CompanyState.set_medical_supplies(world, _CompanyState.get_medical_supplies(world) + 1)
		return false
	_CompanyState.refresh_hud(world)
	if _OperationalLog.is_play_session_active():
		_OperationalLog.play_world(
			"field_care bandage part=%s target=%s seconds=%.0f med_left=%d"
			% [part, str(member.get("name", "?")), FIELD_CARE_SECONDS, _CompanyState.get_medical_supplies(world)]
		)
	return ok


static func _advance_field_care_time(entity: Node) -> void:
	_EntityTimeAdvance.advance(entity, FIELD_CARE_SECONDS * FIELD_CARE_HEAL_MULT, true)
	if entity.has_method("ensure_consciousness_current"):
		entity.ensure_consciousness_current()


static func _entity_for_member(member: Dictionary) -> Node:
	var node_ref: Variant = member.get("node_ref")
	if not is_instance_valid(node_ref) or not (node_ref is Node):
		return null
	return _CampaignBridge.health_entity_from_character(node_ref as Node)


static func _default_performer_entity(world: Node2D) -> Node:
	if world == null or not world.has_node("Character"):
		return null
	return _CampaignBridge.health_entity_from_character(world.get_node("Character"))


static func _first_stabilize_part(entity: Node) -> String:
	if entity == null:
		return ""
	var wounded: Array = []
	if entity.has_method("get_wounded_parts"):
		wounded = entity.get_wounded_parts()
	for part in wounded:
		var p: String = str(part)
		if entity.has_method("can_apply_stabilize") and entity.can_apply_stabilize(p):
			return p
	return ""


static func _first_field_care_part(entity: Node) -> String:
	if entity == null:
		return ""
	var wounded: Array = []
	if entity.has_method("get_wounded_parts"):
		wounded = entity.get_wounded_parts()
	for part in wounded:
		var p: String = str(part)
		if entity.has_method("can_apply_direct_pressure") and entity.can_apply_direct_pressure(p):
			return p
		if entity.has_method("can_apply_bandage") and entity.can_apply_bandage(p):
			return p
	return ""
