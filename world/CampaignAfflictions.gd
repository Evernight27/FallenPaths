class_name CampaignAfflictions
extends RefCounted

## Post-victory permanent injuries (Camp-2.4) — tier RNG from user bundle.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")

const AFFLICTION_SLOWED_CIRCULATION := "slowed_circulation"
const AFFLICTION_OLD_WOUND_ACHE := "old_wound_ache"
const AFFLICTION_LIMPING_LIMB := "limping_limb"

const P_PERIL := 0.30
const P_DANGER := 0.12
const P_BONE_CRIPPLE := 0.45
const P_ARTERIAL_FAIL := 0.55
const P_STRUCK_DOWN := 0.33
const P_CAP := 0.55


static func apply_after_victory(world: Node2D, rng: RandomNumberGenerator) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if not _CompanyState.gate_afflictions_enabled():
		return lines
	if world == null or rng == null:
		return lines
	for n in _CampaignBridge.get_fightable_party_nodes(world):
		var entity: Node = _CampaignBridge.health_entity_from_character(n)
		if entity == null:
			continue
		var roll: Dictionary = _roll_affliction_for_entity(entity, n, rng)
		if roll.is_empty():
			continue
		if not entity.has_method("add_campaign_affliction"):
			continue
		if entity.add_campaign_affliction(roll):
			var name_s: String = str(n.name)
			lines.append("%s — %s" % [name_s, str(roll.get("label", roll.get("id", "")))])
			_CompanyState.adjust_member_mood(world, name_s, -1.35)
	return lines


static func _roll_affliction_for_entity(entity: Node, character: Node, rng: RandomNumberGenerator) -> Dictionary:
	var blood: float = 100.0
	if "blood_volume" in entity:
		blood = float(entity.blood_volume)
	var p: float = 0.0
	var pick: String = AFFLICTION_SLOWED_CIRCULATION
	if character.has_method("is_unconscious") and character.is_unconscious():
		p = maxf(p, P_STRUCK_DOWN)
		pick = AFFLICTION_SLOWED_CIRCULATION
	if blood < _Bleeding.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING:
		p = maxf(p, P_PERIL)
		pick = AFFLICTION_SLOWED_CIRCULATION
	elif blood < _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING:
		p = maxf(p, P_DANGER)
		pick = AFFLICTION_OLD_WOUND_ACHE
	if _count_untreated_arterial(entity) >= 2:
		p = maxf(p, P_ARTERIAL_FAIL)
		pick = AFFLICTION_SLOWED_CIRCULATION
	var bone_part: String = _worst_bone_part(entity)
	if not bone_part.is_empty():
		p = maxf(p, P_BONE_CRIPPLE)
		pick = AFFLICTION_LIMPING_LIMB
	p = minf(p, P_CAP)
	if p <= 0.0 or rng.randf() >= p:
		return {}
	return _affliction_def(pick, bone_part)


static func _affliction_def(id: String, bone_part: String) -> Dictionary:
	match id:
		AFFLICTION_OLD_WOUND_ACHE:
			return {
				"id": id,
				"label": "Old wound ache",
				"stamina_mult": 1.0,
				"pain_mult": 1.08,
			}
		AFFLICTION_LIMPING_LIMB:
			return {
				"id": id,
				"label": "Limping %s" % bone_part,
				"stamina_mult": 0.92,
				"pain_mult": 1.0,
				"part": bone_part,
			}
		_:
			return {
				"id": AFFLICTION_SLOWED_CIRCULATION,
				"label": "Slowed circulation",
				"stamina_mult": 0.90,
				"pain_mult": 1.0,
			}


static func _count_untreated_arterial(entity: Node) -> int:
	var n := 0
	if not entity.wounds is Dictionary:
		return 0
	var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
	var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
	var tq: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
	for part in entity.wounds.keys():
		if bandaged.get(part, false) or packed.get(part, false) or tq.has(part):
			continue
		for injury in entity.wounds[part]:
			if injury is Dictionary and injury.get("is_arterial", false):
				n += 1
	return n


static func _worst_bone_part(entity: Node) -> String:
	var worst: String = ""
	var worst_ratio: float = 1.0
	if entity.get("bone_health") == null or entity.get("bone_max") == null:
		return ""
	for part in entity.bone_health.keys():
		var mx: float = float(entity.bone_max.get(part, 0))
		if mx <= 0.0:
			continue
		var ratio: float = float(entity.bone_health.get(part, 0.0)) / mx
		if ratio <= 0.25 and ratio < worst_ratio:
			worst_ratio = ratio
			worst = str(part)
	return worst
