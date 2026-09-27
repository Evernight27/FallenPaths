class_name BattleEndHandler
extends RefCounted

## Handles battle-end cleanup: camera transfer on defeat, party cleanup, enemy cleanup.
## Extracted from CombatFlow for clearer separation of concerns.


static func handle_defeat(world: Node2D, player: Node, winner: String) -> void:
    if winner == CombatConstants.SIDE_PLAYER:
        return

    if is_instance_valid(player) and player.has_node("Camera2D"):
        var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
        if not is_instance_valid(cam):
            return
        var cam_global_pos = cam.global_position
        player.remove_child(cam)
        world.add_child(cam)
        cam.global_position = cam_global_pos
        if cam.has_method("make_current"):
            cam.make_current()
    if is_instance_valid(player):
        player.queue_free()
    var pm_lost = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
    if pm_lost != null and "members" in pm_lost:
        for member in pm_lost.members:
            var node_ref = member.get("node_ref") if member is Dictionary else null
            if is_instance_valid(node_ref) and node_ref is Node and node_ref != player:
                node_ref.queue_free()
    if world.has_meta("_combat_enemies"):
        world.remove_meta("_combat_enemies")


static func handle_victory(world: Node2D, player: Node, winner: String) -> void:
    if winner != CombatConstants.SIDE_PLAYER:
        return
    # SettlementPanel re-enables input on Continue — avoid a gap where map keys queue moves.
    restore_overworld_party(world, player, false)


## Re-enable map control and drop transient combat enemy refs (victory or soft defeat retry).
static func restore_overworld_party(world: Node2D, player: Node, enable_player_input: bool = true) -> void:
    if world == null:
        return
    var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
    if pm != null and "members" in pm:
        for member in pm.members:
            var node_ref = member.get("node_ref") if member is Dictionary else null
            if is_instance_valid(node_ref) and node_ref.has_method("set_process_input"):
                var allow: bool = enable_player_input and node_ref == player
                node_ref.set_process_input(allow)
    if is_instance_valid(player) and player.has_node("Camera2D"):
        var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
        if not is_instance_valid(cam):
            return
        if cam.has_method("make_current"):
            cam.make_current()
    if world.has_meta("_combat_enemies"):
        for enemy in world.get_meta("_combat_enemies"):
            if is_instance_valid(enemy) and enemy is Node:
                enemy.queue_free()
        world.remove_meta("_combat_enemies")
