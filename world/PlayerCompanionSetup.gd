class_name PlayerCompanionSetup
extends RefCounted

## Assigns species, party boost, random equipment, and optional **`stance_preference`** to player and companions.
## Call before PartySetup so party UI snapshot has correct stats.

const COMPANION_STANCE_PREFS: Array[String] = [
	"plow", "wall", "balanced", "ox", "tempest", "wrath",
]

static func setup_player_and_companion(
	world: Node2D, rng: RandomNumberGenerator, randomize_equipment: bool = true
) -> void:
	if not world.has_node("Character"):
		return
	var player = world.get_node("Character")
	player.is_party_leader = true
	_setup_character(player, rng, randomize_equipment)

	for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
		var path = "Character/Companion" + ("" if i == 1 else str(i))
		if world.has_node(path):
			var companion = world.get_node(path)
			companion.is_party_leader = false
			companion.set_process_input(false)
			_setup_character(companion, rng, randomize_equipment, i - 1)

static func _setup_character(
	character: Node,
	rng: RandomNumberGenerator,
	randomize_equipment: bool,
	companion_index: int = -1
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
			character.stance_preference = COMPANION_STANCE_PREFS[
				companion_index % COMPANION_STANCE_PREFS.size()
			]


## Dev soak: equip every party **`Character`** / **`Companion*`** with one weapon id (e.g. **`SWORD`** for II-2b).
static func equip_party_weapons(world: Node2D, weapon_id: String) -> void:
	if world == null or weapon_id.is_empty():
		return
	if world.has_node("Character"):
		EncounterSpawner.equip_weapon_id(world.get_node("Character"), weapon_id)
	for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
		var path := "Character/Companion" + ("" if i == 1 else str(i))
		if world.has_node(path):
			EncounterSpawner.equip_weapon_id(world.get_node(path), weapon_id)
