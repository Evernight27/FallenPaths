class_name EntityWounds
extends RefCounted

## Wound list, bleeding rates, clotting, and wound creation for entities with wounds dict and game time.
## Entity must have: wounds, body_max, bone_max, _game_time_seconds, endurance, tourniquet_applied,
## direct_pressure_part, self_direct_pressure_part, direct_pressure_held_by, name.

## Reference impact energy (J) — mirrors WeaponConstants.J_PER_MM_BASE = 55 J Williams baseline.
## Kept local to avoid circular preload; both values must stay synchronized at 55.0.
const _IMPACT_KE_REF_J := 55.0
const _SEVERITY_KE_BLEND := 0.28
const _BLEED_KE_BLEND := 0.32


static func effective_endurance_for_clotting(entity: Node) -> float:
	return EntityStatsUtil.get_effective_stat(entity, "endurance")


# Impact KE coupling for wounds (tune with weapon KE bands in WeaponDamageHelper / ImpactVelocityModel).
# ~55 J aligns with typical one-handed cut/thrust order of magnitude used in WeaponConstants / armor docs.

# --- Wound healing progress (used by pain and process_healing) ---


static func _get_wound_healing_progress(entity: Node, injury: Dictionary) -> float:
	var created: float = injury.get("created_at_game_time", -1.0)
	var duration: float = injury.get("healing_duration_seconds", 0.0)
	if created < 0.0 or duration <= 0.0:
		return 0.0
	var age: float = entity._game_time_seconds - created
	if age <= 0.0:
		return 0.0
	var tau: float = duration / HealingConstants.EXPONENTIAL_HEAL_TAU_DIVISOR
	return 1.0 - exp(-age / tau)


# --- Severity (used when adding wounds from damage) ---


static func _severity_from_pct(pct: float) -> String:
	if pct >= BleedingConstants.SEVERITY_PERCENTAGE_CRITICAL:
		return BleedingConstants.SEVERITY_CRITICAL
	if pct >= BleedingConstants.SEVERITY_PERCENTAGE_SEVERE:
		return BleedingConstants.SEVERITY_SEVERE
	if pct >= BleedingConstants.SEVERITY_PERCENTAGE_MODERATE:
		return BleedingConstants.SEVERITY_MODERATE
	return BleedingConstants.SEVERITY_MINOR


static func _severity_order() -> Array:
	return [
		BleedingConstants.SEVERITY_MINOR,
		BleedingConstants.SEVERITY_MODERATE,
		BleedingConstants.SEVERITY_SEVERE,
		BleedingConstants.SEVERITY_CRITICAL,
	]


static func _severity_from_abs_tissue(effective_damage: float) -> String:
	if effective_damage >= BleedingConstants.SEVERITY_ABSOLUTE_CRITICAL:
		return BleedingConstants.SEVERITY_CRITICAL
	if effective_damage >= BleedingConstants.SEVERITY_ABSOLUTE_SEVERE:
		return BleedingConstants.SEVERITY_SEVERE
	if effective_damage >= BleedingConstants.SEVERITY_ABSOLUTE_MODERATE:
		return BleedingConstants.SEVERITY_MODERATE
	return BleedingConstants.SEVERITY_MINOR


static func _severity_from_abs_bone(bone_damage: float) -> String:
	if bone_damage >= BleedingConstants.SEVERITY_ABSOLUTE_BONE_CRITICAL:
		return BleedingConstants.SEVERITY_CRITICAL
	if bone_damage >= BleedingConstants.SEVERITY_ABSOLUTE_BONE_SEVERE:
		return BleedingConstants.SEVERITY_SEVERE
	if bone_damage >= BleedingConstants.SEVERITY_ABSOLUTE_BONE_MODERATE:
		return BleedingConstants.SEVERITY_MODERATE
	return BleedingConstants.SEVERITY_MINOR


static func _compose_severity_abs_and_pct(sev_abs: String, sev_pct: String) -> String:
	var order: Array = _severity_order()
	if BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP:
		return order[mini(order.find(sev_abs), order.find(sev_pct))]
	return sev_abs


static func severity_from_damage(
	entity: Node,
	part: String,
	damage: float,
	sub_region: String = "",
	impact_ke_j: float = -1.0,
	penetration_to_tissue_mm: float = -1.0
) -> String:
	var max_hp: float = entity.body_max.get(part, 10)
	if max_hp <= 0.0:
		return BleedingConstants.SEVERITY_MODERATE
	var ke_mult: float = 1.0
	if impact_ke_j >= 0.0:
		ke_mult = 1.0 + _SEVERITY_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
	var depth_mult: float = BleedingConstants.penetration_depth_severity_mult(penetration_to_tissue_mm)
	var sub_mult: float = 1.0
	if not CombatConstants.is_feature_subregion_combat_mult_enabled():
		sub_mult = BleedingConstants.get_severity_modifier(part, sub_region)
	var effective_damage: float = damage * ke_mult * depth_mult * sub_mult
	var pct: float = effective_damage / max_hp
	var sev_pct: String = _severity_from_pct(pct)
	if BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS:
		return _compose_severity_abs_and_pct(_severity_from_abs_tissue(effective_damage), sev_pct)
	return sev_pct


static func severity_from_bone_damage(entity: Node, part: String, bone_damage: float) -> String:
	if bone_damage <= 0.0:
		return BleedingConstants.SEVERITY_MINOR
	var max_bone: float = entity.bone_max.get(part, 1)
	if max_bone <= 0.0:
		return BleedingConstants.SEVERITY_MODERATE
	if BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_BANDS:
		var sev_abs: String = _severity_from_abs_bone(bone_damage)
		if BleedingConstants.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP:
			var sev_pct: String = _severity_from_pct(bone_damage / max_bone)
			return _compose_severity_abs_and_pct(sev_abs, sev_pct)
		return sev_abs
	return _severity_from_pct(bone_damage / max_bone)


static func _severity_rank(sev: String) -> int:
	var order: Array = _severity_order()
	var idx: int = order.find(sev)
	return idx if idx >= 0 else 1


## Same part + sub_region during one fight -> one wound channel worsens (not N separate pack procedures).
static func _try_merge_wound_into_channel(
	entity: Node,
	part: String,
	injury_type: String,
	damage: float,
	sub_region: String,
	severity: String,
	base_rate: float,
	is_arterial: bool,
	healing_duration: float,
	penetration_to_tissue_mm: float = -1.0
) -> bool:
	if not entity.wounds.has(part):
		return false
	var sr_key: String = sub_region if not sub_region.is_empty() else ""
	for injury in entity.wounds[part]:
		if injury.get("sub_region", "") != sr_key:
			continue
		var existing_type: String = injury.get("injury_type", "")
		if existing_type != injury_type and base_rate > 0.0:
			var penetrating_types: Array = [BleedingConstants.INJURY_TYPE_CUT, BleedingConstants.INJURY_TYPE_CRUSH, BleedingConstants.INJURY_TYPE_STAB]
			if existing_type not in penetrating_types:
				continue
			if injury_type not in penetrating_types:
				continue
		injury["cumulative_damage"] = injury.get("cumulative_damage", 0.0) + damage
		if _severity_rank(severity) > _severity_rank(injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE)):
			injury[DataKeys.INJURY_SEVERITY] = severity
		# Deepest track dominates the channel (drives sustained pain + bleeding depth terms).
		injury["penetration_to_tissue_mm"] = maxf(
			float(injury.get("penetration_to_tissue_mm", -1.0)), penetration_to_tissue_mm
		)
		if is_arterial:
			injury["is_arterial"] = true
		if base_rate > 0.0:
			var prev_base: float = injury.get("base_bleeding_rate", 0.0)
			var prev_cur: float = injury.get("current_bleeding_rate", 0.0)
			injury["base_bleeding_rate"] = prev_base + base_rate
			injury["current_bleeding_rate"] = prev_cur + base_rate
			injury["is_stabilized"] = false
			injury.erase("stabilized_remaining_seconds")
		elif injury.get("healing_duration_seconds", 0.0) == 0.0:
			injury["healing_duration_seconds"] = healing_duration
		return true
	return false


# --- Add wound / stump wound ---


static func add_wound(
	entity: Node,
	part: String,
	injury_type: String,
	damage: float,
	sub_region: String = "",
	severity_override: String = "",
	impact_ke_j: float = -1.0,
	penetration_to_tissue_mm: float = -1.0,
	extra_flags: Dictionary = {}
) -> void:
	if part.is_empty() or damage <= 0.0:
		return
	var severity: String = (
		severity_override
		if not severity_override.is_empty()
		else severity_from_damage(entity, part, damage, sub_region, impact_ke_j, penetration_to_tissue_mm)
	)
	if injury_type == BleedingConstants.INJURY_TYPE_CRUSH and severity == BleedingConstants.SEVERITY_MINOR:
		injury_type = BleedingConstants.INJURY_TYPE_BRUISE
	var base_rate: float = BleedingConstants.get_bleeding_rate(injury_type, severity, part, sub_region)
	if base_rate < 0.0:
		base_rate = 0.0
	if extra_flags.get("dagger_wound", false):
		base_rate *= BleedingConstants.DAGGER_BLEED_MULTIPLIER
	if base_rate > 0.0 and injury_type == BleedingConstants.INJURY_TYPE_CUT:
		if impact_ke_j >= 0.0:
			base_rate *= 1.0 + _BLEED_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
		base_rate *= BleedingConstants.penetration_depth_severity_mult(penetration_to_tissue_mm)
		base_rate *= CombatLayerTissue.layer_rupture_bleed_mult(entity, part)
	if base_rate > 0.0:
		base_rate *= randf_range(
			BleedingConstants.BLEEDING_RATE_VARIANCE_MIN, BleedingConstants.BLEEDING_RATE_VARIANCE_MAX
		)
	var pen_for_arterial: float = penetration_to_tissue_mm if injury_type == BleedingConstants.INJURY_TYPE_CUT else -1.0
	var is_arterial: bool = (
		randf() < BleedingConstants.get_arterial_chance(severity, injury_type, part, sub_region, pen_for_arterial)
		if base_rate > 0.0
		else false
	)
	if base_rate > 0.0 and is_arterial:
		base_rate *= BleedingConstants.BLEEDING_TYPE_RATE_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL]
	if entity.wounds.get(part) == null:
		entity.wounds[part] = []
	var healing_duration: float = HealingConstants.get_wound_healing_duration_seconds(part, severity, injury_type)
	if _try_merge_wound_into_channel(
		entity, part, injury_type, damage, sub_region, severity, base_rate, is_arterial, healing_duration,
		penetration_to_tissue_mm
	):
		return
	var injury: Dictionary = {
		"injury_type": injury_type,
		"severity": severity,
		"damage": damage,
		"cumulative_damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": entity._game_time_seconds,
		"healing_duration_seconds": healing_duration,
		"compensation_mult": 1.0,
		"penetration_to_tissue_mm": penetration_to_tissue_mm
	}
	entity.wounds[part].append(injury)
	# Compound fracture cascade: when ≥2 fractures on different bones in same limb (arm/leg),
	## escalate to compound_fracture — open bone exposure causes 3-5x hemorrhage and 30% lower
	## pain shock threshold per J Trauma 2019 (Gustilo-Anderson type I/II dynamics).
	if injury_type == BleedingConstants.INJURY_TYPE_FRACTURE:
		_try_escalate_compound_fracture(entity, part)


static func _try_escalate_compound_fracture(entity: Node, fracture_part: String) -> void:
	var limb_parts: Array = []
	if BodyPartQuery.is_arm(fracture_part):
		limb_parts = [BodyPartConstants.PART_RIGHT_ARM, BodyPartConstants.PART_LEFT_ARM]
	elif BodyPartQuery.is_leg(fracture_part):
		limb_parts = [BodyPartConstants.PART_RIGHT_LEG, BodyPartConstants.PART_LEFT_LEG]
	else:
		return
	for lp in limb_parts:
		if not entity.wounds.has(lp):
			continue
		var fracture_count_in_limb: int = 0
		for inj in entity.wounds[lp]:
			if inj.get("injury_type") == BleedingConstants.INJURY_TYPE_FRACTURE:
				fracture_count_in_limb += 1
		if fracture_count_in_limb >= 2:
			var new_wounds: Array = []
			for inj in entity.wounds[lp]:
				if inj.get("injury_type") == BleedingConstants.INJURY_TYPE_FRACTURE:
					var compounded: Dictionary = inj.duplicate(true)
					compounded["injury_type"] = BleedingConstants.INJURY_TYPE_COMPOUND_FRACTURE
					var current_rate: float = compounded.get("current_bleeding_rate", 0.0)
					var base_rate: float = compounded.get("base_bleeding_rate", 0.0)
					if base_rate > 0.0:
						compounded["base_bleeding_rate"] = base_rate * 2.5
						compounded["current_bleeding_rate"] = current_rate * 2.5
					compounded["is_compound_fracture"] = true
					if compounded.has("pain_shock_threshold_mult"):
						compounded["pain_shock_threshold_mult"] *= 0.7
					new_wounds.append(compounded)
				else:
					new_wounds.append(inj)
			entity.wounds[lp] = new_wounds


static func create_stump_wound(entity: Node, part: String, sub_region: String) -> Array:
	if sub_region.is_empty():
		sub_region = BleedingConstants.get_random_sub_region(part)
	var base_rate: float = BleedingConstants.get_stump_bleeding_rate(part, sub_region)
	## Stump bleeding variation ±8% around baseline — models anatomical variance in vessel size/position.
	## Clinically, stump hemorrhage rates vary ~15-20% even within same body region; ±8% is conservative.
	var variation: float = 0.92 + randf() * 0.16
	base_rate *= variation
	var arterial_chance: float = (
		BleedingConstants.get_arterial_chance(
			BleedingConstants.SEVERITY_CRITICAL, BleedingConstants.INJURY_TYPE_CUT, part, sub_region
		)
		* BleedingConstants.STUMP_ARTERIAL_CHANCE_MULTIPLIER
	)
	arterial_chance = clampf(arterial_chance, 0.0, 1.0)
	var is_arterial: bool = randf() < arterial_chance
	if is_arterial:
		base_rate *= BleedingConstants.BLEEDING_TYPE_RATE_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL]
	var damage: float = entity.body_max.get(part, 10)
	var healing_duration: float = HealingConstants.get_wound_healing_duration_seconds(
		part, BleedingConstants.SEVERITY_CRITICAL, BleedingConstants.INJURY_TYPE_CUT
	)
	var injury: Dictionary = {
		"injury_type": BleedingConstants.INJURY_TYPE_CUT,
		"severity": BleedingConstants.SEVERITY_CRITICAL,
		"damage": damage,
		"sub_region": sub_region,
		"base_bleeding_rate": base_rate,
		"current_bleeding_rate": base_rate,
		"is_stabilized": false,
		"is_arterial": is_arterial,
		"created_at_game_time": entity._game_time_seconds,
		"healing_duration_seconds": healing_duration,
		"is_stump": true,
		"compensation_mult": 1.0
	}
	return [injury]


static func has_stump_wound(entity: Node, part: String) -> bool:
	if part.is_empty() or not entity.wounds.has(part):
		return false
	for injury in entity.wounds[part]:
		if injury.get("is_stump", false):
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


static func part_has_active_direct_pressure(entity: Node, part: String) -> bool:
	if part.is_empty():
		return false
	return part == entity.direct_pressure_part or part == entity.self_direct_pressure_part


static func part_has_definitive_hemostasis(entity: Node, part: String) -> bool:
	if part.is_empty():
		return false
	if entity.bandaged_parts.get(part, false) or entity.packed_parts.get(part, false):
		return true
	return entity.tourniquet_applied.has(part)


static func get_bleeding_rate_for_part(entity: Node, part: String) -> float:
	if not entity.wounds.has(part):
		return 0.0
	var rate: float = 0.0
	var under_pressure: bool = part_has_active_direct_pressure(entity, part)
	for injury in entity.wounds[part]:
		var r: float = injury.get("current_bleeding_rate", 0.0)
		if under_pressure:
			r *= BleedingConstants.direct_pressure_held_flow_retained(injury.get("is_arterial", false))
		rate += r
	if not entity.tourniquet_applied.has(part):
		return rate
	EntityMedical.ensure_tourniquet_dict_entry(entity, part)
	var data: Dictionary = entity.tourniquet_applied[part]
	var eff: float = data.get("effectiveness", 1.0)
	var reduction: float = eff * BleedingConstants.TOURNIQUET_REDUCTION_AT_FULL
	return rate * (1.0 - reduction)


static func get_total_bleeding_rate(entity: Node) -> float:
	var total: float = 0.0
	for part in entity.wounds:
		total += get_bleeding_rate_for_part(entity, part)
	return total


static func get_permanent_bleeding_rate(entity: Node) -> float:
	return get_total_bleeding_rate(entity)


# --- Wound queries ---


static func get_wounded_parts(entity: Node) -> Array:
	if entity == null or not is_instance_valid(entity):
		return []
	if not ("wounds" in entity) or not (entity.wounds is Dictionary):
		return []
	var out: Array = []
	for part in (entity.wounds as Dictionary).keys():
		out.append(part)
	return out


## Any wounded part without bandage, pack, or tourniquet (pressure / stabilize alone do not count).
static func entity_has_untreated_wounds(entity: Node) -> bool:
	if entity == null:
		return false
	for part in get_wounded_parts(entity):
		if not part_has_definitive_hemostasis(entity, str(part)):
			return true
	return false


## Higher = treat this part before milder wounds (bleed rate + severity + arterial/stump + TQ indication).
static func get_part_intervention_threat(entity: Node, part: String) -> float:
	if entity == null or part.is_empty() or not entity.wounds.has(part):
		return 0.0
	var rate: float = get_bleeding_rate_for_part(entity, part)
	var bonus: float = 0.0
	for injury in entity.wounds[part]:
		if injury.get("is_arterial", false):
			bonus += 2.25
		if injury.get("is_stump", false):
			bonus += 4.5
		var sev: String = str(injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE))
		if sev == BleedingConstants.SEVERITY_CRITICAL:
			bonus += 1.6
		elif sev == BleedingConstants.SEVERITY_SEVERE:
			bonus += 0.85
	if EntityMedical._is_tourniquet_indicated_for_part(entity, part):
		bonus += 1.15
	return rate * 3.5 + bonus


## Concussion triage priority escalation (Issue 6a).
## A concussed entity receives a medical urgency boost so treatment AI prioritizes them alongside
## actively-bleeding casualties. Uses interpolated perception_mult for continuous severity scoring:
## lower perception_mult = more impaired = higher triage priority.
static func get_concussion_triage_bonus(entity: Node) -> float:
	if entity == null or not entity.has_meta("_concussion_until_time"):
		return 0.0
	var info: Dictionary = EntityPainConsciousness.get_concussion_phase_info(entity)
	var perc_mult: float = info.get("perception_mult", 1.0)
	## Map perception_mult [0.35..1.0] → triage bonus [8.0..0.0]:
	## At onset (perc=0.35): urgent, equivalent to multi-part critical bleeding (bonus=8).
	## Mid-recovery (perc≈0.73): moderate urgency (bonus≈4).
	## Near baseline (perc→1.0): bonus fades toward 0.
	var cur_impairment: float = 1.0 - perc_mult # 0 at full health, ~0.65 at worst concussion
	var max_possible_impairment: float = 1.0 - PainConsciousnessConstants.CONCUSSION_PERCEPTION_CRITICAL_MIN
	var normalized: float = clampf(cur_impairment / maxf(max_possible_impairment, 0.001), 0.0, 1.0)
	return lerp(0.0, 8.0, normalized)


## Untreated parts highest threat first (map field care + triage ordering).
static func sorted_untreated_part_names(entity: Node) -> Array:
	var parts: Array = []
	if entity == null:
		return parts
	for raw in get_wounded_parts(entity):
		var p: String = str(raw)
		if part_has_definitive_hemostasis(entity, p):
			continue
		parts.append(p)
	parts.sort_custom(
		func(a, b) -> bool: return get_part_intervention_threat(entity, a) > get_part_intervention_threat(entity, b)
	)
	return parts


static func get_wounds(entity: Node) -> Dictionary:
	return entity.wounds.duplicate(true)


# --- Process bleeding (clotting, direct-pressure auto-clear) ---


## Do not release pressure while blood volume is still at/below bleed-out threshold (rate may be ~0).
static func _blood_volume_safe_to_release_pressure(entity: Node) -> bool:
	if entity == null:
		return false
	var threshold: float = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		threshold = float(entity._get_blood_loss_death_threshold())
	return float(entity.blood_volume) > threshold


## Safe to stop holding: dressed/packed/tourniqueted only  -  do not release on local clot alone (TCCC: keep compression
## until dressed).
static func _hemostasis_allows_pressure_release(entity: Node, part: String) -> bool:
	return part_has_definitive_hemostasis(entity, part) and _blood_volume_safe_to_release_pressure(entity)


static func _pressure_release_reason(entity: Node, part: String) -> String:
	if part_has_definitive_hemostasis(entity, part):
		if entity.bandaged_parts.get(part, false):
			return "bandaged"
		if entity.packed_parts.get(part, false):
			return "packed"
		if entity.tourniquet_applied.has(part):
			return "tourniquet"
		return "dressed"
	if not _blood_volume_safe_to_release_pressure(entity):
		return "blood_volume_at_threshold"
	return "bleeding_stopped"


## Early release without dressing: partial rebleed (TCCC: do not let go until controlled).
## When clotting has significantly reduced the rate, only partial rebound occurs (tissue trauma already initiated
## hemostasis cascade).
static func rebound_bleeding_after_pressure_release(entity: Node, part: String) -> void:
	if part.is_empty() or not entity.wounds.has(part):
		return
	if part_has_definitive_hemostasis(entity, part):
		return
	var before: float = get_bleeding_rate_for_part(entity, part)
	for injury in entity.wounds[part]:
		var rate: float = injury.get("current_bleeding_rate", 0.0)
		var base: float = float(injury.get("base_bleeding_rate", rate))
		var clotting_ratio: float = clampf(rate / maxf(base, 0.001), 0.0, 1.0)
		var full_rebound: float = base * BleedingConstants.DIRECT_PRESSURE_REBOUND_TO_INTRINSIC_MULT
		var partial_factor: float = lerpf(BleedingConstants.DIRECT_PRESSURE_REBOUND_PARTIAL_MULT, 1.0, clotting_ratio)
		var target: float = maxf(rate, full_rebound * partial_factor)
		injury["current_bleeding_rate"] = target
		injury["is_stabilized"] = false
		injury.erase("stabilized_remaining_seconds")
	var after: float = get_bleeding_rate_for_part(entity, part)
	# Always log pressure rebound  -  it is a critical UX event (player sees bleeding spike without understanding why).
	# Bypass EntityMedical.log_medical_session which filters these in F5 sessions.
	CombatDebug.medical_session(
		"%s pressure_rebound part=%s bleed %.3f->%.3f (released without dressing)" % [entity.name, part, before, after]
	)


static func process_bleeding(entity: Node, delta: float) -> void:
	for part in entity.wounds.keys():
		var under_pressure: bool = part_has_active_direct_pressure(entity, part)
		var list: Array = entity.wounds[part]
		var i: int = list.size() - 1
		while i >= 0:
			var injury: Dictionary = list[i]
			var rate: float = injury.get("current_bleeding_rate", 0.0)
			var clotting: float
			if injury.get("is_stabilized", false):
				clotting = BleedingConstants.CLOTTING_RATE_STABILIZED
				if under_pressure:
					clotting = maxf(clotting, BleedingConstants.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
				if injury.get("is_arterial", false):
					if under_pressure:
						# Stabilized arterial wound under direct pressure/tourniquet achieves hemostasis — no additional penalty.
						pass
					else:
						clotting *= BleedingConstants.BLEEDING_TYPE_CLOTTING_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL]
			else:
				var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE)
				clotting = BleedingConstants.get_clotting_rate(sev) * BleedingConstants.get_clotting_multiplier(sev)
				if injury.get("is_arterial", false):
					clotting *= BleedingConstants.BLEEDING_TYPE_CLOTTING_MULT[BleedingConstants.BLEEDING_TYPE_ARTERIAL]
				if under_pressure:
					clotting = maxf(clotting, BleedingConstants.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
				var end_factor: float = clampf(
					0.9 + EntityWounds.effective_endurance_for_clotting(entity) / 1000.0, 0.9, 1.1
				)
				clotting *= end_factor
				# Active combat reduces clotting effectiveness (lethal triad: movement,
				# adrenaline, physical trauma reopen clots and impair coagulation)
				if "exertion_active" in entity and entity.exertion_active:
					clotting *= 0.6
				# Pain shock causes sympathetic surge that impairs coagulation — clinical
				# evidence shows acute stress response delays hemostasis beyond exertion alone.
				if entity.has_method("_pain_shock_until_time") and entity._pain_shock_until_time >= 0.0:
					var now: float = CombatTiming.now_seconds()
					if now < entity._pain_shock_until_time:
						clotting *= 0.75
			# Compensatory delay (vasoconstriction): bleeding starts at full rate, then decays toward
			# a sustained baseline (~35%) over ~30 s. This models the ATLS compensation phase where
			# sympathetic nervous system triggers vasoconstriction to limit hemorrhage before shock onset.
			var comp_mult: float = injury.get("compensation_mult", 1.0)
			if comp_mult > BleedingConstants.COMPENSATION_FLOOR_MULT:
				injury["compensation_mult"] = maxf(
					BleedingConstants.COMPENSATION_FLOOR_MULT,
					comp_mult - BleedingConstants.COMPENSATION_DECAY_RATE * delta
				)
			# Compensation (vasoconstriction) is tracked on the injury for display/debug; rate reduction is handled by
			# clotting alone so bleeding decays on the clinical minutes timescale (moderate cuts clot in 2-7 min).
			rate *= exp(-clotting * delta)
			rate = maxf(0.0, rate)
			if rate <= BleedingConstants.BLEEDING_RATE_EPSILON:
				rate = 0.0
			injury["current_bleeding_rate"] = rate
			i -= 1
	if (
		not entity.direct_pressure_part.is_empty()
		and _hemostasis_allows_pressure_release(entity, entity.direct_pressure_part)
	):
		var ally_part: String = entity.direct_pressure_part
		var reason_ally: String = _pressure_release_reason(entity, ally_part)
		EntityMedical.log_medical_session(
			(
				"%s direct_pressure auto-cleared part=%s (ally-held) reason=%s bv=%.1f"
				% [entity.name, ally_part, reason_ally, float(entity.blood_volume)]
			)
		)
		if entity.direct_pressure_held_by != null and "direct_pressure_on_ally" in entity.direct_pressure_held_by:
			entity.direct_pressure_held_by.direct_pressure_on_ally = {}
		entity.direct_pressure_held_by = null
		if entity.get("direct_pressure_assist_held_by") != null and entity.direct_pressure_assist_held_by != null:
			var asst_auto: Variant = entity.direct_pressure_assist_held_by
			if asst_auto != null and "direct_pressure_on_ally" in asst_auto:
				asst_auto.direct_pressure_on_ally = {}
			entity.direct_pressure_assist_held_by = null
		entity.direct_pressure_part = ""
	if (
		not entity.self_direct_pressure_part.is_empty()
		and _hemostasis_allows_pressure_release(entity, entity.self_direct_pressure_part)
	):
		var self_part: String = entity.self_direct_pressure_part
		var reason_self: String = _pressure_release_reason(entity, self_part)
		EntityMedical.log_medical_session(
			(
				"%s direct_pressure auto-cleared part=%s (self-held) reason=%s bv=%.1f"
				% [entity.name, self_part, reason_self, float(entity.blood_volume)]
			)
		)
		entity.self_direct_pressure_part = ""


# --- Process blood loss (drain from bleeding rate; death at threshold) ---
## Entity must have: blood_volume, _update_consciousness (optional), died signal,
## _get_blood_loss_death_threshold (optional).
static func process_blood_loss(entity: Node, delta: float) -> void:
	if entity != null and entity.has_method("is_dead") and entity.is_dead():
		return
	var total: float = get_total_bleeding_rate(entity)
	var loss_mult: float = 1.0
	var recovery_per_s: float = 0.0
	if entity.has_method("_get_combat_blood_loss_mult"):
		loss_mult = entity._get_combat_blood_loss_mult()
	# Active combat increases blood loss: movement prevents clotting, adrenaline
	# increases heart rate, wounds reopen with exertion (~50% faster bleeding)
	var exertion_active: bool = "exertion_active" in entity and entity.exertion_active
	if exertion_active:
		loss_mult *= 1.5
	# Decompensation (ATLS Class III→IV): nonlinear collapse — lost compensatory vasoconstriction
	# causes rebound vasodilation and microvascular leak. Accelerates both bleeding rate and blood
	# volume drain once below decompensation threshold.
	var blood_pct: float = 100.0
	if "blood_volume" in entity:
		blood_pct = clampf(float(entity.blood_volume), 0.0, 100.0)
	var decomp_time_modifier: float = 1.0
	if blood_pct < BleedingConstants.DECOMPENSATION_BLOOD_THRESHOLD:
		# Volume-based decomp acceleration (existing logic preserved).
		var decomp_factor: float = lerpf(1.0, 1.8, (BleedingConstants.DECOMPENSATION_BLOOD_THRESHOLD - blood_pct) / BleedingConstants.DECOMPENSATION_BLOOD_THRESHOLD)
		loss_mult *= decomp_factor
		# Severity-dependent compounding: check if any wound has been active long enough for
		# severity-based decompensation to kick in (models time-to-decomp progression).
		for part_wounds in entity.wounds.values():
			for injury in part_wounds:
				if injury.get("current_bleeding_rate", 0.0) > 0.1:
					var sev: String = injury.get(DataKeys.INJURY_SEVERITY, BleedingConstants.SEVERITY_MODERATE)
					var time_since_hit: float = entity._get_game_time_seconds() - injury.get("created_at_game_time", 99999.0)
					var decomp_time_s: float = BleedingConstants.get_decomp_time_for_severity(sev)
					if time_since_hit >= decomp_time_s:
						# Severity-based decomp active — additional acceleration on top of volume-based.
						decomp_time_modifier = maxf(decomp_time_modifier, BleedingConstants.get_decomp_modifier_since_hemorrhage(time_since_hit, sev))
	if entity.has_method("_get_combat_blood_recovery_per_s"):
		recovery_per_s = entity._get_combat_blood_recovery_per_s()
	# Decompensated patients have near-zero endogenous recovery (perfusion failure, metabolic collapse).
	if recovery_per_s > 0.0 and blood_pct < BleedingConstants.DECOMPENSATION_BLOOD_THRESHOLD:
		recovery_per_s *= 0.05  # ~95% suppression — only trace replacement while decompensated
	# Apply severity-dependent decompensation acceleration (wound-duration based compounding).
	loss_mult *= decomp_time_modifier
	if BloodVolumeMl.entity_uses_ml(entity):
		BloodVolumeMl.process_blood_loss_tick(entity, total, delta, loss_mult, recovery_per_s)
	elif total > 0.0:
		var loss: float = BleedingConstants.blood_volume_loss_per_second(total, loss_mult) * delta
		entity.blood_volume = maxf(0.0, entity.blood_volume - loss)
	if recovery_per_s > 0.0 and not BloodVolumeMl.entity_uses_ml(entity):
		entity.blood_volume = minf(BleedingConstants.MAX_BLOOD_VOLUME, entity.blood_volume + recovery_per_s * delta)
	if entity.has_method("_update_consciousness"):
		entity._update_consciousness()
	var threshold: float = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		threshold = entity._get_blood_loss_death_threshold()
	if entity.blood_volume <= threshold:
		emit_death_once(entity)


## One `died` emission per entity (map bleed ticks and vital-death paths).
static func emit_death_once(entity: Node) -> void:
	if entity == null:
		return
	# Ensure blood_volume reflects death state — prevents vitals logging showing 100% for entities that died
	# via vital-part destruction (which never drains blood_volume through the bleeding system).
	var death_thresh: float = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		death_thresh = float(entity._get_blood_loss_death_threshold())
	if "blood_volume" in entity and entity.blood_volume > death_thresh:
		entity.blood_volume = maxf(0.0, minf(entity.blood_volume, death_thresh))
	if entity.has_method("_notify_died"):
		entity._notify_died()
		return
	if entity.has_meta("_fp_death_notified") and bool(entity.get_meta("_fp_death_notified")):
		return
	entity.set_meta("_fp_death_notified", true)
	if entity.has_signal("died"):
		entity.died.emit()
