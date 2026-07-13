class_name PlayerCompanionSetup
extends RefCounted

## Assigns species, party boost, random equipment, and optional **`stance_preference`** to player and companions.
## Call before PartySetup so party UI snapshot has correct stats.

const COMPANION_STANCE_PREFS: Array[String] = [
    "plow",
    "wall",
    "balanced",
    "ox",
    "tempest",
    "wrath",
]

## XCamp-4: rookie proficiency points per renown level (capped at +10 per stat).
const ROOKIE_PROFICIENCY_PER_RENOWN: float = 0.5
const ROOKIE_PROFICIENCY_CAP: float = 10.0

# Runtime preload ' circular dependency (CompanyState preloads PlayerCompanionSetup).
static var _company_state_cache: Variant = null


static func _get_company_state() -> GDScript:
    if _company_state_cache == null:
        _company_state_cache = load("res://world/CompanyState.gd")
    return _company_state_cache


const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
const _EncounterSpawner := preload("res://world/EncounterSpawner.gd")


## XCamp-3.1: fresh rookie on a vacant companion slot (species + tutorial-tier gear).
static func setup_hired_companion(companion: Node, rng: RandomNumberGenerator, slot_index: int = 0) -> void:
    if companion == null or rng == null:
        return
    companion.is_party_leader = false
    if companion.has_method("set_process_input"):
        companion.set_process_input(false)
    _setup_character(companion, rng, true, slot_index)
    # XCamp-4: rookies start with zero proficiency  -  no combat experience yet.


static func setup_player_and_companion(
    world: Node2D, rng: RandomNumberGenerator, randomize_equipment: bool = true
) -> void:
    var player: Node2D = _Bridge.get_player(world)
    if player == null:
        return
    player.is_party_leader = true
    _setup_character(player, rng, randomize_equipment)
    _setup_rookie_proficiency_for_world(world, player)

    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % PartySetup._companion_node_name(i)
        if world.has_node(path):
            var companion: Node = world.get_node_or_null(path)
            if not is_instance_valid(companion):
                continue
            companion.is_party_leader = false
            companion.set_process_input(false)
            _setup_character(companion, rng, randomize_equipment, i - 1)
            _setup_rookie_proficiency_for_world(world, companion)


static func _setup_character(
    character: Node, rng: RandomNumberGenerator, randomize_equipment: bool, companion_index: int = -1
) -> void:
    if ResourceLoader.exists(ResourcePaths.HUMAN_SPECIES):
        var human_res = load(ResourcePaths.HUMAN_SPECIES)
        if human_res != null and "species" in character:
            character.species = human_res
            if character.has_method("apply_species"):
                character.apply_species()
            if character.has_method("apply_party_boost"):
                character.apply_party_boost()
    if randomize_equipment and character.has_method("equip_armor") and character.has_method("equip_weapon"):
        EncounterSpawner.equip_random_equipment(character, rng)
    if companion_index >= 0 and "stance_preference" in character:
        var pref: String = str(character.get("stance_preference")).strip_edges()
        if pref.is_empty():
            character.stance_preference = COMPANION_STANCE_PREFS[companion_index % COMPANION_STANCE_PREFS.size()]


## Dev soak: equip every party **`Character`** / **`Companion*`** with one weapon id (e.g. **`SWORD`** for II-2b).
static func equip_party_weapons(world: Node2D, weapon_id: String) -> void:
    if world == null or weapon_id.is_empty():
        return
    var player: Node2D = _Bridge.get_player(world)
    if player != null:
        _EncounterSpawner.equip_weapon_id(player, weapon_id)
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var path: String = "Character/%s" % PartySetup._companion_node_name(i)
        if world.has_node(path):
            var companion_node: Node = world.get_node_or_null(path)
            if is_instance_valid(companion_node):
                _EncounterSpawner.equip_weapon_id(companion_node, weapon_id)


## XCamp-4: assign rookie proficiency bonuses scaled by company renown.
static func _setup_rookie_proficiency_for_world(world: Node2D, character: Node) -> void:
    if character == null or world == null:
        return
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    var entity: Node = _Bridge.health_entity_from_character(character)
    if entity == null or not "_proficiency_bonus" in entity:
        return
    var renown: int = _get_company_state().get_renown(world)
    for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
        var bonus: float = minf(maxf(renown * ROOKIE_PROFICIENCY_PER_RENOWN, 0.0), ROOKIE_PROFICIENCY_CAP)
        entity._proficiency_bonus[stat] = bonus
