class_name EntityWounds
extends RefCounted

## Wound list, bleeding rates, clotting, and wound creation for entities with wounds dict and game time.
## Entity must have: wounds, body_max, bone_max, _game_time_seconds, endurance, tourniquet_applied,
## direct_pressure_part, self_direct_pressure_part, direct_pressure_held_by, name.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _CombatLayerTissue := preload("res://core/CombatLayerTissue.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _Healing := preload("res://core/HealingConstants.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")

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

static func _severity_order() -> Array:
	return [
		_Bleeding.SEVERITY_MINOR,
		_Bleeding.SEVERITY_MODERATE,
		_Bleeding.SEVERITY_SEVERE,
		_Bleeding.SEVERITY_CRITICAL,
	]


static func _severity_from_abs_tissue(effective_damage: float) -> String:
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_CRITICAL:
		return _Bleeding.SEVERITY_CRITICAL
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_SEVERE:
		return _Bleeding.SEVERITY_SEVERE
	if effective_damage >= _Bleeding.SEVERITY_ABSOLUTE_MODERATE:
		return _Bleeding.SEVERITY_MODERATE
	return _Bleeding.SEVERITY_MINOR


static func _severity_from_abs_bone(bone_damage: float) -> String:
	if bone_damage >= _Bleeding.SEVERITY_ABSOLUTE_BONE_CRITICAL:
		return _Bleeding.SEVERITY_CRITICAL
	if bone_damage >= _Bleeding.SEVERITY_ABSOLUTE_BONE_SEVERE:
		return _Bleeding.SEVERITY_SEVERE
	if bone_damage >= _Bleeding.SEVERITY_ABSOLUTE_BONE_MODERATE:
		return _Bleeding.SEVERITY_MODERATE
	return _Bleeding.SEVERITY_MINOR


static func _compose_severity_abs_and_pct(sev_abs: String, sev_pct: String) -> String:
	var order: Array = _severity_order()
	if _Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP:
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
	var max_hp: float = float(entity.body_max.get(part, 10))
	if max_hp <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	var ke_mult: float = 1.0
	if impact_ke_j >= 0.0:
		ke_mult = 1.0 + _SEVERITY_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
	var depth_mult: float = _Bleeding.penetration_depth_severity_mult(penetration_to_tissue_mm)
	var sub_mult: float = 1.0
	if not _CombatConstants.is_feature_subregion_combat_mult_enabled():
		sub_mult = _Bleeding.get_severity_modifier(part, sub_region)
	var effective_damage: float = damage * ke_mult * depth_mult * sub_mult
	var pct: float = effective_damage / max_hp
	var sev_pct: String = _severity_from_pct(pct)
	if _Bleeding.FEATURE_ABSOLUTE_SEVERITY_BANDS:
		return _compose_severity_abs_and_pct(_severity_from_abs_tissue(effective_damage), sev_pct)
	return sev_pct


static func severity_from_bone_damage(entity: Node, part: String, bone_damage: float) -> String:
	if bone_damage <= 0.0:
		return _Bleeding.SEVERITY_MINOR
	var max_bone: float = float(entity.bone_max.get(part, 1))
	if max_bone <= 0.0:
		return _Bleeding.SEVERITY_MODERATE
	if _Bleeding.FEATURE_ABSOLUTE_SEVERITY_BANDS:
		var sev_abs: String = _severity_from_abs_bone(bone_damage)
		if _Bleeding.FEATURE_ABSOLUTE_SEVERITY_PCT_CAP:
			var sev_pct: String = _severity_from_pct(bone_damage / max_bone)
			return _compose_severity_abs_and_pct(sev_abs, sev_pct)
		return sev_abs
	return _severity_from_pct(bone_damage / max_bone)


static func _severity_rank(sev: String) -> int:
	var order: Array = [
		_Bleeding.SEVERITY_MINOR,
		_Bleeding.SEVERITY_MODERATE,
		_Bleeding.SEVERITY_SEVERE,
		_Bleeding.SEVERITY_CRITICAL,
	]
	var idx: int = order.find(sev)
	return idx if idx >= 0 else 1


## Same part + sub_region during one fight → one wound channel worsens (not N separate pack procedures).
static func _try_merge_wound_into_channel(
	entity: Node,
	part: String,
	injury_type: String,
	damage: float,
	sub_region: String,
	severity: String,
	base_rate: float,
	is_arterial: bool,
	healing_duration: float
) -> bool:
	if not entity.wounds.has(part):
		return false
	var sr_key: String = sub_region if not sub_region.is_empty() else ""
	for injury in entity.wounds[part]:
		if str(injury.get("sub_region", "")) != sr_key:
			continue
		var existing_type: String = str(injury.get("injury_type", ""))
		if existing_type != injury_type and base_rate > 0.0:
			if existing_type not in [_Bleeding.INJURY_TYPE_CUT, _Bleeding.INJURY_TYPE_CRUSH]:
				continue
			if injury_type not in [_Bleeding.INJURY_TYPE_CUT, _Bleeding.INJURY_TYPE_CRUSH]:
				continue
		injury["damage"] = float(injury.get("damage", 0.0)) + damage
		if _severity_rank(severity) > _severity_rank(str(injury.get("severity", _Bleeding.SEVERITY_MODERATE))):
			injury["severity"] = severity
		if is_arterial:
			injury["is_arterial"] = true
		if base_rate > 0.0:
			var prev_base: float = float(injury.get("base_bleeding_rate", 0.0))
			var prev_cur: float = float(injury.get("current_bleeding_rate", 0.0))
			injury["base_bleeding_rate"] = prev_base + base_rate
			injury["current_bleeding_rate"] = prev_cur + base_rate
			injury["is_stabilized"] = false
			injury.erase("stabilized_remaining_seconds")
		injury["healing_duration_seconds"] = maxf(
			float(injury.get("healing_duration_seconds", 0.0)), healing_duration
		)
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
	penetration_to_tissue_mm: float = -1.0
) -> void:
	if part.is_empty() or damage <= 0.0:
		return
	var severity: String = (
		severity_override
		if not severity_override.is_empty()
		else severity_from_damage(entity, part, damage, sub_region, impact_ke_j, penetration_to_tissue_mm)
	)
	if injury_type == _Bleeding.INJURY_TYPE_CRUSH and severity == _Bleeding.SEVERITY_MINOR:
		injury_type = _Bleeding.INJURY_TYPE_BRUISE
	var base_rate: float = _Bleeding.get_bleeding_rate(injury_type, severity, part, sub_region)
	if base_rate < 0.0:
		base_rate = 0.0
	if base_rate > 0.0 and injury_type == _Bleeding.INJURY_TYPE_CUT:
		if impact_ke_j >= 0.0:
			base_rate *= 1.0 + _BLEED_KE_BLEND * minf(impact_ke_j / maxf(1.0, _IMPACT_KE_REF_J), 2.0)
		base_rate *= _Bleeding.penetration_depth_severity_mult(penetration_to_tissue_mm)
		base_rate *= _CombatLayerTissue.layer_rupture_bleed_mult(entity, part)
	if base_rate > 0.0:
		base_rate *= randf_range(_Bleeding.BLEEDING_RATE_VARIANCE_MIN, _Bleeding.BLEEDING_RATE_VARIANCE_MAX)
	var pen_for_arterial: float = penetration_to_tissue_mm if injury_type == _Bleeding.INJURY_TYPE_CUT else -1.0
	var is_arterial: bool = (
		randf() < _Bleeding.get_arterial_chance(severity, injury_type, part, sub_region, pen_for_arterial)
		if base_rate > 0.0
		else false
	)
	if base_rate > 0.0 and is_arterial:
		base_rate *= _Bleeding.ARTERIAL_BLEEDING_MULTIPLIER
	if entity.wounds.get(part) == null:
		entity.wounds[part] = []
	var healing_duration: float = _Healing.get_wound_healing_duration_seconds(part, severity, injury_type)
	if _try_merge_wound_into_channel(
		entity, part, injury_type, damage, sub_region, severity, base_rate, is_arterial, healing_duration
	):
		return
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

## When sub_region is empty, uses RNG stump site (not combat hit path — use resolved hit_sub_region from EntityDamage).
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

static func part_has_active_direct_pressure(entity: Node, part: String) -> bool:
	if part.is_empty():
		return false
	return part == entity.direct_pressure_part or part == entity.self_direct_pressure_part


static func part_has_definitive_hemostasis(entity: Node, part: String) -> bool:
	if part.is_empty():
		return false
	if bool(entity.bandaged_parts.get(part, false)) or bool(entity.packed_parts.get(part, false)):
		return true
	return entity.tourniquet_applied.has(part)


static func get_bleeding_rate_for_part(entity: Node, part: String) -> float:
	if not entity.wounds.has(part):
		return 0.0
	var rate: float = 0.0
	var under_pressure: bool = part_has_active_direct_pressure(entity, part)
	for injury in entity.wounds[part]:
		var r: float = float(injury.get("current_bleeding_rate", 0.0))
		if under_pressure:
			r *= _Bleeding.direct_pressure_held_flow_retained(bool(injury.get("is_arterial", false)))
		rate += r
	if not entity.tourniquet_applied.has(part):
		return rate
	_EntityMedical.ensure_tourniquet_dict_entry(entity, part)
	var data: Dictionary = entity.tourniquet_applied[part]
	var eff: float = float(data.get("effectiveness", 1.0))
	var reduction: float = eff * _Bleeding.TOURNIQUET_REDUCTION_AT_FULL
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
		if bool(injury.get("is_arterial", false)):
			bonus += 2.25
		if bool(injury.get("is_stump", false)):
			bonus += 4.5
		var sev: String = str(injury.get("severity", _Bleeding.SEVERITY_MODERATE))
		if sev == _Bleeding.SEVERITY_CRITICAL:
			bonus += 1.6
		elif sev == _Bleeding.SEVERITY_SEVERE:
			bonus += 0.85
	if _EntityMedical.is_tourniquet_indicated_for_part(entity, part):
		bonus += 1.15
	return rate * 3.5 + bonus


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
	parts.sort_custom(func(a, b) -> bool:
		return get_part_intervention_threat(entity, str(a)) > get_part_intervention_threat(entity, str(b))
	)
	return parts


static func get_wounds(entity: Node) -> Dictionary:
	return entity.wounds.duplicate(true)

# --- Process bleeding (clotting, direct-pressure auto-clear) ---

## Do not release pressure while blood volume is still at/below bleed-out threshold (rate may be ~0).
static func _blood_volume_safe_to_release_pressure(entity: Node) -> bool:
	if entity == null:
		return false
	var threshold: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		threshold = float(entity._get_blood_loss_death_threshold())
	return float(entity.blood_volume) > threshold


## Safe to stop holding: dressed/packed/tourniqueted only — do not release on local clot alone (TCCC: keep compression until dressed).
static func _hemostasis_allows_pressure_release(entity: Node, part: String) -> bool:
	if part_has_definitive_hemostasis(entity, part):
		return true
	if not _blood_volume_safe_to_release_pressure(entity):
		return false
	return false


static func _pressure_release_reason(entity: Node, part: String) -> String:
	if part_has_definitive_hemostasis(entity, part):
		if bool(entity.bandaged_parts.get(part, false)):
			return "bandaged"
		if bool(entity.packed_parts.get(part, false)):
			return "packed"
		if entity.tourniquet_applied.has(part):
			return "tourniquet"
		return "dressed"
	if not _blood_volume_safe_to_release_pressure(entity):
		return "blood_volume_at_threshold"
	return "bleeding_stopped"


## Early release without dressing: partial rebleed (TCCC: do not let go until controlled).
static func rebound_bleeding_after_pressure_release(entity: Node, part: String) -> void:
	if part.is_empty() or not entity.wounds.has(part):
		return
	if part_has_definitive_hemostasis(entity, part):
		return
	var before: float = get_bleeding_rate_for_part(entity, part)
	for injury in entity.wounds[part]:
		var rate: float = float(injury.get("current_bleeding_rate", 0.0))
		var base: float = float(injury.get("base_bleeding_rate", rate))
		var target: float = maxf(rate, base * _Bleeding.DIRECT_PRESSURE_REBOUND_TO_INTRINSIC_MULT)
		injury["current_bleeding_rate"] = target
		injury["is_stabilized"] = false
		injury.erase("stabilized_remaining_seconds")
	var after: float = get_bleeding_rate_for_part(entity, part)
	_EntityMedical.log_medical_session(
		"%s pressure_rebound part=%s bleed %.3f→%.3f (released without dressing)"
		% [entity.name, part, before, after]
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
				clotting = _Bleeding.CLOTTING_RATE_STABILIZED
				if under_pressure:
					clotting = maxf(clotting, _Bleeding.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
			else:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MODERATE)
				clotting = _Bleeding.get_clotting_rate(sev) * _Bleeding.get_clotting_multiplier(sev)
				if injury.get("is_arterial", false):
					clotting *= _Bleeding.ARTERIAL_CLOTTING_MULTIPLIER
				if under_pressure:
					clotting = maxf(clotting, _Bleeding.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
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
	if (
		not entity.direct_pressure_part.is_empty()
		and _hemostasis_allows_pressure_release(entity, entity.direct_pressure_part)
	):
		var ally_part: String = entity.direct_pressure_part
		var reason_ally: String = _pressure_release_reason(entity, ally_part)
		_EntityMedical.log_medical_session(
			"%s direct_pressure auto-cleared part=%s (ally-held) reason=%s bv=%.1f"
			% [entity.name, ally_part, reason_ally, float(entity.blood_volume)]
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
		_EntityMedical.log_medical_session(
			"%s direct_pressure auto-cleared part=%s (self-held) reason=%s bv=%.1f"
			% [entity.name, self_part, reason_self, float(entity.blood_volume)]
		)
		entity.self_direct_pressure_part = ""

# --- Process blood loss (drain from bleeding rate; death at threshold) ---
## Entity must have: blood_volume, _update_consciousness (optional), emit_signal("died"), _get_blood_loss_death_threshold (optional).
static func process_blood_loss(entity: Node, delta: float) -> void:
	if entity != null and entity.has_method("is_dead") and entity.is_dead():
		return
	var total: float = get_total_bleeding_rate(entity)
	var loss_mult: float = 1.0
	var recovery_per_s: float = 0.0
	if entity.has_method("get_combat_blood_loss_mult"):
		loss_mult = entity.get_combat_blood_loss_mult()
	if entity.has_method("get_combat_blood_recovery_per_s"):
		recovery_per_s = entity.get_combat_blood_recovery_per_s()
	if _BloodVolumeMl.entity_uses_ml(entity):
		_BloodVolumeMl.process_blood_loss_tick(entity, total, delta, loss_mult, recovery_per_s)
		if total <= 0.0 and recovery_per_s <= 0.0:
			return
	elif total > 0.0:
		var loss: float = _Bleeding.blood_volume_loss_per_second(total, loss_mult) * delta
		entity.blood_volume = maxf(0.0, entity.blood_volume - loss)
	elif recovery_per_s > 0.0:
		entity.blood_volume = minf(
			_Bleeding.MAX_BLOOD_VOLUME,
			entity.blood_volume + recovery_per_s * delta
		)
	else:
		return
	if entity.has_method("_update_consciousness"):
		entity._update_consciousness()
	var threshold: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	if entity.has_method("_get_blood_loss_death_threshold"):
		threshold = entity._get_blood_loss_death_threshold()
	if entity.blood_volume <= threshold:
		emit_death_once(entity)


## One `died` emission per entity (map bleed ticks and vital-death paths).
static func emit_death_once(entity: Node) -> void:
	if entity == null:
		return
	if entity.has_method("notify_died"):
		entity.notify_died()
		return
	if entity.has_meta("_fp_death_notified") and bool(entity.get_meta("_fp_death_notified")):
		return
	entity.set_meta("_fp_death_notified", true)
	if entity.has_signal("died"):
		entity.emit_signal("died")
