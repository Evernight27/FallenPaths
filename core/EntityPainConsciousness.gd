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
## Phase-based model per RESEARCH_concussion_mTBI_combat.md §6b. Phases use proportional weights
## from PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_* of total capped duration.
## Modifiers interpolate continuously between phase boundaries (see get_concussion_phase_info).
const CONCUSSION_BONE_THRESHOLD_MIN: float = 0.6    # bone damage fraction to trigger concussion check
const CONCUSSION_BONE_THRESHOLD_MAX: float = 1.0    # full fracture => guaranteed
const CONCUSSION_DAMAGE_RATIO_FACTOR: float = 0.2    # damage ratio contribution weight (0-1)

# Clinical phase durations for SIS re-impact window check only (not used as game-time boundaries).
## Phase boundary weights are in PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_*.
const CONCUSSION_CRITICAL_DURATION_S: float = 90.0

## Max total concussion duration for gameplay pacing — caps the computed recovery time.
## Clinical data says most adults resolve within ~14 days, but that maps to unrealistic downtime in-game.
## Capped at ~3 minutes so the full phase progression (critical→acute→subacute→recovery) completes within a single combat encounter.
const CONCUSSION_MAX_TOTAL_DURATION_S: float = 180.0

## Severity-to-duration anchors: mild concussion gets shorter total recovery, severe gets up to MAX.
const CONCUSSION_MIN_TOTAL_DURATION_S: float = 60.0   # mild (low severity) — ~1 minute

# Phase-based perception/cognitive modifiers (fraction of baseline function). Gradual recovery curve:
## Values below are boundary points for interpolation in get_concussion_phase_info.
## Within each phase, values interpolate linearly between the onset and offset boundaries.
## Critical: 35-42% function (58-65% reduction) — matches clinical GCS 13-15 data at concussion onset.
## Acute: 42-60% function (40-58% reduction) — significant impairment gradually improving.
## Subacute: 60-85% function (15-40% reduction) — residual foggy thinking improving toward baseline.
## Recovery: 85-100% function — gradual return to full baseline.
const CONCUSSION_PERCEPTION_CRITICAL_MULT: float = 0.35 # onset value at concussion time
const CONCUSSION_PERCEPTION_ACUTE_END_MULT: float = 0.60 # end of acute phase
const CONCUSSION_PERCEPTION_RECOVERY_START_MULT: float = 0.85 # start of recovery (after subacute)

# New modifier categories beyond perception — concussion affects balance, reaction time, visual tracking.
## Reaction time delay added by concussion phase (ms over baseline). Combat impact: +100-500ms can be the difference between parrying and being hit.
## Values are boundary points; interpolation occurs within each phase in get_concussion_phase_info.
const REACTION_TIME_MS_ADD_CRITICAL_START: float = 500.0 # onset of concussion
const REACTION_TIME_MS_ADD_ACUTE_END: float = 300.0      # end of acute phase
const REACTION_TIME_MS_ADD_RECOVERY_END: float = 0.0     # full recovery

## Balance/movement control impairment by concussion phase (fraction of baseline). Vestibular disruption causes gait unsteadiness.
const BALANCE_MULT_CRITICAL_START: float = 0.50 # onset of concussion
const BALANCE_MULT_ACUTE_END: float = 0.70      # end of acute phase
const BALANCE_MULT_RECOVERY_END: float = 1.0     # full recovery

## Visual tracking impairment — ability to follow moving targets/weapons (smooth pursuit, saccadic dysfunction).
const VISUAL_TRACKING_MULT_CRITICAL_START: float = 0.30 # onset of concussion
const VISUAL_TRACKING_MULT_ACUTE_END: float = 0.55      # end of acute phase
const VISUAL_TRACKING_MULT_RECOVERY_END: float = 1.0    # full recovery

## Spatial judgment delay — inability to accurately judge distance, trajectory, timing. Combat impact:
## +200-480ms makes parrying/aiming nearly impossible at close range. Per research §6c.
const SPATIAL_JUDGMENT_MS_ADD_CRITICAL_START: float = 480.0 # onset of concussion
const SPATIAL_JUDGMENT_MS_ADD_ACUTE_END: float = 240.0      # end of acute phase
const SPATIAL_JUDGMENT_MS_ADD_RECOVERY_END: float = 0.0     # full recovery

# Second Impact Syndrome (SIS) — catastrophic brain swelling when hit during vulnerable window.
## Tier boundaries per research §6d: Critical (0-5min, ×3-5x), Early (5-15min, ×2-3x), Late (15min-2hr, ×1.5-2x).
## Vulnerable window extends up to 2hr for severe/prior cases; cumulative concussions extend further.
const SIS_CRITICAL_WINDOW_S: float = 300.0               # 5 minutes — research §6d critical tier boundary
const SIS_EARLY_WINDOW_S: float = 900.0                  # 15 minutes — research §6d early tier boundary
const SIS_LATE_WINDOW_S: float = 7200.0                  # 2 hours — research §6d late tier boundary
const SECOND_IMPACT_VULNERABLE_WINDOW_AFTER_MILD_S: float = 3600.0 # 1hr for mild concussion (no prior)
const SIS_SEVERITY_MULTIPLIER_CRITICAL: float = 4.5      # hit within first 5min — per research ×3-5x range
const SIS_SEVERITY_MULTIPLIER_EARLY: float = 2.5         # 5min - 15min — per research ×2-3x range
const SIS_SEVERITY_MULTIPLIER_LATE: float = 1.75         # 15min - 2hr — per research ×1.5-2x range

# Pain-concussion synergistic amplification (Gosselin et al., J Neurotrauma 2012).
## When both pain shock AND concussion are active, they amplify each other synergistically.
## Full formula: combined_reduction = concussive + pain_shock + (concussive * pain_shock * SYNERGY_FACTOR)
## E.g., 50% pain shock × 65% perception reduction → combined = 0.50 + 0.65 + (0.50*0.65*0.30) = 1.145 → capped at 1.0
## Result: only ~0-2% remaining function vs 15% without synergy — dramatic clinical effect.
const PAIN_CONCUSSION_SYNERGY_FACTOR: float = 0.30      # 30% additional impairment when both present (Gosselin et al.)

# Cumulative concussion tracking — each successive concussion in a session has increasing severity and longer recovery.
## Reflects cumulative brain injury from repeated head trauma (chronic traumatic encephalopathy precursor).
const CONCUSSION_CUMULATIVE_SEVERITY_BONUS: float = 0.15 # +15% severity per prior concussion in same session
const CONCUSSION_CUMULATIVE_DURATION_BONUS: float = 0.20 # +20% duration per prior concussion

# Persistent concussion fatigue — cumulative brain impairment from repeated sub-threshold concussions.
## Each concussion adds a small persistent penalty (based on severity) that lingers after the phase-based effects resolve.
## Cleared by rest/recuperation between sessions via clear_concussion_fatigue(). Cap at 0.45 to prevent total incapacitation.
const CONCUSSION_PERSISTENT_FATIGUE_PER_HIT: float = 0.12 # max fatigue contribution per concussion hit

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
	var risk: float = PainConsciousnessConstants.PAIN_SHOCK_RISK_PER_POINT_NORMALIZED * (pain_value - shock_thresh)
	var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
	if BloodVolumeMl.entity_uses_ml(entity):
		risk *= PainConsciousnessConstants.PAIN_SHOCK_SUSCEPTIBILITY_MULT_HIGH if blood_pct < 85.0 else 1.0
	else:
		risk *= PainConsciousnessConstants.get_pain_shock_susceptibility_mult(blood_pct) if blood_pct < 85.0 else 1.0
	risk = minf(1.0, risk)
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
	if entity.has_method("is_vital_part_critically_damaged") and entity.is_vital_part_critically_damaged():
		base_consciousness = minf(base_consciousness, 15.0)
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
	var base_mod: float = PainConsciousnessConstants.get_combined_performance_modifier(pain, cons)
	if "blood_volume" in entity:
		var blood_pct: float = clampf(float(entity.blood_volume), 0.0, 100.0)
		if blood_pct < 85.0:
			# Stepped impairment by ATLS class (Class I-IV onset). Matches clinical data:
			# Class II (70-85% remaining): -4 to -12% performance (anxious but functional)
			# Class III (60-70%): -12 to -35% (confused/lethargic, significant motor degradation)
			# Approaching Class IV (<60%): -35 to -70% (near-coma, barely coherent)
			var blood_penalty: float
			match BleedingConstants.atls_hemorrhage_class_from_remaining_pct(blood_pct):
				2:  # Class II
					blood_penalty = lerpf(1.0, 0.88, (85.0 - blood_pct) / 15.0)
				3:  # Class III
					blood_penalty = lerpf(0.88, 0.65, (70.0 - blood_pct) / 10.0)
				4:  # Class IV
					blood_penalty = lerpf(0.65, 0.30, clampf((60.0 - blood_pct) / 15.0, 0.0, 1.0))
				_:
					blood_penalty = 1.0
			base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, blood_penalty)
	# Phase-based concussion effects (perception, balance, visual tracking) with pain-concussion synergy.
	var conc_info: Dictionary = get_concussion_phase_info(entity)
	var conc_perception_mult: float = conc_info.get("perception_mult", 1.0)
	var conc_balance_mult: float = conc_info.get("balance_mult", 1.0)
	var conc_visual_mult: float = conc_info.get("visual_tracking_mult", 1.0)
	var spatial_ms_add: float = conc_info.get("spatial_judgment_ms_add", 0.0)
	var conc_reduction: float = 1.0 - conc_perception_mult
	var pain_shock_reduction: float = 0.0
	var now_check: float = CombatTiming.now_seconds()
	if entity._pain_shock_until_time >= 0.0 and now_check < entity._pain_shock_until_time:
		if PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION > 0.0:
			pain_shock_reduction = PainConsciousnessConstants.PAIN_SHOCK_CONSCIOUSNESS_REDUCTION / 100.0
	# Apply perception modifier from concussion phase.
	base_mod *= conc_perception_mult
	# Pain-concussion synergistic amplification (Gosselin et al., J Neurotrauma 2012).
	## When both pain shock AND concussion are active, they amplify each other synergistically.
	## Interaction term = pain_shock_reduction * concussive_reduction * SYNERGY_FACTOR
	## Applied as additional multiplicative penalty on top of individual effects.
	var synergy_mult: float = 1.0
	if pain_shock_reduction > 0.0 and conc_reduction > 0.0:
		var interaction: float = pain_shock_reduction * conc_reduction * PAIN_CONCUSSION_SYNERGY_FACTOR
		synergy_mult = maxf(1.0 - interaction, 0.0)
	base_mod *= synergy_mult
	# Apply balance impairment (affects movement/dodge).
	base_mod *= conc_balance_mult
	# Apply visual tracking impairment (affects hit chance/parry timing).
	base_mod *= conc_visual_mult
	# SIS catastrophic KO/stun — entity is incapacitated for 30-120s during disorientation period.
	var sis_ko_until: float = 0.0
	if entity.has_meta("_sis_ko_until_time"):
		sis_ko_until = float(entity.get_meta("_sis_ko_until_time", 0.0))
	if sis_ko_until > CombatTiming.now_seconds():
		return PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER
	# Apply spatial judgment impairment — misjudged distance/timing degrades combat accuracy.
	# Baseline simple reaction ~150ms; +450ms spatial error = 3x degradation at critical phase.
	if is_concussed(entity):
		var base_reaction_ms: float = PASSIVE_PARRY_BASE_REACTION_S * 1000.0 # ~240ms baseline parry window
		var spatial_penalty: float = 1.0 - clampf(spatial_ms_add / (spatial_ms_add + base_reaction_ms), 0.0, 0.85)
		base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, spatial_penalty)
	# Apply persistent concussion fatigue — cumulative brain impairment from repeated sub-threshold concussions.
	var persistent_fatigue: float = get_persistent_concussion_fatigue(entity)
	if persistent_fatigue > 0.0:
		base_mod *= maxf(PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER, 1.0 - persistent_fatigue * 0.5)
	return base_mod


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
	var base_reaction: float = PASSIVE_PARRY_BASE_REACTION_S / perception_factor
	if is_concussed(entity):
		var reaction_ms_add: float = get_concussion_reaction_time_ms_add(entity)
		base_reaction += reaction_ms_add / 1000.0
	return base_reaction


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
	if bone_damage_ratio < CONCUSSION_BONE_THRESHOLD_MIN:
		return
	var current_time: float = _get_current_simulation_time(entity)
	var current_until: float = 0.0
	if entity.has_meta("_concussion_until_time"):
		current_until = float(entity.get_meta("_concussion_until_time", 0.0))
	# Cumulative concussion tracking — count prior concussions in this session for SIS and severity escalation.
	var cumulative_count: int = 0
	if entity.has_meta("_cumulative_concussion_count"):
		cumulative_count = int(entity.get_meta("_cumulative_concussion_count", 0))
	# Shared variables to avoid redeclaration across if/fallthrough paths (linter CONFUSABLE_LOCAL_DECLARATION).
	var sis_multiplier: float
	var cumulative_bonus: float
	var who: String
	# Calculate base severity from bone damage ratio (0-1 scale).
	var severity: float = (bone_damage_ratio - CONCUSSION_BONE_THRESHOLD_MIN) / (CONCUSSION_BONE_THRESHOLD_MAX - CONCUSSION_BONE_THRESHOLD_MIN)
	severity = clampf(severity, 0.0, 1.0)
	var entity_damage_ratio: float = _get_entity_overall_damage_ratio(entity)
	var weighted_severity: float = severity * (1.0 - CONCUSSION_DAMAGE_RATIO_FACTOR) + entity_damage_ratio * CONCUSSION_DAMAGE_RATIO_FACTOR
	weighted_severity = clampf(weighted_severity, 0.0, 1.0)
	if current_until > current_time:
		# Re-impact during existing concussion — apply phase-based severity escalation.
		var onset_from_meta: float = current_time # fallback if not set (backward compat)
		if entity.has_meta("_concussion_onset_time"):
			onset_from_meta = float(entity.get_meta("_concussion_onset_time"))
		var time_since_initial: float = current_time - onset_from_meta
		sis_multiplier = _get_sis_severity_multiplier(time_since_initial, cumulative_count)
		cumulative_bonus = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
		var new_weighted_severity_raw: float = weighted_severity * sis_multiplier * cumulative_bonus
		var new_weighted_severity: float = clampf(new_weighted_severity_raw, 0.0, 2.0) # cap at double severity
		check_and_apply_sis_catastrophic_outcome(entity, new_weighted_severity)
		if time_since_initial < CONCUSSION_CRITICAL_DURATION_S and new_weighted_severity <= 0.5:
			# Mild re-impact during critical phase — extend with SIS consideration.
			# Even mild impacts add a minimum severity bump to prevent trivial taps from extending without effect.
			var min_severity_bump: float = 0.05 # at least +5% severity from any head trauma during concussion
			new_weighted_severity = maxf(new_weighted_severity, weighted_severity + min_severity_bump)
			var ext: float = lerp(CONCUSSION_MIN_TOTAL_DURATION_S * 0.25, CONCUSSION_MAX_TOTAL_DURATION_S * 0.3, bone_damage_ratio / CONCUSSION_BONE_THRESHOLD_MAX)
			entity.set_meta("_concussion_until_time", current_until + ext)
		else:
			# Severe re-impact or later phase — calculate extended timeline with phases.
			var total_recover_s = _calculate_total_recovery_duration(new_weighted_severity, cumulative_count + 1, sis_multiplier)
			entity.set_meta("_concussion_until_time", current_time + total_recover_s)
		entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
		entity.set_meta("_last_concussion_time", current_time)
		entity.set_meta("_concussion_onset_time", current_time) # re-impact resets onset for phase tracking
		# Accumulate persistent concussion fatigue from repeated sub-threshold impacts.
		var prior_fatigue: float = float(entity.get_meta("_concussion_persistent_fatigue", 0.0))
		var fatigue_bump: float = minf(bone_damage_ratio * CONCUSSION_PERSISTENT_FATIGUE_PER_HIT, 0.12)
		entity.set_meta("_concussion_persistent_fatigue", clampf(prior_fatigue + fatigue_bump, 0.0, 0.45))
		who = _session_entity_label(entity)
		if OperationalLog.play_session_is_editor_f5():
			CombatF5SoakTrace.note_concussion_entry(who, bone_damage_ratio, float(entity.get_meta("_concussion_until_time", 0.0)) - current_time)
		else:
			CombatDebug.combat_session(
				"concussion_reimpact %s bone_damage=%.2f cumulative=%d total_recovery=%.1fs" % [who, bone_damage_ratio, cumulative_count + 1, float(entity.get_meta("_concussion_until_time", 0.0)) - current_time]
			)
		return
	# Initial concussion — set phase-based recovery timeline.
	## First impact uses no SIS multiplier (SIS only applies to re-impacts during healing).
	sis_multiplier = 1.0 # first impact — not yet in SIS window
	cumulative_bonus = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_SEVERITY_BONUS
	var final_weighted_severity: float = weighted_severity * sis_multiplier * cumulative_bonus
	final_weighted_severity = clampf(final_weighted_severity, 0.0, 2.0)
	var total_recovery_s: float = _calculate_total_recovery_duration(final_weighted_severity, cumulative_count + 1, sis_multiplier)
	entity.set_meta("_concussion_until_time", current_time + total_recovery_s)
	entity.set_meta("_concussion_onset_time", current_time)
	entity.set_meta("_cumulative_concussion_count", cumulative_count + 1)
	entity.set_meta("_last_concussion_time", current_time)
	# Initial concussion also sets persistent fatigue baseline.
	var init_fatigue: float = minf(weighted_severity * CONCUSSION_PERSISTENT_FATIGUE_PER_HIT, 0.12)
	entity.set_meta("_concussion_persistent_fatigue", clampf(init_fatigue, 0.0, 0.45))
	who = _session_entity_label(entity)
	if OperationalLog.play_session_is_editor_f5():
		CombatF5SoakTrace.note_concussion_entry(who, bone_damage_ratio, total_recovery_s)
	else:
		CombatDebug.combat_session(
			"concussion_entered %s bone_damage=%.2f cumulative=%d recovery=%.1fs" % [who, bone_damage_ratio, cumulative_count + 1, total_recovery_s]
		)


static func is_concussed(entity: Node) -> bool:
	if not is_instance_valid(entity) or not entity.is_inside_tree():
		return false
	var curr: float = _get_current_simulation_time(entity)
	var until: float = 0.0
	if entity.has_method("get_meta"):
		until = float(entity.get_meta("_concussion_until_time", 0.0))
	return until > curr


static func get_concussion_phase_info(entity: Node) -> Dictionary:
	"""Returns phase info with smoothly interpolated modifiers across concussion recovery.

	Phase boundaries use proportional weights from PainConsciousnessConstants (Critical=15%, Acute=40%, Subacute=35%, Recovery=10%)
	of the total capped duration. Within each phase, modifiers interpolate linearly between the boundary values,
	mirroring the continuous clinical recovery curve rather than step-function jumps.

	Each modifiable field has two boundary values: at phase onset (start) and phase offset (end).
	The interpolation fraction is time_in_phase / phase_duration, clamped [0,1]."""
	if not is_concussed(entity):
		return {"phase": 0, "time_in_phase": 0.0, "perception_mult": 1.0, "reaction_time_ms_add": 0.0, "balance_mult": 1.0, "visual_tracking_mult": 1.0, "spatial_judgment_ms_add": 0.0, "decision_quality_mult": 1.0, "healing_mult": 1.0}
	var current_time: float = _get_current_simulation_time(entity)
	var until: float = 0.0
	if entity.has_method("get_meta"):
		until = float(entity.get_meta("_concussion_until_time", 0.0))
	var total_duration: float = maxf(until - current_time, 0.01)
	var onset_time: float = current_time
	if entity.has_meta("_concussion_onset_time"):
		onset_time = float(entity.get_meta("_concussion_onset_time"))
	var elapsed: float = minf(maxf(current_time - onset_time, 0.0), total_duration)

	# Phase boundary times (cumulative fractions of total duration).
	var critical_end: float = total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_CRITICAL
	var acute_end: float = critical_end + total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_ACUTE
	var subacute_end: float = acute_end + total_duration * PainConsciousnessConstants.CONCUSSION_PHASE_WEIGHT_SUBACUTE
	# Recovery extends to total_duration (the remainder is 10%).

	# Boundary values at each phase transition point.
	## All fields use the "at onset" value as the starting point of a phase and "at offset" as the ending point.
	## Interpolation: value = start + frac * (end - start), where frac = time_in_phase / phase_duration.

	var phase_id: int = 0
	var perception_mult: float
	var reaction_time_ms_add: float
	var balance_mult: float
	var visual_tracking_mult: float
	var spatial_judgment_ms_add: float
	var decision_quality_mult: float
	var healing_mult: float

	if elapsed < critical_end:
		# Phase: Critical (onset=0, offset=critical_end).
		phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL
		var phase_dur: float = maxf(critical_end, 0.01)
		var frac: float = clampf((elapsed - 0.0) / phase_dur, 0.0, 1.0)
		# Interpolate within critical phase (start=offset from prior phase or initial values, end=critical->acute boundary).
		perception_mult = lerp(0.35, 0.42, frac) # clinical data: 0.25-0.40 at onset; slight improvement even within critical
		reaction_time_ms_add = lerp(500.0, 460.0, frac)
		balance_mult = lerp(0.50, 0.53, frac)
		visual_tracking_mult = lerp(0.30, 0.35, frac)
		spatial_judgment_ms_add = lerp(480.0, 440.0, frac)
		decision_quality_mult = lerp(0.30, 0.38, frac)
		healing_mult = lerp(PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT, PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT, frac)
	elif elapsed < acute_end:
		# Phase: Acute (onset=critical_end, offset=acute_end).
		phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE
		var phase_dur: float = maxf(acute_end - critical_end, 0.01)
		var frac: float = clampf((elapsed - critical_end) / phase_dur, 0.0, 1.0)
		perception_mult = lerp(0.42, 0.60, frac) # recovers from critical boundary to acute-end value
		reaction_time_ms_add = lerp(460.0, 300.0, frac)
		balance_mult = lerp(0.53, 0.70, frac)
		visual_tracking_mult = lerp(0.35, 0.55, frac)
		spatial_judgment_ms_add = lerp(440.0, 240.0, frac)
		decision_quality_mult = lerp(0.38, 0.60, frac)
		healing_mult = lerp(PainConsciousnessConstants.CONCUSSION_HEALING_CRITICAL_MULT, PainConsciousnessConstants.CONCUSSION_HEALING_ACUTE_MULT, frac)
	elif elapsed < subacute_end:
		# Phase: Subacute (onset=acute_end, offset=subacute_end).
		phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_SUBACUTE
		var phase_dur: float = maxf(subacute_end - acute_end, 0.01)
		var frac: float = clampf((elapsed - acute_end) / phase_dur, 0.0, 1.0)
		perception_mult = lerp(0.60, 0.85, frac) # continuity from acute-end value of 0.60
		reaction_time_ms_add = lerp(300.0, 140.0, frac) # continuity from acute-end value of 300
		balance_mult = lerp(0.70, 0.88, frac) # continuity from acute-end value of 0.70
		visual_tracking_mult = lerp(0.55, 0.80, frac) # continuity from acute-end value of 0.55
		spatial_judgment_ms_add = lerp(240.0, 90.0, frac) # continuity from acute-end value of 240
		decision_quality_mult = lerp(0.60, 0.88, frac) # continuity from acute-end value of 0.60
		healing_mult = lerp(PainConsciousnessConstants.CONCUSSION_HEALING_ACUTE_MULT, PainConsciousnessConstants.CONCUSSION_HEALING_SUBACUTE_MULT, frac)
	else:
		# Phase: Recovery (onset=subacute_end, offset=total_duration).
		phase_id = PainConsciousnessConstants.CONCUSSION_PHASE_RECOVERY
		var phase_dur: float = maxf(total_duration - subacute_end, 0.01)
		var frac: float = clampf((elapsed - subacute_end) / phase_dur, 0.0, 1.0)
		perception_mult = lerp(0.85, 1.0, frac) # recovers to full baseline by end of recovery
		reaction_time_ms_add = lerp(140.0, 0.0, frac)
		balance_mult = lerp(0.88, 1.0, frac)
		visual_tracking_mult = lerp(0.80, 1.0, frac)
		spatial_judgment_ms_add = lerp(90.0, 0.0, frac)
		decision_quality_mult = lerp(0.88, 1.0, frac)
		healing_mult = lerp(PainConsciousnessConstants.CONCUSSION_HEALING_SUBACUTE_MULT, PainConsciousnessConstants.CONCUSSION_HEALING_RECOVERY_MULT, frac)

	var time_in_phase: float
	match phase_id:
		PainConsciousnessConstants.CONCUSSION_PHASE_CRITICAL:   time_in_phase = elapsed
		PainConsciousnessConstants.CONCUSSION_PHASE_ACUTE:       time_in_phase = maxf(elapsed - critical_end, 0.0)
		PainConsciousnessConstants.CONCUSSION_PHASE_SUBACUTE:    time_in_phase = maxf(elapsed - acute_end, 0.0)
		PainConsciousnessConstants.CONCUSSION_PHASE_RECOVERY:    time_in_phase = maxf(elapsed - subacute_end, 0.0)

	return {
		"phase": phase_id, "time_in_phase": time_in_phase,
		"perception_mult": perception_mult, "reaction_time_ms_add": reaction_time_ms_add,
		"balance_mult": balance_mult, "visual_tracking_mult": visual_tracking_mult,
		"spatial_judgment_ms_add": spatial_judgment_ms_add, "decision_quality_mult": decision_quality_mult,
		"healing_mult": healing_mult
	}


static func get_concussed_perception_modifier(entity: Node) -> float:
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("perception_mult", 1.0)


static func get_concussion_reaction_time_ms_add(entity: Node) -> float:
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("reaction_time_ms_add", 0.0)


static func get_concussion_balance_modifier(entity: Node) -> float:
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("balance_mult", 1.0)


static func get_concussion_visual_tracking_modifier(entity: Node) -> float:
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("visual_tracking_mult", 1.0)


static func get_spatial_judgment_ms_add(entity: Node) -> float:
	"""Spatial judgment impairment delay (ms). Combat impact: affects parry timing, dodge prediction, aim accuracy."""
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("spatial_judgment_ms_add", 0.0)


static func get_pain_concussion_synergy_penalty(pain_shock_reduction: float, concussive_reduction: float) -> float:
	"""Synergistic interaction term per Gosselin et al. (2012): pain * concussive * factor.
	Returns the additional impairment beyond individual effects when both are present."""
	return pain_shock_reduction * concussive_reduction * PAIN_CONCUSSION_SYNERGY_FACTOR


static func _get_current_simulation_time(_entity: Node) -> float:
	# Use CombatTiming.now_seconds() — same clock as pain shock / ambient pain shock / consciousness updates.
	# The old tree.root.get_age() fallback always returned 0.0 because no scene node implements get_age().
	return CombatTiming.now_seconds()


static func get_decision_quality_mult(entity: Node) -> float:
	"""Concussion-based decision quality degradation per research §6c.
	Returns a multiplier (0-1) that reduces AI decision quality during concussion phases."""
	if not is_concussed(entity):
		return 1.0
	var info: Dictionary = get_concussion_phase_info(entity)
	return info.get("decision_quality_mult", 1.0)


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


static func _get_sis_severity_multiplier(seconds_since_onset: float, cumulative_count: int) -> float:
	"""Returns severity multiplier for Second Impact Syndrome based on time since initial concussion.
	Tiers per research §6d: Critical (0-5min, ×4.5), Early (5-15min, ×2.5), Late (15min-2hr, ×1.75).
	Cumulative concussions extend the vulnerable window by 30% per prior hit."""
	if seconds_since_onset == INF:
		return SIS_SEVERITY_MULTIPLIER_CRITICAL # first impact / just occurred — always critical tier
	var late_window_extended: float = SIS_LATE_WINDOW_S * (1.0 + cumulative_count * 0.3)
	if seconds_since_onset < SIS_CRITICAL_WINDOW_S:
		return SIS_SEVERITY_MULTIPLIER_CRITICAL # 0-5min
	if seconds_since_onset < SIS_EARLY_WINDOW_S:
		return SIS_SEVERITY_MULTIPLIER_EARLY # 5-15min
	if seconds_since_onset < late_window_extended:
		return SIS_SEVERITY_MULTIPLIER_LATE # 15min - extended late window (2hr + cumulative bonus)
	return 1.0 # past vulnerable window — no SIS multiplier


static func _calculate_total_recovery_duration(severity: float, cumulative_count: int, sis_multiplier: float) -> float:
	"""Calculate total recovery time in seconds based on severity, prior concussions, and SIS status.
	Returns a capped duration proportional to clinical recovery curves, scaled for gameplay pacing."""
	var base_recovery: float = lerp(CONCUSSION_MIN_TOTAL_DURATION_S, CONCUSSION_MAX_TOTAL_DURATION_S, severity)
	base_recovery = minf(base_recovery, CONCUSSION_MAX_TOTAL_DURATION_S)
	var cumulative_duration_bonus: float = 1.0 + cumulative_count * CONCUSSION_CUMULATIVE_DURATION_BONUS
	var cumulative_total: float = base_recovery * cumulative_duration_bonus
	# SIS extends recovery up to 50% beyond the cap (models prolonged neurological disruption).
	var sis_extension: float = maxf(sis_multiplier - 1.0, 0.0) * cumulative_total * 0.5
	var total_with_sis: float = cumulative_total + sis_extension
	# Apply hard cap after SIS extension to prevent runaway durations in extreme cases.
	return minf(total_with_sis, CONCUSSION_MAX_TOTAL_DURATION_S * 1.5)


static func get_second_impact_vulnerable(entity: Node) -> bool:
	"""Check if entity is in SIS vulnerable window (brain still healing from prior concussion).
	Tier boundaries: Critical 0-5min, Early 5-15min, Late 15min-2hr; cumulative hits extend by 30% each."""
	if not is_concussed(entity):
		var last_time: float = -1.0
		if entity.has_meta("_last_concussion_time"):
			last_time = float(entity.get_meta("_last_concussion_time", -1.0))
		if last_time < 0.0:
			return false
		var current_time: float = _get_current_simulation_time(entity)
		var elapsed: float = current_time - last_time
		var cumulative_count: int = get_cumulative_concussion_count(entity)
		var late_window_extended: float = SIS_LATE_WINDOW_S * (1.0 + cumulative_count * 0.3)
		return elapsed < maxf(late_window_extended, SIS_CRITICAL_WINDOW_S)
	return true # actively concussed = vulnerable


static func is_in_sis_critical_window(entity: Node) -> bool:
	"""Returns true if second impact within first 5 minutes of initial concussion (SIS risk highest)."""
	if not entity.has_meta("_last_concussion_time"):
		return false
	var last_time: float = float(entity.get_meta("_last_concussion_time", -1.0))
	if last_time < 0.0:
		return false
	var current_time: float = _get_current_simulation_time(entity)
	return (current_time - last_time) < SIS_CRITICAL_WINDOW_S


static func get_cumulative_concussion_count(entity: Node) -> int:
	"""Returns number of concussions this entity has sustained in the current session."""
	if entity.has_meta("_cumulative_concussion_count"):
		return int(entity.get_meta("_cumulative_concussion_count", 0))
	return 0


static func check_and_apply_sis_catastrophic_outcome(entity: Node, sis_severity: float) -> bool:
	"""Check for Second Impact Syndrome catastrophic outcome per research §6d.
	Returns true if SIS catastrophic event occurred (KO state triggered).
	SIS catastrophic outcomes: immediate KO/stun, extended recovery days, permanent stat reduction (-5% to -15%).
	SIS is most likely when severity_multiplier >= 4.0 (critical tier) and second impact delivers significant trauma."""
	if not entity.is_inside_tree() or not entity.has_method("_get_vital_parts"):
		return false
	var vital_parts: Array = entity._get_vital_parts()
	if "head" not in vital_parts:
		return false
	# SIS catastrophic threshold: critical tier (>=4.0x) with meaningful second-impact severity
	if sis_severity < 4.0:
		return false
	# Apply immediate stun/disorientation — entity is effectively KO'd for a period
	var sis_ko_duration_s: float = lerp(30.0, 120.0, (sis_severity - 4.0) / 3.0) # 30-120s based on severity
	if entity.has_method("_apply_stun"):
		entity._apply_stun(sis_ko_duration_s, "second_impact_syndrome")
	elif entity.has_method("set_meta"):
		entity.set_meta("_sis_ko_until_time", _get_current_simulation_time(entity) + sis_ko_duration_s)
	# Apply extended recovery beyond normal concussion timeline (can be days in real-world mTBI)
	var existing_until: float = 0.0
	if entity.has_meta("_concussion_until_time"):
		existing_until = float(entity.get_meta("_concussion_until_time", 0.0))
	var sis_recovery_extension: float = lerp(3600.0, 43200.0, (sis_severity - 4.0) / 3.0) # 1hr to 12hr extension
	if existing_until > _get_current_simulation_time(entity):
		entity.set_meta("_concussion_until_time", existing_until + sis_recovery_extension)
	else:
		entity.set_meta("_concussion_until_time", _get_current_simulation_time(entity) + sis_recovery_extension)
	# Apply permanent stat reduction (-5% to -15%) — reflects lasting TBI damage
	var perm_stat_reduction: float = lerp(0.05, 0.15, (sis_severity - 4.0) / 3.0) # 5-15% reduction
	if entity.has_method("_apply_permanent_stat_reduction"):
		entity._apply_permanent_stat_reduction(perm_stat_reduction)
	elif entity.has_method("set_meta") and entity.has_meta("_sis_perm_stat_reduced"):
		var current_reduction: float = float(entity.get_meta("_sis_perm_stat_reduced", 0.0))
		entity.set_meta("_sis_perm_stat_reduced", minf(current_reduction + perm_stat_reduction, 0.30)) # cap at 30%
	elif entity.has_method("set_meta"):
		entity.set_meta("_sis_perm_stat_reduced", perm_stat_reduction)
	# Accumulate persistent concussion fatigue spike from SIS — represents lasting brain trauma beyond normal recovery.
	var prior_fatigue_sis: float = float(entity.get_meta("_concussion_persistent_fatigue", 0.0))
	entity.set_meta("_concussion_persistent_fatigue", clampf(prior_fatigue_sis + 0.25, 0.0, 0.45))
	# Flag that SIS catastrophic event occurred (for UI display / medical treatment)
	if entity.has_method("set_meta"):
		entity.set_meta("_sis_catastrophic_flag", true)
		return true
	return false


static func get_sis_perm_stat_reduction(entity: Node) -> float:
	"""Returns permanent stat reduction fraction from prior SIS catastrophic events."""
	if entity.has_meta("_sis_perm_stat_reduced"):
		return clampf(float(entity.get_meta("_sis_perm_stat_reduced", 0.0)), 0.0, 0.30)
	return 0.0


static func was_sis_catastrophic(entity: Node) -> bool:
	"""Returns true if entity has suffered a SIS catastrophic outcome."""
	if entity.has_meta("_sis_catastrophic_flag"):
		return bool(entity.get_meta("_sis_catastrophic_flag", false))
	return false


static func get_effective_stat_with_sis_reduction(entity: Node, stat_name: String) -> float:
	"""Get effective stat value accounting for permanent SIS reduction.
	Note: EntityStatsUtil.get_effective_stat() already applies SIS reduction internally, so this is now a pass-through."""
	return EntityStatsUtil.get_effective_stat(entity, stat_name) if entity.has_method("get_meta") else 0.0


static func get_persistent_concussion_fatigue(entity: Node) -> float:
	"""Returns accumulated persistent concussion fatigue from repeated sub-threshold concussions (0-1 scale).
	This represents cumulative brain fatigue that lingers after individual concussions resolve,
	affecting performance until cleared by rest/recuperation between sessions."""
	if entity.has_meta("_concussion_persistent_fatigue"):
		return clampf(float(entity.get_meta("_concussion_persistent_fatigue", 0.0)), 0.0, 1.0)
	return 0.0


static func clear_concussion_fatigue(entity: Node) -> void:
	"""Clear persistent concussion fatigue — call after extended rest or between campaign sessions."""
	if entity.has_method("set_meta"):
		entity.set_meta("_concussion_persistent_fatigue", 0.0)


static func apply_attacker_windup_concussion_mult(_manager: Variant, attacker: Dictionary, wind_up_s: float) -> float:
	"""Concussion-based windup extension for attackers per research — impaired motor planning increases initiation time.
	Windup penalty is inversely related to decision_quality_mult and interpolated continuously across phases."""
	var entity_node = CombatantEntityAccess.scene_node(attacker)
	if entity_node == null or not is_concussed(entity_node):
		return wind_up_s
	var info = get_concussion_phase_info(entity_node)
	var dq = info.get("decision_quality_mult", 1.0)
	# decision_quality goes 0.30(critical) -> 1.0(recovery); windup penalty goes +30% -> +5%.
	# Map: windup_mult = 1.0 + lerp(0.30, 0.05, 1.0 - dq) where dq in [0.30, 1.0]
	var normalized_dq = clampf((dq - 0.30) / 0.70, 0.0, 1.0) # normalize to [0,1] over clinical range
	return wind_up_s * lerp(1.30, 1.05, normalized_dq)
