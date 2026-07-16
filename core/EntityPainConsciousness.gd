class_name EntityPainConsciousness
extends RefCounted

## Pain aggregation, consciousness, pain shock, and performance modifiers.
## Entity must have: wounds, body_max, species, consciousness, effective_consciousness,
## _consciousness_dirty, _pain_shock_until_time, _last_hit_impact, _ambient_pain_shock_accum, blood_volume,
## body_cutting,
## body_blunt, endurance, perception, agility; signals health_changed, creature_incapacitated.

const PASSIVE_PARRY_BASE_REACTION_S: float = 0.24
# HEMA: void is valid but timing-sensitive; research supports modest base (0.08 - 0.15)
const DODGE_CHANCE_AT_FULL_SPEED: float = 0.12

# --- Concussion constants (Issue 1: head trauma / concussion mechanics) ---
const CONCUSSION_BONE_THRESHOLD_MIN: float = 0.6    # bone damage fraction to trigger concussion check
const CONCUSSION_BONE_THRESHOLD_MAX: float = 1.0    # full fracture => guaranteed
const CONCUSSION_DURATION_MIN_S: float = 3.0         # minimum post-impact confusion duration (s)
const CONCUSSION_DURATION_MAX_S: float = 15.0        # max confusion for severe (bone=1.0) trauma
const CONCUSSION_PERCEPTION_PENALTY_MULT: float = 0.4  # perception reduced to 40% during concussion
const CONCUSSION_DAMAGE_RATIO_FACTOR: float = 0.2    # damage ratio contribution weight (0-1)

# --- Pain contribution (single wound; used for pain-shock from hit) ---


static func get_pain_contribution_for_wound(
	_entity: Node,
	part: String,
	damage: float,
	severity: String,
	injury_type: String,
	sub_region: String,
	is_stump: bool = false
) -> float:
	if damage <= 0.0:
		return 0.0
	var part_mult: float = PainConsciousnessConstants.get_body_part_pain_multiplier(part)
	var sev_mult: float = PainConsciousnessConstants.SEVERITY_PAIN_MULTIPLIERS.get(severity, 1.0)
	var itype_mult: float = PainConsciousnessConstants.get_injury_type_pain_multiplier(injury_type)
	var sub_mult: float = PainConsciousnessConstants.get_sub_region_pain_multiplier(part, sub_region)
	var stump_mult: float = PainConsciousnessConstants.get_stump_pain_multiplier(is_stump)
	return damage * sev_mult * part_mult * itype_mult * sub_mult * stump_mult


# --- Pain per part and total ---


static func get_pain_for_part(entity: Node, part: String) -> float:
	if not entity.wounds.has(part):
		return 0.0
	var total: float = 0.0
	var part_mult: float = PainConsciousnessConstants.get_body_part_pain_multiplier(part)
	for injury in entity.wounds[part]:
		var d: float = injury.get("damage", 0.0)
		var sev: String = injury.get(DataKeys.INJURY_SEVERITY, "moderate")
		var sev_mult: float = PainConsciousnessConstants.SEVERITY_PAIN_MULTIPLIERS.get(sev, 1.0)
		var itype: String = injury.get("injury_type", "crush")
		var itype_mult: float = PainConsciousnessConstants.get_injury_type_pain_multiplier(itype)
		var sub: String = injury.get("sub_region", "")
		var sub_mult: float = PainConsciousnessConstants.get_sub_region_pain_multiplier(part, sub)
		var stump_mult: float = PainConsciousnessConstants.get_stump_pain_multiplier(injury.get("is_stump", false))
		var progress: float = EntityWounds._get_wound_healing_progress(entity, injury)
		total += d * sev_mult * part_mult * itype_mult * sub_mult * stump_mult * (1.0 - progress)
	if entity.has_method("_get_campaign_pain_mult"):
		total *= float(entity._get_campaign_pain_mult())
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
	if not PainConsciousnessConstants.USE_NORMALIZED_PAIN:
		return raw
	var ref: float = 6.0
	if entity.species != null and entity.species.has_method("get_pain_reference"):
		ref = entity.species.get_pain_reference(entity.body_max)
	if ref <= 0.0:
		ref = 6.0
	return raw / ref


static func _get_effective_pain_for_region(entity: Node, region: String) -> float:
	var raw: float = 0.0
	match region:
		"arms":
			raw = (
				get_pain_for_part(entity, BodyPartConstants.PART_RIGHT_ARM)
				+ get_pain_for_part(entity, BodyPartConstants.PART_LEFT_ARM)
			)
		"legs":
			raw = (
				get_pain_for_part(entity, BodyPartConstants.PART_LEFT_LEG)
				+ get_pain_for_part(entity, BodyPartConstants.PART_RIGHT_LEG)
			)
		BodyPartConstants.PART_CHEST:
			raw = get_pain_for_part(entity, BodyPartConstants.PART_CHEST)
		BodyPartConstants.PART_HEAD:
			raw = get_pain_for_part(entity, BodyPartConstants.PART_HEAD)
		_:
			return 0.0
	if not PainConsciousnessConstants.USE_NORMALIZED_PAIN:
		return raw
	return raw / get_pain_reference(entity)


# --- Blood -> consciousness modifier ---


static func get_blood_consciousness_modifier(entity: Node) -> float:
	return BleedingConstants.blood_consciousness_modifier_from_remaining(
		float(entity.blood_volume),
		PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
		PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
		PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
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
	var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
	shock_thresh += (
		(_effective_endurance(entity) - 100.0) * PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
	)
	if pain_value <= shock_thresh:
		return
	var risk: float = minf(
		1.0, (pain_value - shock_thresh) * PainConsciousnessConstants.get_pain_shock_risk_per_point()
	)
	var suscept: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(
		get_effective_pain_for_thresholds(entity)
	)
	risk = minf(1.0, risk * suscept)
	if randf() >= risk:
		return
	var now: float = CombatTiming.now_seconds()
	var duration: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(
		pain_value, entity._last_hit_impact
	)
	entity._pain_shock_until_time = now + duration
	entity._last_hit_impact = 0.0


## Sustained high pain during combat (no new hit). Returns true when shock was entered this tick.
static func try_ambient_pain_shock_tick(entity: Node, delta: float) -> bool:
	if not CombatConstants.is_feature_ambient_pain_shock():
		return false
	if entity == null or delta <= 0.0:
		return false
	var now: float = CombatTiming.now_seconds()
	if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
		entity._ambient_pain_shock_accum = 0.0
		return false
	# Ambient cooldown: prevent repeated ambient shock re-entry within cooldown window.
	var last_ambient_shock: float = -1.0
	if entity.has_method("_get_last_ambient_pain_shock_time"):
		last_ambient_shock = float(entity.call("_get_last_ambient_pain_shock_time"))
	if (
		last_ambient_shock >= 0.0
		and (now - last_ambient_shock) < PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_COOLDOWN_S
	):
		entity._ambient_pain_shock_accum = 0.0
		return false
	var pain_value: float = get_effective_pain_for_thresholds(entity)
	var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
	shock_thresh += (
		(_effective_endurance(entity) - 100.0) * PainConsciousnessConstants.ENDURANCE_PAIN_SHOCK_SLOPE_PER_POINT
	)
	if pain_value <= shock_thresh:
		entity._ambient_pain_shock_accum = 0.0
		return false
	entity._ambient_pain_shock_accum += delta
	if entity._ambient_pain_shock_accum < PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S:
		return false
	entity._ambient_pain_shock_accum = 0.0
	var risk: float = minf(
		1.0,
		(
			(pain_value - shock_thresh)
			* PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_RISK_PER_POINT
			* PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_RISK_MULT
		)
	)
	risk = minf(1.0, risk * PainConsciousnessConstants.get_pain_shock_susceptibility_mult(pain_value))
	if randf() >= risk:
		return false
	var duration: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain_value, 0.0)
	entity._pain_shock_until_time = now + duration
	if entity.has_method("_set_last_ambient_pain_shock_time"):
		entity.call("_set_last_ambient_pain_shock_time", now)
	else:
		entity._last_ambient_pain_shock_time = now
	entity._consciousness_dirty = true
	var who: String = _session_entity_label(entity)
	if OperationalLog.play_session_is_editor_f5():
		CombatF5SoakTrace.note_ambient_pain_shock(who, pain_value, duration)
	else:
		CombatDebug.combat_session(
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
	var head_cut: float = entity.body_cutting.get(BodyPartConstants.PART_HEAD, 0.0)
	var head_blunt: float = entity.body_blunt.get(BodyPartConstants.PART_HEAD, 0.0)
	var head_max: int = entity.body_max.get(BodyPartConstants.PART_HEAD, 1)
	var head_total: float = float(head_cut + head_blunt)
	var head_max_total: float = float(head_max * 2)
	var base_consciousness: float = 100.0
	if head_max_total > 0.0:
		base_consciousness = 100.0 * (head_total / head_max_total)
	var true_consciousness: float = base_consciousness * get_blood_consciousness_modifier(entity)
	var old_consciousness: float = entity.consciousness
	var old_effective: float = entity.effective_consciousness
	entity.consciousness = true_consciousness
	var now: float = CombatTiming.now_seconds()
	if entity._pain_shock_until_time >= 0.0 and now < entity._pain_shock_until_time:
		entity.effective_consciousness = (
			true_consciousness * (1.0 - PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0)
		)
	else:
		entity._pain_shock_until_time = -1.0
		entity.effective_consciousness = true_consciousness
	entity._consciousness_dirty = false
	if old_consciousness != entity.consciousness or old_effective != entity.effective_consciousness:
		if entity.has_method("_notify_health_changed"):
			entity._notify_health_changed()
		elif entity.has_signal("health_changed"):
			entity.health_changed.emit()
	if true_consciousness < PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
		if entity.has_method("_notify_creature_incapacitated"):
			entity._notify_creature_incapacitated()
		elif entity.has_signal("creature_incapacitated"):
			entity.creature_incapacitated.emit()


# --- Performance modifiers ---


static func get_performance_modifier(entity: Node) -> float:
	var pain: float = get_effective_pain_for_thresholds(entity)
	var cons: float = get_effective_consciousness(entity)
	return PainConsciousnessConstants.get_combined_performance_modifier(pain, cons)


static func get_action_bar_performance_modifier(entity: Node) -> float:
	var base: float = get_performance_modifier(entity)
	var chest_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
		_get_effective_pain_for_region(entity, BodyPartConstants.PART_CHEST)
	)
	return maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, base * chest_pain_mod)


static func get_hit_chance_performance_modifier(entity: Node) -> float:
	var base: float = get_performance_modifier(entity)
	var head_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
		_get_effective_pain_for_region(entity, BodyPartConstants.PART_HEAD)
	)
	return maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, base * head_pain_mod)


# get_effective_consciousness: ensure current then return (used by get_performance_modifier and callers)
static func get_effective_consciousness(entity: Node) -> float:
	if entity._consciousness_dirty:
		update_consciousness(entity)
	return entity.effective_consciousness


# --- Parry and dodge (depend on consciousness and pain) ---


static func _effective_perception(entity: Node) -> float:
	return EntityStatsUtil.get_effective_stat(entity, "perception")


static func _effective_agility(entity: Node) -> float:
	return EntityStatsUtil.get_effective_stat(entity, "agility")


static func _effective_endurance(entity: Node) -> float:
	return EntityStatsUtil.get_effective_stat(entity, "endurance")


static func get_passive_parry_reaction_time(entity: Node) -> float:
	var perception_norm: float = clampf(_effective_perception(entity) / 100.0, 0.2, 1.5)
	var consciousness_norm: float = clampf(get_effective_consciousness(entity) / 100.0, 0.1, 1.0)
	var head_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
		_get_effective_pain_for_region(entity, BodyPartConstants.PART_HEAD)
	)
	var perception_factor: float = clampf(perception_norm * consciousness_norm * head_pain_mod, 0.15, 1.0)
	return PASSIVE_PARRY_BASE_REACTION_S / perception_factor


static func get_dodge_chance(entity: Node) -> float:
	var leg: float = entity._get_leg_functionality() if entity.has_method("_get_leg_functionality") else 1.0
	var perf: float = get_performance_modifier(entity)
	var leg_pain_mod: float = PainConsciousnessConstants.get_pain_performance_modifier(
		_get_effective_pain_for_region(entity, "legs")
	)
	var dodge_stat_factor: float = clampf(
		(_effective_agility(entity) + _effective_perception(entity)) / 100.0 * 0.5,
		CombatConstants.STAT_EFFECT_MULT_MIN,
		CombatConstants.STAT_EFFECT_MULT_MAX
	)
	return clampf(dodge_stat_factor * DODGE_CHANCE_AT_FULL_SPEED * leg * perf * leg_pain_mod, 0.0, 1.0)


# --- Concussion methods (Issue 1) ---

static func try_enter_concussion_from_head_bone_damage(entity: Node, bone_damage_ratio: float) -> void:
	if not entity.has_method("_get_vital_parts"):
		return
	var vital_parts: Array = entity._get_vital_parts()
	if not "head" in vital_parts:
		return
	# Only check if head bone damage is significant.
	if bone_damage_ratio < CONCUSSION_BONE_THRESHOLD_MIN:
		return
	# Already concussed — extend duration proportionally.
	var current_until: float = 0.0
	if entity.has_method("get"):
		current_until = float(entity.get("_concussion_until_time"))
	var _now: float = 0.0
	if is_instance_valid(entity) and entity.is_inside_tree():
		_now = entity.get_tree().get_physics_process_delta_time()
	# Use time_step from physics process if available; approximate with scene timestamp.
	var current_time: float = _get_current_simulation_time(entity)
	if current_until > current_time and bone_damage_ratio <= CONCUSSION_BONE_THRESHOLD_MAX * 0.5:
		# Mild re-impact during existing concussion — small extension.
		var ext: float = lerp(CONCUSSION_DURATION_MIN_S, CONCUSSION_DURATION_MIN_S * 2.0, bone_damage_ratio / CONCUSSION_BONE_THRESHOLD_MAX)
		entity._concussion_until_time = current_time + ext
		return
	# Calculate concussion severity and duration.
	var severity: float = (bone_damage_ratio - CONCUSSION_BONE_THRESHOLD_MIN) / (CONCUSSION_BONE_THRESHOLD_MAX - CONCUSSION_BONE_THRESHOLD_MIN)
	severity = clampf(severity, 0.0, 1.0)
	# Also factor in damage ratio to body_max for this hit.
	var entity_damage_ratio: float = _get_entity_overall_damage_ratio(entity)
	var weighted_severity: float = severity * (1.0 - CONCUSSION_DAMAGE_RATIO_FACTOR) + entity_damage_ratio * CONCUSSION_DAMAGE_RATIO_FACTOR
	# Duration scales with severity.
	var duration_s: float = lerp(CONCUSSION_DURATION_MIN_S, CONCUSSION_DURATION_MAX_S, weighted_severity)
	entity._concussion_until_time = current_time + duration_s


static func is_concussed(entity: Node) -> bool:
	if not is_instance_valid(entity) or not entity.is_inside_tree():
		return false
	var curr: float = _get_current_simulation_time(entity)
	var until: float = 0.0
	if entity.has_method("get"):
		until = float(entity.get("_concussion_until_time"))
	return until > curr


static func get_concussed_perception_modifier(entity: Node) -> float:
	if is_concussed(entity):
		return CONCUSSION_PERCEPTION_PENALTY_MULT
	return 1.0


static func _get_current_simulation_time(entity: Node) -> float:
	# Try to get scene time; fallback to a simple approach.
	if is_instance_valid(entity) and entity.is_inside_tree():
		var tree = entity.get_tree()
		if tree != null:
			var root = tree.root
			if root and root.has_method("get_age"):
				return root.get_age()
	return 0.0


static func _get_entity_overall_damage_ratio(entity: Node) -> float:
	if not entity.has_method("body_max") or not entity.has_method("body_cutting") or not entity.has_method("bone_health"):
		return 0.0
	var body_max: Dictionary = entity.body_max
	var body_cutting: Dictionary = entity.body_cutting
	var bone_health: Dictionary = entity.bone_health
	var total_remaining: float = 0.0
	var total_max: float = 0.0
	for part in body_max:
		var mx: float = body_max[part]
		total_max += mx
		total_remaining += maxf(0.0, mx - body_cutting.get(part, 0.0) - bone_health.get(part, 0.0))
	if total_max > 0.0:
		return clampf(1.0 - (total_remaining / total_max), 0.0, 1.0)
	return 0.0
