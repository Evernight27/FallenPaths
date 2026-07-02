class_name EntityHealing
extends RefCounted

## Time-advance healing: game time, wound resolution, bandage/tourniquet expiry, tissue/bone/blood recovery.
## Entity must have: _game_time_seconds, wounds, bandaged_parts, packed_parts, tourniquet_applied,
## body_cutting, body_blunt, bone_health, body_max, bone_max, blood_volume; methods _get_body_part_list,
## _is_part_severed, _round_tissue, get_total_bleeding_rate; and EntityWounds.get_wound_healing_progress,
## EntityPainConsciousness.update_consciousness.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _BloodVolumeMl := preload("res://core/BloodVolumeMl.gd")
const _Healing := preload("res://core/HealingConstants.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _EntityPainConsciousness := preload("res://core/EntityPainConsciousness.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")

# --- Main entry: advance game time and run all healing logic ---

static func process_healing(entity: Node, seconds: float) -> void:
	if seconds <= 0.0:
		return
	entity._game_time_seconds += seconds

	# Remove resolved wounds (healing progress >= threshold); pain has effectively resolved
	for part in entity.wounds.keys():
		var list: Array = entity.wounds[part]
		var i: int = list.size() - 1
		while i >= 0:
			if _EntityWounds.get_wound_healing_progress(entity, list[i]) >= _Healing.WOUND_RESOLVED_THRESHOLD:
				list.remove_at(i)
			i -= 1
		if list.is_empty():
			entity.wounds.erase(part)
			entity.bandaged_parts.erase(part)
			entity.packed_parts.erase(part)

	# Bandage stabilization expiry: subtract time from stabilized_remaining_seconds; clear is_stabilized when expired.
	if _Bleeding.BANDAGE_STABILIZATION_DURATION > 0.0:
		for part in entity.wounds.keys():
			for injury in entity.wounds[part]:
				if injury.get("stabilized_remaining_seconds", 0.0) > 0.0:
					var rem: float = injury["stabilized_remaining_seconds"] - seconds
					injury["stabilized_remaining_seconds"] = maxf(0.0, rem)
					if rem <= 0.0:
						injury["is_stabilized"] = false
						injury.erase("stabilized_remaining_seconds")
	# Tourniquet expiry: if max duration > 0, release TQ after duration (limb ischemia risk). Bleeding can resume.
	if _Bleeding.TOURNIQUET_MAX_DURATION_SECONDS > 0.0:
		for part in entity.tourniquet_applied.keys():
			_EntityMedical.ensure_tourniquet_dict_entry(entity, part)
			var data: Dictionary = entity.tourniquet_applied[part]
			var applied_at: float = data.get("applied_at", 0.0)
			if entity._game_time_seconds - applied_at >= _Bleeding.TOURNIQUET_MAX_DURATION_SECONDS:
				entity.tourniquet_applied.erase(part)

	for part in entity._get_body_part_list():
		if part not in entity.body_max or part not in entity.bone_max:
			continue
		if entity._is_part_severed(part):
			continue  # severed part is gone; no healing. Crushed/mangled (still attached) can heal (limb salvage).
		var max_tissue: int = entity.body_max.get(part, 0)
		var max_bone: int = entity.bone_max.get(part, 0)
		if max_tissue <= 0:
			continue
		# Worst wound severity on this part sets tissue heal duration (medical realism)
		var severity: String = _Bleeding.SEVERITY_MINOR
		if entity.wounds.has(part) and entity.wounds[part].size() > 0:
			var order: Array = [_Bleeding.SEVERITY_MINOR, _Bleeding.SEVERITY_MODERATE, _Bleeding.SEVERITY_SEVERE, _Bleeding.SEVERITY_CRITICAL]
			for injury in entity.wounds[part]:
				var sev: String = injury.get("severity", _Bleeding.SEVERITY_MINOR)
				if order.find(sev) > order.find(severity):
					severity = sev
		var tissue_duration: float = _Healing.get_tissue_heal_duration_seconds(part, severity)
		if tissue_duration <= 0.0:
			tissue_duration = _Healing.SECONDS_PER_DAY * 4.0
		# Tissue: exponential healing (deficit *= exp(-t/tau)); rate ~ current deficit. See RESEARCH_BASED_APPROXIMATIONS.md.
		var cur_cut: float = entity.body_cutting.get(part, 0.0)
		var cur_blunt: float = entity.body_blunt.get(part, 0.0)
		var remain_cut: float = float(max_tissue) - cur_cut
		var remain_blunt: float = float(max_tissue) - cur_blunt
		var heal_speed: float = 1.0
		if entity.has_method("get_endurance_healing_speed_mult"):
			heal_speed = entity.get_endurance_healing_speed_mult()
		var tau_tissue: float = tissue_duration / (_Healing.EXPONENTIAL_HEAL_TAU_DIVISOR * heal_speed)
		var add_cut: float = remain_cut * (1.0 - exp(-seconds / tau_tissue))
		var add_blunt: float = remain_blunt * (1.0 - exp(-seconds / tau_tissue))
		entity.body_cutting[part] = entity._round_tissue(minf(float(max_tissue), cur_cut + add_cut))
		entity.body_blunt[part] = entity._round_tissue(minf(float(max_tissue), cur_blunt + add_blunt))
		# Bone: exponential healing toward max (6 weeks duration)
		var bone_duration: float = _Healing.get_bone_heal_duration_seconds(part)
		if bone_duration <= 0.0:
			bone_duration = _Healing.BONE_HEAL_DURATION_SECONDS
		var cur_bone: float = entity.bone_health.get(part, 0.0)
		var remain_bone: float = float(max_bone) - cur_bone
		var tau_bone: float = bone_duration / (_Healing.EXPONENTIAL_HEAL_TAU_DIVISOR * heal_speed)
		var bone_heal: float = remain_bone * (1.0 - exp(-seconds / tau_bone))
		entity.bone_health[part] = entity._round_tissue(minf(float(max_bone), cur_bone + bone_heal))

	# Blood volume recovery when not bleeding: exponential (deficit ~ current deficit). Body replenishes over ~24 h.
	if entity.get_total_bleeding_rate() <= 0.0:
		var remain_blood: float = _Bleeding.MAX_BLOOD_VOLUME - entity.blood_volume
		if remain_blood > 0.0:
			var tau_blood: float = _Healing.BLOOD_VOLUME_RECOVERY_DURATION_SECONDS / _Healing.EXPONENTIAL_HEAL_TAU_DIVISOR
			var add_blood: float = remain_blood * (1.0 - exp(-seconds / tau_blood))
			entity.blood_volume = minf(_Bleeding.MAX_BLOOD_VOLUME, entity.blood_volume + add_blood)
			if _BloodVolumeMl.entity_uses_ml(entity):
				_BloodVolumeMl.sync_ml_from_percent(entity)
	# Pain and consciousness depend on wounds, head, and blood; refresh after all healing/time advance.
	_EntityPainConsciousness.update_consciousness(entity)
