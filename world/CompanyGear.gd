class_name CompanyGear
extends RefCounted

## CompanyGear -- gladiator gear commerce: buy + equip weapons and the best armor piece per body part.
## Spends company gold (CompanyEconomy) and equips on the party member's combat entity (CoreEntity).
## Gear cost table lives here (gear domain); gold state lives in CompanyEconomy.
## "Best per part" = the plate-grade piece, so one click arms a body part with top kit.

## Gold price per weapon id (matches WeaponConstants template ids, uppercase).
const WEAPON_PRICES: Dictionary = {
    "SWORD": 150,
    "AXE": 150,
    "MACE": 180,
    "DAGGER": 100,
    "SPEAR": 200,
}
## Best (plate-grade) armor piece id offered for sale per body part.
const GEAR_BEST_ARMOR_BY_PART: Dictionary = {
    "head": "KETTLE_HELM",
    "chest": "CUIRASS",
    "right_arm": "VAMBRACES_RIGHT",
    "left_arm": "VAMBRACES_LEFT",
    "right_leg": "GREAVES_RIGHT",
    "left_leg": "GREAVES_LEFT",
}
## Gold price per sellable armor piece id.
const ARMOR_PRICES: Dictionary = {
    "KETTLE_HELM": 120,
    "CUIRASS": 150,
    "VAMBRACES_RIGHT": 75,
    "VAMBRACES_LEFT": 75,
    "GREAVES_RIGHT": 75,
    "GREAVES_LEFT": 75,
}
## UI labels (match Weapon/Armor display names so PartyMenu can detect "equipped" without instantiating).
const WEAPON_SHORT_NAMES: Dictionary = {
    "SWORD": "Sword",
    "AXE": "Axe",
    "MACE": "Mace",
    "DAGGER": "Dagger",
    "SPEAR": "Spear",
}
const PART_LABELS: Dictionary = {
    "head": "Head",
    "chest": "Chest",
    "right_arm": "R.Arm",
    "left_arm": "L.Arm",
    "right_leg": "R.Leg",
    "left_leg": "L.Leg",
}
const BEST_ARMOR_DISPLAY: Dictionary = {
    "KETTLE_HELM": "Kettle Helm",
    "CUIRASS": "Cuirass",
    "VAMBRACES_RIGHT": "Vambraces (R)",
    "VAMBRACES_LEFT": "Vambraces (L)",
    "GREAVES_RIGHT": "Greaves (R)",
    "GREAVES_LEFT": "Greaves (L)",
}
## Sale order for the UI.
const WEAPON_SALE_ORDER: Array = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
const ARMOR_PART_SALE_ORDER: Array = [
    "head",
    "chest",
    "right_arm",
    "left_arm",
    "right_leg",
    "left_leg",
]

# Runtime preload -- circular dependency (CompanyState preloads sibling modules; keep lookups lazy).
static var _company_state: Variant = null
static var _company_economy: Variant = null


static func _get_state() -> GDScript:
    if CompanyGear._company_state == null:
        CompanyGear._company_state = load("res://world/CompanyState.gd")
    return CompanyGear._company_state


static func _get_economy() -> GDScript:
    if CompanyGear._company_economy == null:
        CompanyGear._company_economy = load("res://world/CompanyEconomy.gd")
    return CompanyGear._company_economy


static func weapon_price(weapon_id: String) -> int:
    return int(WEAPON_PRICES.get(weapon_id, 0))


static func best_armor_for_part(part: String) -> String:
    return str(GEAR_BEST_ARMOR_BY_PART.get(part, ""))


static func armor_price_for_part(part: String) -> int:
    var piece_id := best_armor_for_part(part)
    return int(ARMOR_PRICES.get(piece_id, 0))


static func is_weapon_equipped(node_ref: Node, weapon_id: String) -> bool:
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return false
    return str(EncounterSpawner.weapon_id_from_entity(entity)).strip_edges() == weapon_id


static func is_best_armor_equipped(node_ref: Node, part: String) -> bool:
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    var piece_id := best_armor_for_part(part)
    if piece_id.is_empty():
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return false
    var ids: Dictionary = EncounterSpawner.armor_ids_from_entity(entity)
    return str(ids.get(part, "")).strip_edges() == piece_id


static func can_buy_weapon(world: Node2D, node_ref: Node, weapon_id: String) -> bool:
    if weapon_id not in WEAPON_PRICES:
        return false
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    if is_weapon_equipped(node_ref, weapon_id):
        return false
    return _get_economy().get_gold(world) >= weapon_price(weapon_id)


static func can_buy_armor(world: Node2D, node_ref: Node, part: String) -> bool:
    var piece_id := best_armor_for_part(part)
    if piece_id.is_empty() or piece_id not in ARMOR_PRICES:
        return false
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    if is_best_armor_equipped(node_ref, part):
        return false
    return _get_economy().get_gold(world) >= armor_price_for_part(part)


## Buy + equip a weapon on a party member. Charges gold, refunds if equip fails.
static func buy_weapon(world: Node2D, node_ref: Node, weapon_id: String) -> bool:
    if not can_buy_weapon(world, node_ref, weapon_id):
        return false
    var cost := weapon_price(weapon_id)
    if not _get_economy().consume_gold(world, cost):
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    var w: Weapon = Weapon.create_from_definition(weapon_id)
    if entity == null or not entity.has_method("equip_weapon") or w == null:
        _get_economy().add_gold(world, cost)
        return false
    entity.equip_weapon(w)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "buy_weapon %s %s gold_left=%d" % [str(node_ref.name), weapon_id, _get_economy().get_gold(world)]
        )
    return true


## Buy + equip the best armor piece for a body part. Charges gold, refunds if equip fails.
static func buy_armor(world: Node2D, node_ref: Node, part: String) -> bool:
    if not can_buy_armor(world, node_ref, part):
        return false
    var piece_id := best_armor_for_part(part)
    var cost := armor_price_for_part(part)
    if not _get_economy().consume_gold(world, cost):
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    var piece: ArmorPiece = ArmorPiece.create_from_definition(piece_id)
    if entity == null or not entity.has_method("equip_armor") or piece == null:
        _get_economy().add_gold(world, cost)
        return false
    entity.equip_armor(part, piece)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "buy_armor %s %s gold_left=%d" % [str(node_ref.name), piece_id, _get_economy().get_gold(world)]
        )
    return true
