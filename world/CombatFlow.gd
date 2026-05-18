class_name CombatFlow
extends RefCounted

## Handles combat initiation and battle-end cleanup. Used by main.gd.
## Optional world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** (`"combat_encounter"`): copied into **`BattleScene.start`** → **`CombatManager.encounter`** before **`start()`** (doctrine, depth polearm AI mults, posture, morale, … — see **`CombatManager`** default_enc in **`CombatManager.gd`**).
## Encounter nodes set meta via **`CampaignEncounterBridge.prepare_combat_from_encounter`**.

const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")

static func start_combat(world: Node2D, enemies: Array) -> void:
	var players: Array = _CampaignBridge.get_fightable_party_nodes(world)
	if players.is_empty():
		push_warning(
			"CombatFlow.start_combat: no living players (check world meta 'party_manager', get_members(), node_ref)."
		)
		return
	for p in players:
		if p.has_method("set_process_input"):
			p.set_process_input(false)
	var pb = _find_party_button(world)
	if pb:
		pb.visible = false

	var battle_script = load(ResourcePaths.BATTLE_SCENE)
	if battle_script == null:
		print("BattleScene script missing")
		return
	var current = world.get_tree().get_current_scene()
	var battle = battle_script.new()
	battle.parent_scene = current
	world.get_tree().root.add_child(battle)
	world.set_meta("_combat_enemies", enemies)

	await world.get_tree().process_frame
	if battle.has_method("start"):
		var party_formation: Dictionary = world.get_meta("party_formation", {}) if world.has_meta("party_formation") else {}
		var enemy_formation: Dictionary = world.get_meta("enemy_formation", {}) if world.has_meta("enemy_formation") else {}
		var combat_encounter: Dictionary = (
			world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
			if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
			else {}
		)
		battle.start(players, enemies, party_formation, enemy_formation, combat_encounter)
	await world.get_tree().process_frame
	if battle.has_signal("battle_ended"):
		battle.connect("battle_ended", Callable(world, "_on_battle_ended"), CONNECT_ONE_SHOT)

static func handle_battle_ended(world: Node2D, winner: String, defeated: Node) -> void:
	var def_name: String = str(defeated.name) if defeated != null else "null"
	print("[Combat] handle_battle_ended: winner=%s defeated=%s" % [winner, def_name])
	await world.get_tree().process_frame
	var player = world.get_node_or_null("Character")
	var player_lost := (winner != "player")
	var outcome: String = "defeat" if player_lost else "victory"
	print("[Combat] handle_battle_ended: player_lost=%s => %s" % [player_lost, outcome])

	if player_lost:
		BattleEndHandler.handle_defeat(world, player, winner)
		_CampaignBridge.clear_transient_combat_meta(world)
		return

	BattleEndHandler.handle_victory(world, player, winner)
	_CampaignBridge.on_return_from_combat(world, winner)
	var pb = _find_party_button(world)
	if pb:
		pb.visible = true

static func _find_party_button(world: Node2D) -> Control:
	var root = world.get_tree().root
	for child in root.get_children():
		if "name" in child and child.name == "UIOverlayLayer":
			if child.has_node("PartyButton"):
				return child.get_node("PartyButton")
			for gc in child.get_children():
				if "name" in gc and gc.name == "PartyButton":
					return gc
	for child in root.get_children():
		if child.has_method("find_node"):
			var pb = child.find_node("PartyButton", true, false)
			if pb != null:
				return pb
		if "name" in child and child.name == "PartyButton":
			return child
	return null
