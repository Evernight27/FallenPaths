class_name TurnReadyHandler
extends RefCounted

## Handles turn_ready for player side: auto-attack when no actions, else pick via CombatAIActionPicker and resolve.
## BattleScene connects to manager.turn_ready and delegates here (enemies are handled directly in CombatStateHandlers).

static func handle(manager: Node, combatant_id: int) -> void:
	if manager == null:
		return
	var caps = manager.get_combatants()
	var me: Dictionary = {}
	for c in caps:
		if c.id == combatant_id:
			me = c
			break
	if me.is_empty():
		return
	if me.side != "player":
		return
	var actions: Array = manager.get_available_actions(combatant_id)
	if actions.is_empty():
		# Combat phase: attack first available enemy. Medical phase: no enemies, skip turn.
		for c in caps:
			if c.side != "player" and c.alive:
				manager.resolve_action(combatant_id, c.id)
				return
		# No valid target (e.g. medical phase with no wounded allies)
		if manager.has_method("skip_turn"):
			manager.skip_turn(combatant_id)
		return
	var choice = CombatAIActionPicker.pick(actions, combatant_id, manager)
	var opts: Dictionary = {}
	if choice.get("target_part", "") != "":
		opts["target_part"] = choice.target_part
	manager.resolve_action(combatant_id, choice.target_id, choice.get("move_id", ""), opts)
