class_name EntityPainConsciousness
extends RefCounted

## Pain aggregation, consciousness, pain shock, and performance modifiers.
## Entity must have: wounds, body_max, species, consciousness, effective_consciousness,
## _consciousness_dirty, _pain_shock_until_time, _last_hit_impact, _ambient_pain_shock_accum, blood_volume, body_cutting,
## body_blunt, endurance, perception, agility; signals health_changed, creature_incapacitated.

const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")

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
	if entity.has_method("get_campaign_pain_mult"):
		total *= float(entity.get_campaign_pain_mult())
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
	return _Bleeding.blood_consciousness_modifier_from_remaining(
		float(entity.blood_volume),
		_PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
		_PainConscious.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
	)

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
	var suscept: float = _PainConscious.get_pain_shock_susceptibility_mult(
		get_effective_pain_for_thresholds(entity)
	)
	risk = minf(1.0, risk * suscept)
	if randf() >= risk:
		return
	var now: float = _CombatTiming.now_seconds()
	var duration: float = _PainConscious.get_pain_shock_duration_seconds(pain_value, entity._last_hit_impact)
	entity._pain_shock_until_time = now + duration
	entity._last_hit_impact = 0.0


## Sustained high pain during combat (no new hit). Returns true when shock was entered this tick.
static func try_ambient_pain_shock_tick(entity: Node, delta: float) -> bool:
	if not _CombatConstants.is_feature_ambient_pain_shock():
		return false
	if entity == null or delta <= 0.0:
		return false
	var now: float = _CombatTiming.now_seconds()
	if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
		entity._ambient_pain_shock_accum = 0.0
		return false
	var pain_value: float = get_effective_pain_for_thresholds(entity)
	var shock_thresh: float = _PainConscious.get_pain_shock_threshold()
	shock_thresh += (float(entity.endurance) - 100.0) * 0.02
	if pain_value <= shock_thresh:
		entity._ambient_pain_shock_accum = 0.0
		return false
	entity._ambient_pain_shock_accum += delta
	if entity._ambient_pain_shock_accum < _PainConscious.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S:
		return false
	entity._ambient_pain_shock_accum = 0.0
	var risk: float = minf(
		1.0,
		(pain_value - shock_thresh)
		* _PainConscious.PAIN_SHOCK_AMBIENT_RISK_PER_POINT
		* _PainConscious.PAIN_SHOCK_AMBIENT_RISK_MULT
	)
	risk = minf(1.0, risk * _PainConscious.get_pain_shock_susceptibility_mult(pain_value))
	if randf() >= risk:
		return false
	var duration: float = _PainConscious.get_pain_shock_duration_seconds(pain_value, 0.0)
	entity._pain_shock_until_time = now + duration
	entity._consciousness_dirty = true
	var who: String = _session_entity_label(entity)
	if _OperationalLog.play_session_is_editor_f5():
		_F5SoakTrace.note_ambient_pain_shock(who, pain_value, duration)
	else:
		_CombatDebug.combat_session(
			"ambient_pain_shock %s effective_pain=%.1f duration=%.1fs" % [who, pain_value, duration]
		)
	return true


## Character node name when **`CombatBody`** is nested (F5 **ii6** grep `Companion`).
static func _session_entity_label(entity: Node) -> String:
	if entity == null:
		return "?"
	var parent: Node = entity.get_parent()
	if parent != null:
		var pn: String = str(parent.name).strip_edges()
		if not pn.is_empty():
			return pn
	return str(entity.name)


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
	var now: float = _CombatTiming.now_seconds()
	if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
		entity.effective_consciousness = true_consciousness * (1.0 - _PainConscious.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0)
	else:
		entity._pain_shock_until_time = -1.0
		entity.effective_consciousness = true_consciousness
	entity._consciousness_dirty = false
	if old_consciousness != entity.consciousness or old_effective != entity.effective_consciousness:
		if entity.has_method("notify_health_changed"):
			entity.notify_health_changed()
		else:
			entity.health_changed.emit()
	if true_consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
		if entity.has_method("notify_creature_incapacitated"):
			entity.notify_creature_incapacitated()
		else:
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

const PASSIVE_PARRY_BASE_REACTION_S: float = 0.24
const DODGE_CHANCE_AT_FULL_SPEED: float = 0.10  # HEMA: void is valid but timing-sensitive; research supports modest base (0.08–0.15)

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
