class_name CombatDoctrine
extends RefCounted

## Per-formation intent: steers hybrid targeting (CombatTargetScoring) + clears commitments on change.

static func normalize(doctrine: String) -> String:
	var d: String = str(doctrine).strip_edges().to_lower()
	if d.is_empty() or d == CombatConstants.DOCTRINE_DEFAULT:
		return CombatConstants.DOCTRINE_DEFAULT
	if d == CombatConstants.DOCTRINE_PINCH_CENTER or d == "pinch" or d == "pincer":
		return CombatConstants.DOCTRINE_PINCH_CENTER
	if d == CombatConstants.DOCTRINE_HOLD_LANE or d == "hold":
		return CombatConstants.DOCTRINE_HOLD_LANE
	return CombatConstants.DOCTRINE_DEFAULT


static func doctrine_for_fid(manager: Node, formation_id: String) -> String:
	if manager == null:
		return CombatConstants.DOCTRINE_DEFAULT
	var fd: Variant = manager.get("formation_doctrine")
	if fd == null or typeof(fd) != TYPE_DICTIONARY:
		return CombatConstants.DOCTRINE_DEFAULT
	var d: Variant = (fd as Dictionary).get(str(formation_id), CombatConstants.DOCTRINE_DEFAULT)
	return normalize(str(d))


static func clear_commitments_for_side(manager: Node, formation_id: String) -> void:
	if manager == null:
		return
	for c in manager.combatants:
		if str(c.get("formation_id", "")) != formation_id:
			continue
		c["doctrine_target_commit_id"] = -1
		c["doctrine_commit_until"] = 0.0
