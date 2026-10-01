class_name CompanyGear
extends RefCounted

## CompanyGear -- gladiator gear commerce: buy + equip weapons and armor.
## Spends company gold (CompanyEconomy) and equips on the party member's combat entity (CoreEntity).
## Gear cost table lives here (gear domain); gold state lives in CompanyEconomy.
## Armor is a per-part buy-ladder (XCamp-4f); "best per part" = the plate-grade top tier.

## Gold price per weapon id (matches WeaponConstants template ids, uppercase).
const WEAPON_PRICES: Dictionary = {
    "SWORD": 150,
    "AXE": 150,
    "MACE": 180,
    "DAGGER": 100,
    "SPEAR": 200,
}
## XCamp-4f: ordered armor buy-ladder per body part, cheapest -> most protective.
## A fighter climbs the ladder one tier at a time; only a tier strictly better than
## the piece already worn on that part is purchasable (no downgrades / re-buys).
## Material tiers (from the sim, see ArmorConstants): cloth < leather < mail < plate.
## Every part carries 4 tiers (mail sits between leather and plate).
const GEAR_ARMOR_TIERS_BY_PART: Dictionary = {
    "head": ["CLOTH_COIF", "LEATHER_CAP", "MAIL_COIF", "KETTLE_HELM"],
    "chest": ["GAMBESON", "LEATHER_CUIRASS", "HAUBERK", "CUIRASS"],
    "right_arm": ["ARM_WRAPS_RIGHT", "LEATHER_BRACERS_RIGHT", "MAIL_SLEEVES_RIGHT", "VAMBRACES_RIGHT"],
    "left_arm": ["ARM_WRAPS_LEFT", "LEATHER_BRACERS_LEFT", "MAIL_SLEEVES_LEFT", "VAMBRACES_LEFT"],
    "right_leg": ["LEG_WRAPS_RIGHT", "LEATHER_GREAVES_RIGHT", "MAIL_CHAUSSES_RIGHT", "GREAVES_RIGHT"],
    "left_leg": ["LEG_WRAPS_LEFT", "LEATHER_GREAVES_LEFT", "MAIL_CHAUSSES_LEFT", "GREAVES_LEFT"],
}
## XCamp-4e/4f: single buy + sell price table for all 24 armor pieces, keyed by material
## tier (cloth < leather < mail < plate). Buy prices come from here (armor_price); selling
## refunds SELL_FRACTION of the same value, so selling back a piece you just bought is exactly
## half. Weapons are priced separately in WEAPON_PRICES (all 5 ids).
const SELL_FRACTION: float = 0.5
const ARMOR_PIECE_PRICES: Dictionary = {
    "KETTLE_HELM": 120,
    "MAIL_COIF": 80,
    "LEATHER_CAP": 50,
    "CLOTH_COIF": 30,
    "CUIRASS": 150,
    "HAUBERK": 90,
    "LEATHER_CUIRASS": 60,
    "GAMBESON": 40,
    "VAMBRACES_RIGHT": 75,
    "MAIL_SLEEVES_RIGHT": 55,
    "LEATHER_BRACERS_RIGHT": 40,
    "ARM_WRAPS_RIGHT": 25,
    "VAMBRACES_LEFT": 75,
    "MAIL_SLEEVES_LEFT": 55,
    "LEATHER_BRACERS_LEFT": 40,
    "ARM_WRAPS_LEFT": 25,
    "GREAVES_RIGHT": 75,
    "MAIL_CHAUSSES_RIGHT": 55,
    "LEATHER_GREAVES_RIGHT": 40,
    "LEG_WRAPS_RIGHT": 25,
    "GREAVES_LEFT": 75,
    "MAIL_CHAUSSES_LEFT": 55,
    "LEATHER_GREAVES_LEFT": 40,
    "LEG_WRAPS_LEFT": 25,
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


## The ordered buy-ladder for a body part (cheapest -> most protective).
static func armor_tiers_for_part(part: String) -> Array:
    return (GEAR_ARMOR_TIERS_BY_PART.get(part, []) as Array).duplicate()


## Most-protective (plate-grade) piece id for a body part. Back-compat for the
## "best per part" callers.
static func best_armor_for_part(part: String) -> String:
    var tiers: Array = GEAR_ARMOR_TIERS_BY_PART.get(part, [])
    if tiers.is_empty():
        return ""
    return str(tiers[tiers.size() - 1])


## Gold price to buy a specific armor piece id. 0 for unknown ids.
static func armor_price(piece_id: String) -> int:
    return int(ARMOR_PIECE_PRICES.get(piece_id, 0))


## Gold price for the best (plate-grade) piece on a part. Back-compat.
static func armor_price_for_part(part: String) -> int:
    return armor_price(best_armor_for_part(part))


## Index of a piece in a part's buy-ladder, -1 when it is not a buyable tier on
## that part. Higher index = better armor.
static func armor_tier_index(part: String, piece_id: String) -> int:
    var tiers: Array = GEAR_ARMOR_TIERS_BY_PART.get(part, [])
    return int(tiers.find(piece_id))


## Human-legible display name for an armor piece (falls back to the raw id).
static func armor_display_name(piece_id: String) -> String:
    if piece_id.is_empty():
        return ""
    var def: Dictionary = ArmorConstants.get_piece_definition(piece_id)
    if def.is_empty():
        return piece_id
    return str(def.get("name", piece_id))


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


## XCamp-4f: check whether a specific armor piece is equipped on a body part.
static func is_armor_equipped(node_ref: Node, part: String, piece_id: String) -> bool:
    if piece_id.is_empty():
        return false
    return equipped_armor_piece_id(node_ref, part) == piece_id


## XCamp-4h: for each body part a fighter is currently armored, its display name and
## condition (0.0–100.0, the weakest layer's remaining durability). Parts with no armor
## are omitted. Reads the live ArmorPiece instances, so wear accrued in combat shows.
static func equipped_armor_condition_map(node_ref: Node) -> Dictionary:
    var out: Dictionary = {}
    if node_ref == null or not is_instance_valid(node_ref):
        return out
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return out
    var slots: Dictionary = CombatantEntityAccess.get_armor_slots_from_node(entity)
    for part in slots:
        var piece: Variant = slots[part]
        if piece is not ArmorPiece:
            continue
        var ap := piece as ArmorPiece
        if ap.display_name.is_empty():
            continue
        out[str(part)] = {"name": ap.display_name, "condition": ap.get_condition_pct()}
    return out


static func can_buy_weapon(world: Node2D, node_ref: Node, weapon_id: String) -> bool:
    if weapon_id not in WEAPON_PRICES:
        return false
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    if is_weapon_equipped(node_ref, weapon_id):
        return false
    return _get_economy().get_gold(world) >= weapon_price(weapon_id)


## XCamp-4f: can this fighter buy the given armor piece on a part? Requires the piece to be
## a buyable tier on that part, strictly better than what is already worn (no downgrades /
## re-buys), and the company to be able to afford it.
static func can_buy_armor(world: Node2D, node_ref: Node, part: String, piece_id: String) -> bool:
    if piece_id.is_empty() or piece_id not in ARMOR_PIECE_PRICES:
        return false
    if armor_tier_index(part, piece_id) < 0:
        return false
    if node_ref == null or not is_instance_valid(node_ref):
        return false
    var worn: String = equipped_armor_piece_id(node_ref, part)
    if worn == piece_id:
        return false
    if not worn.is_empty() and armor_tier_index(part, worn) >= armor_tier_index(part, piece_id):
        return false
    return _get_economy().get_gold(world) >= armor_price(piece_id)


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


## XCamp-4f: buy + equip a specific armor tier on a body part. Charges gold,
## refunds if equip fails.
static func buy_armor(world: Node2D, node_ref: Node, part: String, piece_id: String) -> bool:
    if not can_buy_armor(world, node_ref, part, piece_id):
        return false
    var cost := armor_price(piece_id)
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
            "buy_armor %s %s %s gold_left=%d" % [str(node_ref.name), part, piece_id, _get_economy().get_gold(world)]
        )
    return true


## XCamp-4e: sell value (gold refunded) for a weapon by its template id. 0 for unknown ids.
static func sell_value_for_weapon(weapon_id: String) -> int:
    return roundi(float(WEAPON_PRICES.get(weapon_id, 0)) * SELL_FRACTION)


## XCamp-4e: sell value (gold refunded) for an armor piece by its template id. 0 for unknown ids.
## XCamp-4v: refund scales with the piece's current condition (weakest layer's durability, 0-100).
## A fresh piece (default 100) refunds the full SELL_FRACTION; battered gear fetches less — grinding
## armor down and selling it is no longer worth the same as selling it fresh.
static func sell_value_for_piece(piece_id: String, condition_pct: float = 100.0) -> int:
    var price: int = int(ARMOR_PIECE_PRICES.get(piece_id, 0))
    if price <= 0:
        return 0
    return roundi(float(price) * SELL_FRACTION * clampf(condition_pct, 0.0, 100.0) / 100.0)


## XCamp-4h: gold cost to fully repair all worn armor on a fighter. Each equipped piece
## whose condition is below 100% costs ceil(price * lost_fraction), where lost_fraction is
## the missing slice of the weakest layer's durability. 0 when the fighter has no worn armor,
## which is also the signal "there is nothing to repair."
static func armor_repair_cost(node_ref: Node) -> int:
    if node_ref == null or not is_instance_valid(node_ref):
        return 0
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return 0
    var total: int = 0
    for part in CombatantEntityAccess.get_armor_slots_from_node(entity):
        var piece: Variant = entity.armor_slots[part]
        if piece is not ArmorPiece:
            continue
        var ap := piece as ArmorPiece
        var cond: float = ap.get_condition_pct()
        if cond >= 100.0:
            continue
        var price: int = armor_price(EncounterSpawner._armor_piece_id_from_instance(ap))
        if price <= 0:
            continue
        total += ceili(float(price) * (1.0 - cond / 100.0))
    return total


## XCamp-4h: can a fighter afford to repair their worn armor now? True when there is
## something to repair (cost > 0) and the company can cover it.
static func can_repair_armor(world: Node2D, node_ref: Node) -> bool:
    var cost: int = armor_repair_cost(node_ref)
    if cost <= 0:
        return false
    return _get_economy().get_gold(world) >= cost


## XCamp-4h: restore every equipped armor layer on a fighter to full durability, charging the
## proportional cost from `armor_repair_cost`. Refunds the gold and leaves armor unchanged if the
## cost cannot be paid. No-op (returns false) when there is nothing worn.
static func repair_armor(world: Node2D, node_ref: Node) -> bool:
    var cost: int = armor_repair_cost(node_ref)
    if cost <= 0:
        return false
    if not _get_economy().consume_gold(world, cost):
        return false
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        _get_economy().add_gold(world, cost)
        return false
    var slots: Dictionary = CombatantEntityAccess.get_armor_slots_from_node(entity)
    for part in slots:
        var piece: Variant = slots[part]
        if piece is not ArmorPiece:
            continue
        for layer in (piece as ArmorPiece).layers:
            if layer is Dictionary:
                (layer as Dictionary)["durability"] = float(
                    (layer as Dictionary).get("max_durability", ArmorConstants.DEFAULT_ARMOR_LAYER_DURABILITY)
                )
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "repair_armor %s cost=%d gold_left=%d" % [str(node_ref.name), cost, _get_economy().get_gold(world)]
        )
    return true


## XCamp-4e: the template id of the weapon a fighter currently holds ("" when bare-handed).
static func equipped_weapon_id(node_ref: Node) -> String:
    if node_ref == null or not is_instance_valid(node_ref):
        return ""
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return ""
    return str(EncounterSpawner.weapon_id_from_entity(entity)).strip_edges()


## XCamp-4e: the template id of the armor piece a fighter currently wears on a body part ("" when bare).
static func equipped_armor_piece_id(node_ref: Node, part: String) -> String:
    if node_ref == null or not is_instance_valid(node_ref) or part.is_empty():
        return ""
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null:
        return ""
    var ids: Dictionary = EncounterSpawner.armor_ids_from_entity(entity)
    return str(ids.get(part, "")).strip_edges()


## XCamp-4e: unequip + sell the weapon a fighter is currently holding. Refunds the sell value to the
## company and leaves the fighter bare-handed. Returns the gold refunded (0 when there is nothing
## to sell). Combat degrades a null weapon gracefully, so this is a deliberate strategic choice.
static func sell_equipped_weapon(world: Node2D, node_ref: Node) -> int:
    if world == null or node_ref == null or not is_instance_valid(node_ref):
        return 0
    var wid: String = equipped_weapon_id(node_ref)
    if wid.is_empty():
        return 0
    var value: int = sell_value_for_weapon(wid)
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null or not entity.has_method("equip_weapon"):
        return 0
    entity.equip_weapon(null)
    _get_economy().add_gold(world, value)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "sell_weapon %s %s +%dg gold=%d" % [str(node_ref.name), wid, value, _get_economy().get_gold(world)]
        )
    return value


## XCamp-4e: unequip + sell the armor piece a fighter wears on a body part. Refunds the sell value
## to the company and leaves that part bare. Returns the gold refunded (0 when the part is bare).
static func sell_equipped_armor(world: Node2D, node_ref: Node, part: String) -> int:
    if world == null or node_ref == null or not is_instance_valid(node_ref) or part.is_empty():
        return 0
    var piece_id: String = equipped_armor_piece_id(node_ref, part)
    if piece_id.is_empty():
        return 0
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref)
    if entity == null or not entity.has_method("equip_armor"):
        return 0
    var condition_pct: float = 100.0
    var piece: Variant = entity.armor_slots.get(part)
    if piece is ArmorPiece:
        condition_pct = (piece as ArmorPiece).get_condition_pct()
    var value: int = sell_value_for_piece(piece_id, condition_pct)
    entity.equip_armor(part, null)
    _get_economy().add_gold(world, value)
    _get_state().refresh_hud(world)
    if OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            (
                "sell_armor %s %s %s +%dg gold=%d"
                % [str(node_ref.name), part, piece_id, value, _get_economy().get_gold(world)]
            )
        )
    return value
