class_name TurnReadyHandler
extends RefCounted

## Handles turn_ready for player side: auto-attack when no actions, else pick via CombatAIActionPicker and resolve.
## BattleScene connects to manager.turn_ready and delegates here (enemies are handled directly in CombatStateHandlers).

static func handle(manager: Node, combatant_id: int) -> void:
	if manager == null:
		return
	var me: Dictionary = manager._get_by_id(combatant_id) if manager.has_method("_get_by_id") else {}
	if me == null or me.is_empty():
		return
	if me.side != "player":
		return
	var actions: Array = manager.get_available_actions(combatant_id)
	if actions.is_empty():
		# No valid actions (rank 1 with no swap partner, out of range, medical phase with no wounded).
		# Skip turn instead of attacking — we cannot perform any action.
		if manager.has_method("skip_turn"):
			manager.skip_turn(combatant_id, "pass", "no available actions")
		return
	var choice = CombatAIActionPicker.pick(actions, combatant_id, manager)
	var opts: Dictionary = CombatAIActionPicker.opts_from_choice(choice)
	CombatDebug.flow_log_turn("player", combatant_id, actions, choice)
	manager.resolve_action(combatant_id, choice.target_id, choice.get("move_id", ""), opts)
