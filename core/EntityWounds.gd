class_name EntityWounds
extends RefCounted

## Wound list, bleeding rates, clotting, and wound creation for entities with wounds dict and game time.
## Entity must have: wounds, body_max, bone_max, _game_time_seconds, endurance, tourniquet_applied,
## direct_pressure_part, self_direct_pressure_part, direct_pressure_held_by, name.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _Healing := preload("res://core/HealingConstants.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")

# Impact KE coupling for wounds (tune with weapon KE bands in WeaponDamageHelper / ImpactVelocityModel).
# ~55 J aligns with typical one-handed cut/thrust order of magnitude used in WeaponConstants / armor docs.
const _IMPACT_KE_REF_J := 55.0
const _SEVERITY_KE_BLEND := 0.28
const _BLEED_KE_BLEND := 0.32

# --- Wound healing progress (used by pain and process_healing) ---

static func get_wound_healing_progress(entity: Node, injury: Dictionary) -> float:
	var created: float = injury.get("created_at_game_time", -1.0)
	var duration: float = injury.get("healing_duration_seconds", 0.0)
	if created < 0.0 or duration <= 0.0:
		return 0.0
	var age: float = entity._game_time_seconds - created
	if age <= 0.0:
		return 0.0
	var tau: float = duration / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
	return 1.0 - exp(-age / tau)

# --- Severity (used when adding wounds from damage) ---

static func _severity_from_pct(pct: float) -> String:
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_CRITICAL:
		return _Bleeding.SEVERITY_CRITICAL
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_SEVERE:
		return _Bleeding.SEVERITY_SEVERE
	if pct >= _Bleeding.SEVERITY_PERCENTAGE_MODERATE:
		return _Bleeding.SEVERITY_MODERATE
	return _Bleeding.SEVERITY_MINOR

static func _severity_from_abs(effective_damage: float) -> String:
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_CRITICAL:
		return _Bleeding.SEVERITY_CRITICAL
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_SEVERE:
		return _Bleeding.SEVERITY_SEVERE
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_MINOR:
		return _Bleeding.SEVERITY_MODERATE
	return _Bleeding.SEVERITY_MINOR

static func severity_from_damage(entity: Node, part: String, damage: float, sub_region: String = "", impact_ke_j: float = -1.0) -> String:
	var max_hp: float = float(entity.body_max.get(part, 10))
	if max_hp <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	var ke_mult: float = 1.0
	if impact_ke_j >= 0.0:
		ke_mult = 1.0 + _SEVERITY_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
	var effective_damage: float = damage * ke_mult * _Bleeding.get_severity_modifier(part, sub_region)
	var pct: float = effective_damage / max_hp
	var sev_pct: String = _severity_from_pct(pct)
	var sev_abs: String = _severity_from_abs(effective_damage)
	var order: Array = [_Bleeding.SEVERITY_MINOR, _Bleeding.SEVERITY_MODERATE, _Bleeding.SEVERITY_SEVERE, _Bleeding.SEVERITY_CRITICAL]
	return order[maxi(order.find(sev_pct), order.find(sev_abs))]

static func severity_from_bone_damage(entity: Node, part: String, bone_damage: float) -> String:
	var max_bone: float = float(entity.bone_max.get(part, 1))
	if max_bone <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	var pct: float = bone_damage / max_bone
	return _severity_from_pct(pct)

# --- Add wound / stump wound ---

static func add_wound(entity: Node, part: String, injury_type: String, damage: float, sub_region: String = "", severity_override: String = "", impact_ke_j: float = -1.0) -> void:
	if part.is_empty() or damage <= 0.0:
		return
	var severity: String = severity_override if not severity_override.is_empty() else severity_from_damage(entity, part, damage, sub_region, impact_ke_j)
	if injury_type == _Bleeding.INJURY_TYPE_CRUSH and severity == _Bleeding.SEVERITY_MINOR:
		injury_type = _Bleeding.INJURY_TYPE_BRUISE
	var base_rate: float = _Bleeding.get_bleeding_rate(injury_type, severity, part, sub_region)
	if base_rate < 0.0:
		base_rate = 0.0
	if base_rate > 0.0 and injury_type == _Bleeding.INJURY_TYPE_CUT and impact_ke_j >= 0.0:
		base_rate *= 1.0 + _BLEED_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
	if base_rate > 0.0:
		base_rate *= randf_range(_Bleeding.BLEEDING_RATE_VARIANCE_MIN, _Bleeding.BLEEDING_RATE_VARIANCE_MAX)
	var is_arterial: bool = randf() < _Bleeding.get_arterial_chance(severity, injury_type, part, sub_region) if base_rate > 0.0 else false
	if base_rate > 0.0 and is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	if entity.wounds.get(part) == null:
		entity.wounds[part] = []
	var healing_duration: float = _Healing.get_wound_healing_duration_seconds(part, severity, injury_type)
	var injury: Dictionary = {
		"injury_type": injury_type,
		"severity": severity,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": entity._game_time_seconds,
		"healing_duration_seconds": healing_duration
	}
	entity.wounds[part].append(injury)

static func create_stump_wound(entity: Node, part: String, sub_region: String) -> Array:
	if sub_region.is_empty():
		sub_region = _Bleeding.get_random_sub_region(part)
	var base_rate: float = _Bleeding.get_stump_bleeding_rate(part, sub_region)
	var variation: float = 0.92 + randf() * 0.16
	base_rate *= variation
	var arterial_chance: float = _Bleeding.get_arterial_chance(_Bleeding.SEVERITY_CRITICAL, _Bleeding.INJURY_TYPE_CUT, part, sub_region) * _Bleeding.STUMP_ARTERIAL_CHANCE_MULTIPLIER
	arterial_chance = clampf(arterial_chance, 0.0, 1.0)
	var is_arterial: bool = randf() < arterial_chance
	if is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	var damage: float = float(entity.body_max.get(part, 10))
	var healing_duration: float = _Healing.get_wound_healing_duration_seconds(part, _Bleeding.SEVERITY_CRITICAL, _Bleeding.INJURY_TYPE_CUT)
	var injury: Dictionary = {
		"injury_type": _Bleeding.INJURY_TYPE_CUT,
		"severity": _Bleeding.SEVERITY_CRITICAL,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": entity._game_time_seconds,
		"healing_duration_seconds": healing_duration,
		"is_stump": true
	}
	return [injury]


static func has_stump_wound(entity: Node, part: String) -> bool:
	if part.is_empty() or not entity.wounds.has(part):
		return false
	for injury in entity.wounds[part]:
		if bool(injury.get("is_stump", false)):
			return true
	return false


## Replace existing wounds with a single severance stump wound once.
## If a stump wound already exists, keep current wound state (do not reset bleed timers/chances).
static func ensure_stump_wound(entity: Node, part: String, sub_region: String = "") -> void:
	if part.is_empty():
		return
	if has_stump_wound(entity, part):
		return
	entity.wounds[part] = create_stump_wound(entity, part, sub_region)

# --- Bleeding rate getters ---

static func get_bleeding_rate_for_part(entity: Node, part: String) -> float:
	if not entity.wounds.has(part):
		return 0.0
	var raw: float = 0.0
	for injury in entity.wounds[part]:
		raw += injury.get("current_bleeding_rate", 0.0)
	if not entity.tourniquet_applied.has(part):
		return raw
	_EntityMedical.ensure_tourniquet_dict_entry(entity, part)
	var data: Dictionary = entity.tourniquet_applied[part]
	var eff: float = float(data.get("effectiveness", 1.0))
	var reduction: float = eff * _Bleeding.TOURNIQUET_REDUCTION_AT_FULL
	return raw * (1.0 - reduction)

static func get_total_bleeding_rate(entity: Node) -> float:
	var total: float = 0.0
	for part in entity.wounds:
		total += get_bleeding_rate_for_part(entity, part)
	return total

static func get_permanent_bleeding_rate(entity: Node) -> float:
	var total: float = 0.0
	for part in entity.wounds:
		var rate: float = get_bleeding_rate_for_part(entity, part)
		if part == entity.self_direct_pressure_part or part == entity.direct_pressure_part:
			if rate > 0.0:
				rate /= (1.0 - _Bleeding.DIRECT_PRESSURE_IMMEDIATE_REDUCTION)
		total += rate
	return total

# --- Wound queries ---

static func get_wounded_parts(entity: Node) -> Array:
	var out: Array = []
	for part in entity.wounds.keys():
		out.append(part)
	return out

static func get_wounds(entity: Node) -> Dictionary:
	return entity.wounds.duplicate(true)

# --- Process bleeding (clotting, direct-pressure auto-clear) ---

static func process_bleeding(entity: Node, delta: float) -> void:
	for part in entity.wounds.keys():
		var list: Array = entity.wounds[part]
		var i: int = list.size() - 1
		while i >= 0:
			var injury: Dictionary = list[i]
			var rate: float = injury.get("current_bleeding_rate", 0.0)
			var clotting: float
			if injury.get("is_stabilized", false):
				clotting = _Bleeding.CLOTTING_RATE_STABILIZED
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
			else:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
				clotting = _Bleeding.get_clotting_rate(sev) * _Bleeding.get_clotting_multiplier(sev)
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
				var end_factor: float = clampf(0.9 + float(entity.endurance) / 1000.0, 0.9, 1.1)
				clotting *= end_factor
			rate = rate * exp(-clotting * delta)
			rate = maxf(0.0, rate)
			if rate <= _Bleeding.BLEEDING_RATE_EPSILON:
				rate = 0.0
			injury["current_bleeding_rate"] = rate
			i -= 1
		if list.is_empty():
			entity.wounds.erase(part)
	if not entity.direct_pressure_part.is_empty() and get_bleeding_rate_for_part(entity, entity.direct_pressure_part) <= _Bleeding.BLEEDING_RATE_EPSILON:
		print("[Medical] %s direct_pressure auto-cleared: bleeding on %s stopped (ally-held, rate <= epsilon)" % [entity.name, entity.direct_pressure_part])
		if entity.direct_pressure_held_by != null and "direct_pressure_on_ally" in entity.direct_pressure_held_by:
			entity.direct_pressure_held_by.direct_pressure_on_ally = {}
		entity.direct_pressure_held_by = null
		if entity.get("direct_pressure_assist_held_by") != null and entity.direct_pressure_assist_held_by != null:
			var asst_auto: Variant = entity.direct_pressure_assist_held_by
			if asst_auto != null and "direct_pressure_on_ally" in asst_auto:
				asst_auto.direct_pressure_on_ally = {}
			entity.direct_pressure_assist_held_by = null
		entity.direct_pressure_part = ""
	if not entity.self_direct_pressure_part.is_empty() and get_bleeding_rate_for_part(entity, entity.self_direct_pressure_part) <= _Bleeding.BLEEDING_RATE_EPSILON:
		print("[Medical] %s direct_pressure auto-cleared: bleeding on %s stopped (self-held, rate <= epsilon)" % [entity.name, entity.self_direct_pressure_part])
		entity.self_direct_pressure_part = ""

# --- Process blood loss (drain from bleeding rate; death at threshold) ---
## Entity must have: blood_volume, _update_consciousness (optional), emit_signal("died"), _get_blood_loss_death_threshold (optional).
static func process_blood_loss(entity: Node, delta: float) -> void:
	var total: float = get_total_bleeding_rate(entity)
	if total <= 0.0:
		return
	var loss: float = total * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER * delta
	entity.blood_volume = maxf(0.0, entity.blood_volume - loss)
	if entity.has_method("_update_consciousness"):
		entity._update_consciousness()
	var threshold: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		threshold = entity._get_blood_loss_death_threshold()
	if entity.blood_volume <= threshold:
		if entity.has_method("notify_died"):
			entity.notify_died()
		else:
			entity.emit_signal("died")
