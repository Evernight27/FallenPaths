class_name TurnReadyHandler
extends RefCounted

## Player-side `turn_ready`: **only AI logic gates** —" `get_available_actions` then `CombatAIActionPicker.pick`; no
## separate player target UI.
## F5 footing: **`CombatF5SoakTrace.log_turn_ready_player_ui`** → **`turn_ready_gauge`** (full suffix string; content
## asserts open — **`#wf-soak-audit-status`** · **`#battle-ui`**).
## content asserts open —" **`#wf-soak-audit-status`** · **`#battle-ui`**).
## Same pattern as enemies (`CombatEventDispatch`). BattleScene connects `turn_ready` here.


static func handle(manager: Node, combatant_id: int) -> void:
    if manager == null:
        return
    var me: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if me.is_empty():
        return
    CombatantEntityAccess.finalize_dead_combatant_if_node_dead(manager, me)
    if not CombatantEntityAccess.is_alive_in_combat(me):
        return
    if CombatantEntityAccess.side_str(me) != CombatConstants.SIDE_PLAYER:
        return
    var actions: Array = manager.get_available_actions(combatant_id)
    CombatPlayerTurnHints.emit_turn_ready_hints(manager, me, actions)
    CombatF5SoakTrace.log_turn_ready_player_ui(manager, me, actions)
    CombatAIActionPicker.resolve_picked_turn_or_skip(manager, combatant_id, actions, CombatConstants.SIDE_PLAYER)
