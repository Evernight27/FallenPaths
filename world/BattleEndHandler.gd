class_name BattleEndHandler
extends RefCounted

## Handles battle-end cleanup: camera transfer on defeat, party cleanup, enemy cleanup.
## Extracted from CombatFlow for clearer separation of concerns.

static func handle_defeat(world: Node2D, player: Node, winner: String) -> void:
	if winner == "player":
		return
	print("You were defeated.")
	if player != null and is_instance_valid(player) and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		var cam_global_pos = cam.global_position
		player.remove_child(cam)
		world.add_child(cam)
		cam.global_position = cam_global_pos
		if cam.has_method("make_current"):
			cam.make_current()
	if player != null and is_instance_valid(player):
		player.queue_free()
	var pm_lost = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm_lost != null and pm_lost.has_method("get_members"):
		for member in pm_lost.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref) and node_ref is Node and node_ref != player:
				node_ref.queue_free()
	if world.has_meta("_combat_enemies"):
		world.remove_meta("_combat_enemies")

static func handle_victory(world: Node2D, player: Node, winner: String) -> void:
	if winner != "player":
		return
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if is_instance_valid(node_ref) and node_ref.has_method("set_process_input"):
				node_ref.set_process_input(node_ref == player)
	if player != null and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		if cam and cam.has_method("make_current"):
			cam.make_current()
	if world.has_meta("_combat_enemies"):
		for enemy in world.get_meta("_combat_enemies"):
			if is_instance_valid(enemy) and enemy is Node:
				enemy.queue_free()
				print("Enemy defeated.")
		world.remove_meta("_combat_enemies")
