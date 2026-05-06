class_name CombatMoraleCohesion
extends RefCounted

## Tier 1.5 (P6): drives `formations[fid].morale_cohesion_factor` before line cohesion each recompute.
## Priority: encounter per-side override → mean of combatant `morale_cohesion` (alive, not incapacitated) → 1.0.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")


static func apply_to_formations(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var fm: Dictionary = manager.formations
	var enc: Dictionary = manager.encounter if typeof(manager.encounter) == TYPE_DICTIONARY else {}
	for fid in ["player", "enemy"]:
		var form: Dictionary = fm.get(fid, {})
		if form.is_empty():
			continue
		var side: String = str(form.get("side", fid))
		var factor: float = _resolve_morale_cohesion_factor(manager, enc, side)
		form["morale_cohesion_factor"] = clampf(factor, CombatConstants.MORALE_COHESION_FACTOR_MIN, 1.0)


static func _resolve_morale_cohesion_factor(manager: Node, enc: Dictionary, side: String) -> float:
	var key: String = (
		CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER
		if side == "player"
		else CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_ENEMY
	)
	if enc.has(key):
		return float(enc[key])
	return _average_combatant_morale_cohesion(manager, side)


static func _average_combatant_morale_cohesion(manager: Node, side: String) -> float:
	var n: int = 0
	var s: float = 0.0
	for c in manager.combatants:
		if not c.get("alive", false):
			continue
		if str(c.get("side", "")) != side:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		s += clampf(float(c.get("morale_cohesion", 1.0)), 0.0, 1.0)
		n += 1
	if n <= 0:
		return 1.0
	return s / float(n)
