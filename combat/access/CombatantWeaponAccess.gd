class_name CombatantWeaponAccess
extends CombatantCombatStateAccess

## Weapon and armor accessors for combatant nodes.


static func weapon_attack_types(weapon: Variant) -> Array:
    if weapon == null or not weapon.has_method("get_available_attack_types"):
        return []
    return weapon.get_available_attack_types()


static func weapon_has_attack_types(weapon: Variant) -> bool:
    return weapon != null and weapon.has_method("get_available_attack_types")


static func weapon_contact_type(weapon: Variant, move_id: String, default_contact: String = "cut") -> String:
    if weapon == null or not weapon.has_method("get_contact_type"):
        return default_contact
    return str(weapon.get_contact_type(move_id))


## Delegates to **`WeaponConstants.weapon_mass_kg`** (combat call sites).


## Delegates to **`WeaponConstants.weapon_mass_kg`** (combat call sites).
static func weapon_mass_kg(weapon: Variant) -> float:
    return WeaponConstants.weapon_mass_kg(weapon)


static func parry_wobble_context(defender_weapon: Variant, parry_readiness: float) -> Dictionary:
    return {"parry_readiness": parry_readiness, "defender_mass_kg": weapon_mass_kg(defender_weapon)}


static func parry_wobble_context_for_combatant(combatant: Dictionary, parry_readiness: float) -> Dictionary:
    return parry_wobble_context(get_weapon(combatant), parry_readiness)


static func weapon_archetype_id(weapon: Variant, move_id: String, default_id: String = "slash") -> String:
    if weapon == null or not weapon.has_method("get_archetype_id"):
        return default_id
    return str(weapon.get_archetype_id(move_id))


static func weapon_archetype_for_move(
    weapon: Variant, move_id: String, default_archetype_id: String = WeaponConstants.ARCHETYPE_SLASH
) -> Dictionary:
    return WeaponConstants.get_archetype(weapon_archetype_id(weapon, move_id, default_archetype_id))


static func weapon_has_parts(weapon: Variant) -> bool:
    return weapon != null and weapon.has_method("has_parts") and weapon.has_parts()


static func weapon_parry_strong_fraction(weapon: Variant, default_frac: float = 0.25) -> float:
    if weapon == null or not weapon.has_method("get_parry_strong_fraction"):
        return default_frac
    return weapon.get_parry_strong_fraction()


static func weapon_parry_part_length_cm(weapon: Variant, default_len: float = 0.0) -> float:
    if weapon == null or not weapon.has_method("get_parry_part_length_cm"):
        return default_len
    return weapon.get_parry_part_length_cm()


## Striking-segment mass for parry/block; falls back to total weapon mass or baseline.


## Striking-segment mass for parry/block; falls back to total weapon mass or baseline.
static func weapon_striking_mass_kg(weapon: Variant, contact_type: String = "") -> float:
    if weapon_has_parts(weapon):
        return weapon.get_striking_part_mass_kg(contact_type)
    return weapon_mass_kg(weapon)


static func weapon_parry_part_mass_kg(weapon: Variant) -> float:
    if weapon_has_parts(weapon) and weapon.has_method("get_parry_part_mass_kg"):
        return weapon.get_parry_part_mass_kg()
    return weapon_mass_kg(weapon)


static func weapon_parry_contact_type(weapon: Variant, default_pct: String = "blade") -> String:
    if weapon == null or not weapon.has_method("get_parry_contact_type"):
        return default_pct
    return str(weapon.get_parry_contact_type())


## Cut vs blunt band for parry-speed reference (shaft/haft →f→s'f→s' -> blunt).


## Cut vs blunt band for parry-speed reference (shaft/haft →f→s'f→s' -> blunt).
static func weapon_parry_ref_contact_type(weapon: Variant) -> String:
    var pct: String = weapon_parry_contact_type(weapon)
    if pct == "shaft" or pct == "haft":
        return WeaponConstants.ATTACK_TYPE_BLUNT
    return WeaponConstants.ATTACK_TYPE_CUT


static func weapon_impact_velocity_band_max(weapon: Variant, contact_type: String) -> float:
    if weapon != null and weapon.has_method("get_impact_velocity_band_m_s"):
        return weapon.get_impact_velocity_band_m_s(contact_type).y
    return _get_impact_velocity_model().unarmed_velocity_band_m_s().y


## Wound part list for medical UI. With **`manager`**, uses **`get_health_entity`** (same as
## **`entity_get_wounded_parts`**).


## Wound part list for medical UI. With **`manager`**, uses **`get_health_entity`** (same as
## **`entity_get_wounded_parts`**).
static func get_weapon(combatant: Dictionary) -> Variant:
    var node = node_variant(combatant)
    if node == null or not node.has_method("get_weapon"):
        return null
    return node.get_weapon()


## Canonical weapon template id (SWORD, AXE, …) from equipped Weapon instance.


## Canonical weapon template id (SWORD, AXE, …) from equipped Weapon instance.
static func weapon_type_id(combatant: Dictionary) -> String:
    var weapon: Variant = get_weapon(combatant)
    if weapon == null:
        return ""
    if "weapon_type" in weapon:
        return str(weapon.weapon_type).to_upper().strip_edges()
    return ""


## CoreEntity from combatant dict when present.


## CoreEntity from combatant dict when present.
static func weapon_melee_reach(combatant: Dictionary, default_reach: float = 1.5) -> float:
    var weapon: Variant = get_weapon(combatant)
    if weapon == null:
        return default_reach
    var reach: float = float(weapon.melee_range)
    # Body-size scaling: a smaller wielder has shorter arms, so shorter effective reach (see SpeciesResource).
    var node: Variant = node_variant(combatant)
    if node is Node and "species" in node:
        var species: Variant = (node as Node).species
        if species != null and species.has_method("body_reach_scale"):
            reach *= float(species.body_reach_scale())
    return reach


## Living ally on **`actor`**'s side (alive, same side).


## Living ally on **`actor`**'s side (alive, same side).
static func has_weapon(combatant: Dictionary) -> bool:
    return get_weapon(combatant) != null


## Returns weapon from node directly. Use when caller has node (not combatant dict).


## Returns weapon from node directly. Use when caller has node (not combatant dict).
static func get_weapon_from_node(node: Node) -> Variant:
    if node == null or not node.has_method("get_weapon"):
        return null
    return node.get_weapon()


## Returns armor slots from node. Use when caller has node (not combatant dict).


## Returns armor slots from node. Use when caller has node (not combatant dict).
static func get_armor_slots_from_node(node: Node) -> Dictionary:
    if node == null or not node.has_method("_get_armor_slots"):
        return {}
    return node._get_armor_slots()


## Returns weapon display name for UI. Empty if no weapon or node unavailable.


## Returns weapon display name for UI. Empty if no weapon or node unavailable.
static func get_weapon_display_name_from_node(node: Node) -> String:
    var w = get_weapon_from_node(node)
    if w == null:
        return ""
    if "display_name" in w and w.display_name:
        return str(w.display_name)
    if "weapon_type" in w:
        return str(w.weapon_type)
    return "?"


## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).


## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).
static func get_armor_summary_from_node(node: Node) -> Array:
    var slots: Dictionary = get_armor_slots_from_node(node)
    var names: Array = []
    for part in slots.keys():
        var piece = slots[part]
        if piece != null and "display_name" in piece and piece.display_name:
            names.append(piece.display_name)
    return names


## Sum of equipped ArmorPiece.get_total_mass_kg()  -  formation moves, encumbrance tuning.


## Sum of equipped ArmorPiece.get_total_mass_kg()  -  formation moves, encumbrance tuning.
static func get_total_armor_mass_kg_from_node(node: Node) -> float:
    if node == null or not node.has_method("_get_armor_slots"):
        return 0.0
    var slots: Dictionary = node._get_armor_slots()
    var total: float = 0.0
    for part in slots.keys():
        var piece = slots[part]
        if piece != null and piece.has_method("get_total_mass_kg"):
            total += piece.get_total_mass_kg()
    return total

## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.

## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.
