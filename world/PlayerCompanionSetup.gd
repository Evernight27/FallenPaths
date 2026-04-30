class_name PlayerCompanionSetup
extends RefCounted

## Assigns species, party boost, and random equipment to player and companion.
## Call before PartySetup so party UI snapshot has correct stats.

static func setup_player_and_companion(world: Node2D, rng: RandomNumberGenerator) -> void:
	if not world.has_node("Character"):
		return
	var player = world.get_node("Character")
	player.is_party_leader = true
	_setup_character(player, rng)

	for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
		var path = "Character/Companion" + ("" if i == 1 else str(i))
		if world.has_node(path):
			var companion = world.get_node(path)
			companion.is_party_leader = false
			companion.set_process_input(false)
			_setup_character(companion, rng)

static func _setup_character(character: Node, rng: RandomNumberGenerator) -> void:
	if ResourceLoader.exists(ResourcePaths.HUMAN_SPECIES):
		var human_res = load(ResourcePaths.HUMAN_SPECIES)
		if human_res != null and "species" in character:
			character.species = human_res
			if character.has_method("apply_species"):
				character.apply_species()
			if character.has_method("apply_party_boost"):
				character.apply_party_boost()
	if character.has_method("equip_armor") and character.has_method("equip_weapon"):
		EncounterSpawner.equip_random_equipment(character, rng)
