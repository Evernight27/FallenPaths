extends "res://combat/CombatManager.gd"

## Tuning-combat manager: extends CombatManager with an optional action override
## hook (`tuning_override_provider`) so the tuning scene can force a specific move
## without modifying production code. Skips post-victory medical phase by default.

## Callable(combatant_id: int) -> Array[Dictionary] or null.
## When set, called inside get_available_actions(). If it returns a non-empty array,
## that array is returned instead of AvailableActionsBuilder.build().
var tuning_override_provider: Callable

## When true (default), player wins end combat immediately without medical triage.
var tuning_skip_medical: bool = true

func start(player_preset: Dictionary = {}, enemy_preset: Dictionary = {}) -> void:
	set_meta("tuning_expose_strike_context", true)
	set_meta("_harness_expose_penetration_applied", true)
	set_meta("_harness_expose_damage_kinematics", true)
	super.start(player_preset, enemy_preset)

func get_available_actions(combatant_id: int) -> Array:
	if tuning_override_provider != null:
		var result = tuning_override_provider.call(combatant_id)
		if result != null and not result.is_empty():
			return result
	return super(combatant_id)


func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	if not tuning_skip_medical:
		super._end_combat_phase(winner, defeated_node)
		return
	if has_meta("_d001_suppress_winner_check"):
		return
	_reset_tactical_engagement_state()
	var alive_by_side: Dictionary = {}
	var fled_by_side: Dictionary = {}
	for c in combatants:
		var sd: String = _EntityAccess.side_str(c)
		if _EntityAccess.alive_bool(c):
			alive_by_side[sd] = alive_by_side.get(sd, 0) + 1
		if (
			bool(c.get("combat_absent", false))
			or _EntityAccess.state_str(c) == CombatConstants.STATE_FLED
		):
			fled_by_side[sd] = fled_by_side.get(sd, 0) + 1
	var standing_by_side: Dictionary = _StandingHelper.get_standing_by_side(combatants)
	var def_node: String = str(defeated_node.name) if defeated_node != null else "null"
	if not _OperationalLog.play_session_is_editor_f5():
		_Debug.combat_session(
			"phase_end winner=%s defeated_node=%s alive_by_side=%s standing_by_side=%s fled_by_side=%s (tuning skip medical)"
			% [winner, def_node, alive_by_side, standing_by_side, fled_by_side]
		)
	_F5SoakTrace.log_fight_end_summary(winner, false)
	medical_phase = false
	medical_phase_winner = winner
	combat_resolution_closed = true
	_halt_losing_side_combat()
	emit_signal("combat_ended", winner, defeated_node)
	stop()
