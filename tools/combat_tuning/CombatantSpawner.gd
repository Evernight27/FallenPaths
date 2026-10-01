class_name CombatantSpawner
extends RefCounted

## Creates and configures CoreEntity combatants for the tuning scene.
## Wraps the 1v1 setup pattern from CombatRegressionHarnessProficiency1v1Tail.

const _CoreEntity := preload("res://core/CoreEntity.gd")
const _Weapon := preload("res://resources/weapons/Weapon.gd")
const _WeaponForm := preload("res://combat/weapon_form/CombatWeaponForm.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _ArmorPiece := preload("res://resources/armor/ArmorPiece.gd")
static var _entity_access_cache: Variant = null
static var log_sink: Callable = Callable()


static func _get_entity_access() -> GDScript:
    if CombatantSpawner._entity_access_cache == null:
        CombatantSpawner._entity_access_cache = load("res://combat/access/CombatantEntityAccess.gd")
    return CombatantSpawner._entity_access_cache


## Returns {attacker_entity, defender_entity, attacker_id, defender_id}.
static func spawn_1v1(manager: Node, attacker_cfg: Variant, defender_cfg: Variant) -> Dictionary:
    var atk_ent: Node = _create_entity(attacker_cfg)
    var def_ent: Node = _create_entity(defender_cfg)

    var atk_id: int = manager.register(atk_ent, "player")
    var def_id: int = manager.register(def_ent, "enemy")

    return {
        "attacker_entity": atk_ent,
        "defender_entity": def_ent,
        "attacker_id": atk_id,
        "defender_id": def_id,
        "attacker_config": attacker_cfg,
        "defender_config": defender_cfg,
    }


## Creates a single CoreEntity from config.
static func _create_entity(cfg: Variant) -> Node:
    var e := _CoreEntity.new()
    if not cfg.species_tres_path.is_empty() and ResourceLoader.exists(cfg.species_tres_path):
        e.species = load(cfg.species_tres_path)
    e.apply_species()
    e.name = cfg.display_name
    e.dominant_hand = BodyPartConstants.PART_RIGHT_ARM
    e.offhand_functionality = 1.0
    e._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}
    e._weapon_proficiency = {cfg.weapon_id: 20.0}
    e._form_proficiency = {cfg.form: 20.0}

    e.strength = cfg.strength
    e.agility = cfg.agility
    e.intelligence = cfg.intelligence
    e.endurance = cfg.endurance
    e.perception = cfg.perception

    var w := _Weapon.create_from_definition(cfg.weapon_id)
    if w != null:
        e.equip_weapon(w)

    # Apply armor from config overrides
    for part in cfg.armor_overrides:
        var armor_def := _ArmorPiece.create_from_definition(cfg.armor_overrides[part])
        if armor_def != null:
            e.equip_armor(str(part), armor_def)

    var entity_line := (
        "[Tuning] Entity '%s': dominant=%s weapon=%s armor=%s"
        % [e.name, e.dominant_hand, "yes" if w != null else "no", str(cfg.armor_overrides)]
    )
    if CombatantSpawner.log_sink.is_valid():
        CombatantSpawner.log_sink.call(entity_line)
    else:
        print(entity_line)

    return e
