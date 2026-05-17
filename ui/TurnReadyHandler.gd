class_name TurnReadyHandler
extends RefCounted

const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

## Player-side `turn_ready`: **only AI logic gates** — `get_available_actions` then `CombatAIActionPicker.pick`; no separate player target UI.
## Same pattern as enemies (`CombatEventDispatch`). BattleScene connects `turn_ready` here.

static func handle(manager: Node, combatant_id: int) -> void:
	if manager == null:
		return
	var me_raw: Variant = manager._get_by_id(combatant_id) if manager.has_method("_get_by_id") else null
	if me_raw == null or not (me_raw is Dictionary):
		return
	var me: Dictionary = me_raw as Dictionary
	if me.is_empty():
		return
	if _EntityAccess.side_str(me) != "player":
		return
	var actions: Array = manager.get_available_actions(combatant_id)
	_PlayerTurnHints.emit_turn_ready_hints(manager, me, actions)
	CombatAIActionPicker.resolve_picked_turn_or_skip(manager, combatant_id, actions, "player")
