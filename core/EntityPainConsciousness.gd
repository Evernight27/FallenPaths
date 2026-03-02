class_name EntityPainConsciousness
extends RefCounted

## Pain aggregation, consciousness, pain shock, and performance modifiers.
## Entity must have: wounds, body_max, species, consciousness, effective_consciousness,
## _consciousness_dirty, _pain_shock_until_time, _last_hit_impact, blood_volume, body_cutting,
## body_blunt, endurance, perception, agility; signals health_changed, creature_incapacitated.

const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")

# --- Pain contribution (single wound; used for pain-shock from hit) ---

static func get_pain_contribution_for_wound(_entity: Node, part: String, damage: float, severity: String, injury_type: String, sub_region: String, is_stump: bool = false) -> float:
	if damage <= 0.0:
		return 0.0
	var part_mult: float = _PainConscious.get_body_part_pain_multiplier(part)
	var sev_mult: float = _PainConscious.SEVERITY_PAIN_MULTIPLIERS.get(severity, 1.0)
	var itype_mult: float = _PainConscious.get_injury_type_pain_multiplier(injury_type)
	var sub_mult: float = _PainConscious.get_sub_region_pain_multiplier(part, sub_region)
	var stump_mult: float = _PainConscious.get_stump_pain_multiplier(is_stump)
	return damage * sev_mult * part_mult * itype_mult * sub_mult * stump_mult

# --- Pain per part and total ---

static func get_pain_for_part(entity: Node, part: String) -> float:
	if not entity.wounds.has(part):
		return 0.0
	var total: float = 0.0
	var part_mult: float = _PainConscious.get_body_part_pain_multiplier(part)
	for injury in entity.wounds[part]:
		var d: float = injury.get("damage", 0.0)
		var sev: String = injury.get("severity", "moderate")
		var sev_mult: float = _PainConscious.SEVERITY_PAIN_MULTIPLIERS.get(sev, 1.0)
		var itype: String = injury.get("injury_type", "crush")
		var itype_mult: float = _PainConscious.get_injury_type_pain_multiplier(itype)
		var sub: String = injury.get("sub_region", "")
		var sub_mult: float = _PainConscious.get_sub_region_pain_multiplier(part, sub)
		var stump_mult: float = _PainConscious.get_stump_pain_multiplier(injury.get("is_stump", false))
		var progress: float = _EntityWounds.get_wound_healing_progress(entity, injury)
		total += d * sev_mult * part_mult * itype_mult * sub_mult * stump_mult * (1.0 - progress)
	return total

static func get_total_pain(entity: Node) -> float:
	var total: float = 0.0
	for part in entity.wounds:
		total += get_pain_for_part(entity, part)
	return total

static func get_pain_reference(entity: Node) -> float:
	if entity.species != null and entity.species.has_method("get_pain_reference"):
		var r: float = entity.species.get_pain_reference(entity.body_max)
		if r > 0.0:
			return r
	return 6.0

static func get_effective_pain_for_thresholds(entity: Node) -> float:
	var raw: float = get_total_pain(entity)
	if not _PainConscious.USE_NORMALIZED_PAIN:
		return raw
	var ref: float = 6.0
	if entity.species != null and entity.species.has_method("get_pain_reference"):
		ref = entity.species.get_pain_reference(entity.body_max)
	if ref <= 0.0:
		ref = 6.0
	return raw / ref

static func get_effective_pain_for_region(entity: Node, region: String) -> float:
	var raw: float = 0.0
	match region:
		"arms":
			raw = get_pain_for_part(entity, "right_arm") + get_pain_for_part(entity, "left_arm")
		"legs":
			raw = get_pain_for_part(entity, "left_leg") + get_pain_for_part(entity, "right_leg")
		"chest":
			raw = get_pain_for_part(entity, "chest")
		"head":
			raw = get_pain_for_part(entity, "head")
		_:
			return 0.0
	if not _PainConscious.USE_NORMALIZED_PAIN:
		return raw
	return raw / get_pain_reference(entity)

# --- Blood → consciousness modifier ---

static func get_blood_consciousness_modifier(entity: Node) -> float:
	if entity.blood_volume >= _PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD:
		return 1.0
	if entity.blood_volume <= _PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD:
		return maxf(0.0, 1.0 - _PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX)
	var start: float = _PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD
	var floor_t: float = _PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD
	var reduction: float = (start - entity.blood_volume) / (start - floor_t) * _PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
	return maxf(0.0, 1.0 - reduction)

# --- Consciousness update and pain shock ---

static func mark_consciousness_dirty(entity: Node) -> void:
	entity._consciousness_dirty = true

static func try_enter_pain_shock_from_hit(entity: Node, pain_from_this_hit_raw: float) -> void:
	if entity._last_hit_impact <= 0.0 or pain_from_this_hit_raw <= 0.0:
		return
	var ref: float = get_pain_reference(entity)
	if ref <= 0.0:
		ref = 6.0
	var pain_value: float = pain_from_this_hit_raw / ref
	var shock_thresh: float = _PainConscious.get_pain_shock_threshold()
	shock_thresh += (float(entity.endurance) - 100.0) * 0.02
	if pain_value <= shock_thresh:
		return
	var risk: float = minf(1.0, (pain_value - shock_thresh) * _PainConscious.get_pain_shock_risk_per_point())
	if randf() >= risk:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var duration: float = _PainConscious.get_pain_shock_duration_seconds(pain_value, entity._last_hit_impact)
	entity._pain_shock_until_time = now + duration
	entity._last_hit_impact = 0.0

static func update_consciousness(entity: Node) -> void:
	var head_cut: float = entity.body_cutting.get("head", 0.0)
	var head_blunt: float = entity.body_blunt.get("head", 0.0)
	var head_max: int = entity.body_max.get("head", 1)
	var head_total: float = float(head_cut + head_blunt)
	var head_max_total: float = float(head_max * 2)
	var base_consciousness: float = 100.0
	if head_max_total > 0.0:
		base_consciousness = 100.0 * (head_total / head_max_total)
	var true_consciousness: float = base_consciousness * get_blood_consciousness_modifier(entity)
	var old_consciousness: float = entity.consciousness
	var old_effective: float = entity.effective_consciousness
	entity.consciousness = true_consciousness
	var now: float = Time.get_ticks_msec() / 1000.0
	if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
		entity.effective_consciousness = true_consciousness * (1.0 - _PainConscious.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0)
	else:
		entity._pain_shock_until_time = -1.0
		entity.effective_consciousness = true_consciousness
	entity._consciousness_dirty = false
	if old_consciousness != entity.consciousness or old_effective != entity.effective_consciousness:
		entity.health_changed.emit()
	if true_consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
		entity.creature_incapacitated.emit()

# --- Performance modifiers ---

static func get_performance_modifier(entity: Node) -> float:
	var pain: float = get_effective_pain_for_thresholds(entity)
	var cons: float = get_effective_consciousness(entity)
	return _PainConscious.get_combined_performance_modifier(pain, cons)

static func get_action_bar_performance_modifier(entity: Node) -> float:
	var base: float = get_performance_modifier(entity)
	var chest_pain_mod: float = _PainConscious.get_pain_performance_modifier(get_effective_pain_for_region(entity, "chest"))
	return maxf(_PainConscious.MIN_PERFORMANCE_MODIFIER, base * chest_pain_mod)

static func get_hit_chance_performance_modifier(entity: Node) -> float:
	var base: float = get_performance_modifier(entity)
	var head_pain_mod: float = _PainConscious.get_pain_performance_modifier(get_effective_pain_for_region(entity, "head"))
	return maxf(_PainConscious.MIN_PERFORMANCE_MODIFIER, base * head_pain_mod)

# get_effective_consciousness: ensure current then return (used by get_performance_modifier and callers)
static func get_effective_consciousness(entity: Node) -> float:
	if entity._consciousness_dirty:
		update_consciousness(entity)
	return entity.effective_consciousness

# --- Parry and dodge (depend on consciousness and pain) ---

const PASSIVE_PARRY_BASE_REACTION_S: float = 0.22
const DODGE_CHANCE_AT_FULL_SPEED: float = 0.08

static func get_passive_parry_reaction_time(entity: Node) -> float:
	var perception_norm: float = clampf(float(entity.perception) / 100.0, 0.2, 1.5)
	var consciousness_norm: float = clampf(get_effective_consciousness(entity) / 100.0, 0.1, 1.0)
	var head_pain_mod: float = _PainConscious.get_pain_performance_modifier(get_effective_pain_for_region(entity, "head"))
	var perception_factor: float = clampf(perception_norm * consciousness_norm * head_pain_mod, 0.15, 1.0)
	return PASSIVE_PARRY_BASE_REACTION_S / perception_factor

static func get_dodge_chance(entity: Node) -> float:
	var leg: float = entity.get_leg_functionality() if entity.has_method("get_leg_functionality") else 1.0
	var perf: float = get_performance_modifier(entity)
	var leg_pain_mod: float = _PainConscious.get_pain_performance_modifier(get_effective_pain_for_region(entity, "legs"))
	var dodge_stat_factor: float = clampf((float(entity.agility) + float(entity.perception)) / 200.0, 0.5, 1.5)
	return clampf(dodge_stat_factor * DODGE_CHANCE_AT_FULL_SPEED * leg * perf * leg_pain_mod, 0.0, 1.0)
