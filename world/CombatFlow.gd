class_name CombatFlow
extends RefCounted

## Handles combat initiation and battle-end cleanup. Used by main.gd.

static func start_combat(world: Node2D, enemies: Array) -> void:
	var players: Array = _gather_players(world)
	if players.is_empty():
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
		battle.start(players, enemies)
	await world.get_tree().process_frame
	if battle.has_signal("battle_ended"):
		battle.connect("battle_ended", Callable(world, "_on_battle_ended"), CONNECT_ONE_SHOT)

static func handle_battle_ended(world: Node2D, winner: String, defeated: Node) -> void:
	await world.get_tree().process_frame
	var player = world.get_node_or_null("Character")
	var player_lost := (winner != "player")

	if player_lost:
		BattleEndHandler.handle_defeat(world, player, winner)
		return

	BattleEndHandler.handle_victory(world, player, winner)
	var pb = _find_party_button(world)
	if pb:
		pb.visible = true

static func _gather_players(world: Node2D) -> Array:
	var players: Array = []
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm == null or not pm.has_method("get_members"):
		return players
	for member in pm.get_members():
		var node_ref = member.get("node_ref") if member is Dictionary else null
		if not is_instance_valid(node_ref):
			continue
		var alive: bool = true
		if node_ref.has_method("is_dead"):
			alive = not (node_ref as Node).is_dead()
		if alive:
			players.append(node_ref)
	return players

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
