class_name EntityEquipment
extends RefCounted

## Armor and weapon logic for entities. Entity must have: armor_slots, weapon, dominant_hand, offhand_functionality.
## Uses BodyPartQuery and EntityPainConsciousness for arm functionality and pain modifiers.

const _BodyPartQuery := preload("res://core/BodyPartQuery.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _Bp := preload("res://core/BodyPartConstants.gd")

# --- Sub-region arm functional degradation (Issue 2: weapon function from arm wounds) ---
# When an arm is wounded, the specific sub-region damaged affects different combat functions.
# This module adds a damage-power multiplier that scales with tissue health on the attacking arm.

static func get_armor_for_part(entity: Node, part: String) -> Variant:
	if entity == null or not "armor_slots" in entity:
		return null
	var result = entity.armor_slots.get(part)
	if result == null:
		return null
	if result is ArmorPiece:
		return result
	return null

static func get_armor_sharp_resistance_for_part(entity: Node, part: String) -> float:
	var armor_var = get_armor_for_part(entity, part)
	if armor_var is ArmorPiece:
		return armor_var.get_outer_layer_sharp_resistance_rha_mm()
	return 0.0

static func get_armor_slots(entity: Node) -> Dictionary:
	if entity == null or not "armor_slots" in entity:
		return {}
	return entity.armor_slots.duplicate()

static func equip_armor(entity: Node, part: String, piece: Variant) -> void:
	if entity == null or part.is_empty():
		return
	if piece == null:
		entity.armor_slots.erase(part)
		return
	if not (piece is ArmorPiece):
		return
	if piece.body_part != part:
		return
	entity.armor_slots[part] = piece

static func get_weapon(entity: Node) -> Variant:
	if entity == null or not "weapon" in entity:
		return null
	return entity.weapon

static func equip_weapon(entity: Node, w: Variant) -> void:
	if entity != null and "weapon" in entity:
		entity.weapon = w

static func _get_offhand(entity: Node) -> String:
	if entity == null or not "dominant_hand" in entity:
		return _Bp.PART_LEFT_ARM
	return _Bp.PART_LEFT_ARM if entity.dominant_hand == _Bp.PART_RIGHT_ARM else _Bp.PART_RIGHT_ARM

static func get_attacking_arm(entity: Node) -> String:
	if entity == null:
		return ""
	var dominant_hand: String = entity.dominant_hand if "dominant_hand" in entity else _Bp.PART_RIGHT_ARM
	var offhand_functionality: float = entity.offhand_functionality if "offhand_functionality" in entity else 0.8
	var offhand: String = _get_offhand(entity)
	var dom_ok: bool = not _BodyPartQuery.is_arm_destroyed(entity, dominant_hand)
	var off_ok: bool = not _BodyPartQuery.is_arm_destroyed(entity, offhand)
	if not dom_ok and not off_ok:
		return ""
	if dom_ok and not off_ok:
		return dominant_hand
	if off_ok and not dom_ok:
		return offhand
	var dom_eff: float = _BodyPartQuery.get_arm_functionality(entity, dominant_hand) * 1.0
	var off_eff: float = _BodyPartQuery.get_arm_functionality(entity, offhand) * offhand_functionality
	return dominant_hand if dom_eff >= off_eff else offhand

static func get_attack_damage_modifier(entity: Node) -> float:
	var arm: String = get_attacking_arm(entity)
	if arm.is_empty():
		return 0.0
	var dominant_hand: String = entity.dominant_hand if "dominant_hand" in entity else _Bp.PART_RIGHT_ARM
	var offhand_functionality: float = entity.offhand_functionality if "offhand_functionality" in entity else 0.8
	var base: float = 1.0 if arm == dominant_hand else offhand_functionality
	var arm_func: float = _BodyPartQuery.get_arm_functionality(entity, arm)
	var arm_pain_mod: float = 1.0
	if entity.has_method("get_effective_pain_for_region"):
		arm_pain_mod = _PainConscious.get_pain_performance_modifier(entity.get_effective_pain_for_region("arms"))
	# Sub-region degradation: wounded arms lose swing power proportional to tissue damage,
	# with worst-case sub-region penalty (forearm/upper arm penalize power most).
	var arm_power_mod: float = _BodyPartQuery.get_arm_damage_power_modifier(entity, arm)
	return base * arm_func * arm_pain_mod * arm_power_mod
