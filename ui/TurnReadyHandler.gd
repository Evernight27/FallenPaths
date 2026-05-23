class_name TurnReadyHandler
extends RefCounted

const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")

## Player-side `turn_ready`: **only AI logic gates** — `get_available_actions` then `CombatAIActionPicker.pick`; no separate player target UI.
## Same pattern as enemies (`CombatEventDispatch`). BattleScene connects `turn_ready` here.

static func handle(manager: Node, combatant_id: int) -> void:
	if manager == null:
		return
	var me: Dictionary = _EntityAccess.manager_get_combatant(manager, combatant_id)
	if me.is_empty():
		return
	if _EntityAccess.side_str(me) != "player":
		return
	var actions: Array = manager.get_available_actions(combatant_id)
	_PlayerTurnHints.emit_turn_ready_hints(manager, me, actions)
	_F5SoakTrace.log_turn_ready_player_ui(manager, me, actions)
	CombatAIActionPicker.resolve_picked_turn_or_skip(manager, combatant_id, actions, "player")
