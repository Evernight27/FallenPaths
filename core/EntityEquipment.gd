class_name EntityEquipment
extends RefCounted

## Armor and weapon logic for entities. Entity must have: armor_slots, weapon, dominant_hand, offhand_functionality.
## Uses BodyPartQuery and EntityPainConsciousness for arm functionality and pain modifiers.

## Two-handed weapon handling floor: when the supporting (offhand) arm is destroyed, a two-handed
## weapon is wielded one-handed and attack power drops to this fraction. Lerp from this floor to 1.0
## as the offhand arm's functionality recovers. A spear/polearm one-armed is ~40% as effective.
const TWO_HAND_ONE_ARM_FLOOR: float = 0.4


static func _get_armor_for_part(entity: Node, part: String) -> Variant:
    if entity == null or not "armor_slots" in entity:
        return null
    var result = entity.armor_slots.get(part)
    if result == null:
        return null
    if result is ArmorPiece:
        return result
    return null


static func _get_armor_sharp_resistance_for_part(entity: Node, part: String) -> float:
    var armor_var = _get_armor_for_part(entity, part)
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
        return BodyPartConstants.PART_LEFT_ARM
    return (
        BodyPartConstants.PART_LEFT_ARM
        if entity.dominant_hand == BodyPartConstants.PART_RIGHT_ARM
        else BodyPartConstants.PART_RIGHT_ARM
    )


static func get_attacking_arm(entity: Node) -> String:
    if entity == null:
        return ""
    var dominant_hand: String = entity.dominant_hand if "dominant_hand" in entity else BodyPartConstants.PART_RIGHT_ARM
    var offhand_functionality: float = entity.offhand_functionality if "offhand_functionality" in entity else 0.8
    var offhand: String = _get_offhand(entity)
    var dom_ok: bool = not BodyPartQuery.is_arm_destroyed(entity, dominant_hand)
    var off_ok: bool = not BodyPartQuery.is_arm_destroyed(entity, offhand)
    if not dom_ok and not off_ok:
        return ""
    if dom_ok and not off_ok:
        return dominant_hand
    if off_ok and not dom_ok:
        return offhand
    var dom_eff: float = BodyPartQuery.get_arm_functionality(entity, dominant_hand) * 1.0
    var off_eff: float = BodyPartQuery.get_arm_functionality(entity, offhand) * offhand_functionality
    return dominant_hand if dom_eff >= off_eff else offhand


static func _get_attack_base_modifier(entity: Node, arm: String) -> float:
    var dominant_hand: String = entity.dominant_hand if "dominant_hand" in entity else BodyPartConstants.PART_RIGHT_ARM
    var offhand_functionality: float = entity.offhand_functionality if "offhand_functionality" in entity else 0.8
    return 1.0 if arm == dominant_hand else offhand_functionality


static func get_attack_damage_modifier(entity: Node) -> float:
    return attack_damage_modifier_factors(entity).get("total", 0.0)


## Breakdown of the attack damage modifier into its multiplicative factors so a low KE strike is
## explainable at a glance (tuning log `ke_low_by=arm`). Returns factor name -> value for each factor
## that deviates from 1.0, plus "total" = their product and "arm" = the attacking limb. Empty arm maps to total 0.0.
static func attack_damage_modifier_factors(entity: Node) -> Dictionary:
    var out: Dictionary = {}
    var arm: String = get_attacking_arm(entity)
    if arm.is_empty():
        out["total"] = 0.0
        out["arm"] = ""
        return out
    var base: float = _get_attack_base_modifier(entity, arm)
    var arm_func: float = BodyPartQuery.get_arm_functionality(entity, arm)
    var arm_pain_mod: float = 1.0
    if entity.has_method("_get_effective_pain_for_region"):
        arm_pain_mod = PainConsciousnessConstants.get_pain_performance_modifier(
            entity._get_effective_pain_for_region("arms")
        )
    var grip_mult: float = BodyPartQuery.get_arm_wound_function_mult(entity, arm)
    var two_hand_mult: float = _get_two_hand_handling_mult(entity)
    out["arm"] = arm
    if absf(base - 1.0) > 0.001:
        out["base"] = base
    if absf(arm_func - 1.0) > 0.001:
        out["func"] = arm_func
    if absf(arm_pain_mod - 1.0) > 0.001:
        out["pain"] = arm_pain_mod
    if absf(grip_mult - 1.0) > 0.001:
        out["grip"] = grip_mult
    if absf(two_hand_mult - 1.0) > 0.001:
        out["two_hand"] = two_hand_mult
    out["total"] = base * arm_func * arm_pain_mod * grip_mult * two_hand_mult
    return out


## Two-handed weapon handling factor: 1.0 unless the entity wields a two-handed weapon AND the
## supporting (offhand) arm is impaired/destroyed. A two-handed weapon needs both arms; a compromised
## supporting arm means one-handed handling, so power drops toward `TWO_HAND_ONE_ARM_FLOOR`. The
## offhand arm is used (not the attacking arm) because the attacking arm's impairment is already
## captured by `arm_func` / `base` — this term is the non-overlapping two-handed sensitivity.
static func _get_two_hand_handling_mult(entity: Node) -> float:
    var weapon: Variant = get_weapon(entity)
    if not WeaponConstants.weapon_is_two_handed(weapon):
        return 1.0
    var offhand: String = _get_offhand(entity)
    var offhand_func: float = BodyPartQuery.get_arm_functionality(entity, offhand)
    return lerpf(TWO_HAND_ONE_ARM_FLOOR, 1.0, offhand_func)
