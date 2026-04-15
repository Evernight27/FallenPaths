class_name EntityMedical
extends RefCounted

## Medical actions (bandage, packing, direct pressure, tourniquet) for entities that have
## wounds, bandaged_parts, packed_parts, tourniquet_applied, and direct_pressure_* state.
## Entity must implement: get_attacking_arm(), get_bleeding_rate_for_part(part), get_medical_effectiveness(), get_game_time_seconds()

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

# --- Shared wound treatment (bandage, packing) ---

## Internal: shared roll-and-apply logic for stabilizing wound treatments (bandage, packing).
## Returns true on success. Mutates entity.wounds in place.
static func _apply_stabilizing_treatment(
	entity: Node, part: String, effectiveness: float,
	success_base: float, success_arterial_mult: float, arterial_eff_mult: float, immediate_reduction: float,
	mark_dict: Dictionary
) -> Dictionary:
	effectiveness = clampf(effectiveness, 0.0, 1.5)
	var has_arterial: bool = false
	for injury in entity.wounds[part]:
		if injury.get("is_arterial", false):
			has_arterial = true
			break
	var success_chance: float = success_base
	if has_arterial:
		success_chance *= success_arterial_mult
	success_chance *= effectiveness
	success_chance = clampf(success_chance, 0.0, 1.0)
	var roll: float = randf()
	var success: bool = roll < success_chance
	var wound_count: int = entity.wounds[part].size()
	var reduction: float = 0.0
	if success:
		for injury in entity.wounds[part]:
			var eff: float = effectiveness
			if injury.get("is_arterial", false):
				eff *= arterial_eff_mult
			var red: float = immediate_reduction * clampf(eff, 0.0, 1.0)
			var rate: float = injury.get("current_bleeding_rate", 0.0)
			injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - red))
			injury["is_stabilized"] = true
			if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
				injury["stabilized_remaining_seconds"] = _Bleeding.BANDAGE_STABILIZATION_DURATION
		mark_dict[part] = true
	else:
		var closeness: float = 1.0
		if success_chance < 1.0:
			closeness = 1.0 - (roll - success_chance) / (1.0 - success_chance)
			closeness = clampf(closeness, 0.0, 1.0)
		reduction = closeness * immediate_reduction
		for injury in entity.wounds[part]:
			var eff: float = effectiveness
			if injury.get("is_arterial", false):
				eff *= arterial_eff_mult
			var wound_reduction: float = reduction * clampf(eff, 0.0, 1.0)
			var rate: float = injury.get("current_bleeding_rate", 0.0)
			injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - wound_reduction))
	return { "success": success, "wound_count": wound_count, "reduction": reduction }

# --- Bandage ---

static func get_bandage_application_time_seconds() -> float:
	return _Bleeding.BANDAGE_APPLICATION_TIME_SECONDS

static func get_bandage_application_time_seconds_for_part(entity: Node, part: String) -> float:
	return _get_application_time_for_part(entity, part, _Bleeding.BANDAGE_APPLICATION_TIME_SECONDS, _Bleeding.BANDAGE_PER_WOUND_EXTRA_SECONDS)

## Internal: shared logic for bandage/packing per-part application time.
static func _get_application_time_for_part(entity: Node, part: String, base_seconds: float, per_wound_extra: float) -> float:
	if part.is_empty() or not entity.wounds.has(part):
		return base_seconds
	var n: int = entity.wounds[part].size()
	if n <= 0:
		return base_seconds
	return base_seconds + per_wound_extra * max(0, n - 1)

static func can_apply_bandage(entity: Node, part: String) -> bool:
	if part.is_empty() or not entity.wounds.has(part) or entity.wounds[part].is_empty():
		return false
	if entity.tourniquet_applied.has(part):
		return false
	if entity.bandaged_parts.has(part):
		return false
	if entity.packed_parts.has(part):
		return false
	return true

static func apply_bandage(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
	if part.is_empty() or not entity.wounds.has(part):
		return false
	if entity.tourniquet_applied.has(part) or entity.bandaged_parts.has(part) or entity.packed_parts.has(part):
		return false
	clear_direct_pressure(entity)
	var r = _apply_stabilizing_treatment(
		entity, part, effectiveness,
		_Bleeding.BANDAGE_SUCCESS_BASE_CHANCE, _Bleeding.BANDAGE_SUCCESS_ARTERIAL_MULT,
		_Bleeding.BANDAGE_ARTERIAL_EFFECTIVENESS_MULT, _Bleeding.BANDAGE_IMMEDIATE_REDUCTION,
		entity.bandaged_parts
	)
	if r.success:
		print("[Medical] %s apply_bandage(%s) => success, %d wound(s) stabilized" % [entity.name, part, r.wound_count])
	else:
		print("[Medical] %s apply_bandage(%s) => failed (%.0f%% reduction), %d wound(s); can retry" % [entity.name, part, r.reduction * 100, r.wound_count])
	return r.success

# --- Packing ---

static func can_apply_packing(entity: Node, part: String) -> bool:
	if part not in _Bleeding.PACKING_PARTS:
		return false
	if not entity.wounds.has(part) or entity.wounds[part].is_empty():
		return false
	if entity.tourniquet_applied.has(part) or entity.bandaged_parts.has(part) or entity.packed_parts.has(part):
		return false
	return true

static func apply_packing(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
	if not can_apply_packing(entity, part):
		return false
	clear_direct_pressure(entity)
	var r = _apply_stabilizing_treatment(
		entity, part, effectiveness,
		_Bleeding.PACKING_SUCCESS_BASE_CHANCE, _Bleeding.PACKING_SUCCESS_ARTERIAL_MULT,
		_Bleeding.PACKING_ARTERIAL_EFFECTIVENESS_MULT, _Bleeding.PACKING_IMMEDIATE_REDUCTION,
		entity.packed_parts
	)
	if r.success:
		print("[Medical] %s apply_packing(%s) => success, %d wound(s) packed with linen" % [entity.name, part, r.wound_count])
	else:
		print("[Medical] %s apply_packing(%s) => failed (%.0f%% reduction), %d wound(s); can retry" % [entity.name, part, r.reduction * 100, r.wound_count])
	return r.success

static func get_packing_application_time_seconds_for_part(entity: Node, part: String) -> float:
	return _get_application_time_for_part(entity, part, _Bleeding.PACKING_APPLICATION_TIME_SECONDS, _Bleeding.PACKING_PER_WOUND_EXTRA_SECONDS)

# --- Direct pressure ---

## Internal: applies direct pressure wound reduction to injuries. Mutates entity.wounds in place.
static func _apply_direct_pressure_to_wounds(entity: Node, part: String, effectiveness: float) -> void:
	effectiveness = clampf(effectiveness, 0.0, 1.5)
	for injury in entity.wounds[part]:
		var eff: float = effectiveness
		if injury.get("is_arterial", false):
			eff *= _Bleeding.DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT
		var reduction: float = _Bleeding.DIRECT_PRESSURE_IMMEDIATE_REDUCTION * clampf(eff, 0.0, 1.0)
		var rate: float = injury.get("current_bleeding_rate", 0.0)
		injury["current_bleeding_rate"] = maxf(0.0, rate * (1.0 - reduction))
		injury["is_stabilized"] = true
		if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
			injury["stabilized_remaining_seconds"] = _Bleeding.BANDAGE_STABILIZATION_DURATION

static func can_apply_direct_pressure(entity: Node, target_part: String) -> bool:
	if entity.bandaged_parts.has(target_part) or entity.packed_parts.has(target_part):
		return false
	if entity.tourniquet_applied.has(target_part):
		if entity.get_bleeding_rate_for_part(target_part) <= _Bleeding.BLEEDING_RATE_EPSILON:
			return false
	var arm: String = entity.get_attacking_arm()
	if arm.is_empty():
		return false
	if target_part == "right_arm" or target_part == "left_arm":
		if arm == target_part:
			return false
	return true

static func apply_direct_pressure_from_ally(entity: Node, part: String, performer_entity: Node = null) -> bool:
	if part.is_empty() or not entity.wounds.has(part):
		return false
	if entity.bandaged_parts.has(part) or entity.packed_parts.has(part):
		return false
	if entity.tourniquet_applied.has(part) and entity.get_bleeding_rate_for_part(part) <= _Bleeding.BLEEDING_RATE_EPSILON:
		return false
	var effectiveness: float = _EntityAccess.get_medical_effectiveness_from_node(performer_entity)
	_apply_direct_pressure_to_wounds(entity, part, effectiveness)
	entity.direct_pressure_part = part
	entity.direct_pressure_held_by = performer_entity
	print("[Medical] direct_pressure_from_ally on %s => holding until performer releases or bleeding stops" % [part])
	return true

static func apply_direct_pressure(entity: Node, part: String, effectiveness: float = -1.0) -> bool:
	if part.is_empty() or not entity.wounds.has(part):
		return false
	if not can_apply_direct_pressure(entity, part):
		return false
	if effectiveness < 0.0:
		effectiveness = _EntityAccess.get_medical_effectiveness_from_node(entity)
	_apply_direct_pressure_to_wounds(entity, part, effectiveness)
	entity.self_direct_pressure_part = part
	print("[Medical] %s applying direct_pressure on %s (self) => holding until next action or bleeding stops" % [entity.name, part])
	return true

static func is_applying_direct_pressure(entity: Node) -> bool:
	return not entity.direct_pressure_part.is_empty() or not entity.self_direct_pressure_part.is_empty() or not entity.direct_pressure_on_ally.is_empty()

static func has_direct_pressure_on_part(entity: Node, part: String) -> bool:
	return part == entity.self_direct_pressure_part or part == entity.direct_pressure_part

static func get_direct_pressure_part(entity: Node) -> String:
	if not entity.self_direct_pressure_part.is_empty():
		return entity.self_direct_pressure_part
	if entity.direct_pressure_on_ally.has("part"):
		return entity.direct_pressure_on_ally.get("part", "")
	return entity.direct_pressure_part

static func clear_direct_pressure(entity: Node) -> void:
	if entity.direct_pressure_held_by != null and "direct_pressure_on_ally" in entity.direct_pressure_held_by:
		entity.direct_pressure_held_by.direct_pressure_on_ally = {}
		entity.direct_pressure_held_by = null
	if not entity.direct_pressure_part.is_empty():
		print("[Medical] %s clear_direct_pressure (ally was holding %s)" % [entity.name, entity.direct_pressure_part])
	entity.direct_pressure_part = ""
	if not entity.self_direct_pressure_part.is_empty():
		print("[Medical] %s clear_direct_pressure (was self-holding %s)" % [entity.name, entity.self_direct_pressure_part])
	entity.self_direct_pressure_part = ""
	if entity.direct_pressure_on_ally.has("node") and entity.direct_pressure_on_ally.has("part"):
		var ally_entity = entity.direct_pressure_on_ally.get("node")
		var ally_part: String = entity.direct_pressure_on_ally.get("part", "")
		if ally_entity != null and "direct_pressure_part" in ally_entity:
			ally_entity.direct_pressure_part = ""
			if "direct_pressure_held_by" in ally_entity:
				ally_entity.direct_pressure_held_by = null
			print("[Medical] %s released direct_pressure on ally's %s" % [entity.name, ally_part])
	entity.direct_pressure_on_ally = {}

# --- Tourniquet ---

static func is_tourniquet_indicated_for_part(entity: Node, part: String) -> bool:
	if part not in _Bleeding.LIMB_PARTS or not entity.wounds.has(part) or entity.wounds[part].is_empty():
		return false
	for injury in entity.wounds[part]:
		if injury.get("is_stump", false):
			return true
	for injury in entity.wounds[part]:
		var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
		if sev == _Bleeding.SEVERITY_SEVERE or sev == _Bleeding.SEVERITY_CRITICAL:
			return true
	if entity.get_bleeding_rate_for_part(part) >= _Bleeding.TOURNIQUET_BLEEDING_RATE_THRESHOLD:
		return true
	return false

static func can_apply_tourniquet(entity: Node, part: String) -> bool:
	if part not in _Bleeding.LIMB_PARTS:
		return false
	if not entity.wounds.has(part) or entity.wounds[part].is_empty():
		return false
	if entity.tourniquet_applied.has(part) or entity.bandaged_parts.has(part) or entity.packed_parts.has(part):
		return false
	return true

## Migrates legacy float timestamp storage to { "applied_at", "effectiveness" } (e.g. old saves).
static func ensure_tourniquet_dict_entry(entity: Node, part: String) -> void:
	if not entity.tourniquet_applied.has(part):
		return
	var data = entity.tourniquet_applied[part]
	if typeof(data) == TYPE_FLOAT or typeof(data) == TYPE_INT:
		entity.tourniquet_applied[part] = { "applied_at": float(data), "effectiveness": 1.0 }


static func is_tourniquet_applied(entity: Node, part: String) -> bool:
	return entity.tourniquet_applied.has(part)

static func apply_tourniquet(entity: Node, part: String, effectiveness: float = 1.0) -> bool:
	if not can_apply_tourniquet(entity, part):
		return false
	effectiveness = clampf(effectiveness, 0.0, 1.5)
	var success_chance: float = _Bleeding.TOURNIQUET_SUCCESS_BASE_CHANCE * effectiveness
	success_chance = clampf(success_chance, 0.0, 1.0)
	var success: bool = randf() < success_chance
	if success:
		clear_direct_pressure(entity)
		var eff_clamped: float = clampf(effectiveness, 0.0, 1.0)
		entity.tourniquet_applied[part] = { "applied_at": entity.get_game_time_seconds(), "effectiveness": eff_clamped }
		var reduction_pct: float = eff_clamped * _Bleeding.TOURNIQUET_REDUCTION_AT_FULL * 100.0
		print("[Medical] %s apply_tourniquet(%s) => success, effectiveness=%.2f => %.0f%% bleeding reduction" % [entity.name, part, eff_clamped, reduction_pct])
	else:
		print("[Medical] %s apply_tourniquet(%s) => failed (not tight enough); can retry" % [entity.name, part])
	return success

static func remove_tourniquet(entity: Node, part: String) -> void:
	entity.tourniquet_applied.erase(part)

static func get_tourniquet_application_time_seconds() -> float:
	return _Bleeding.TOURNIQUET_APPLICATION_TIME_SECONDS
