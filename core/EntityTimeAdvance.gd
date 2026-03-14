class_name EntityTimeAdvance
extends RefCounted

## Centralized entity time advancement: bleeding, blood loss, and optional healing.
## Used by CombatManager (delta, no healing) and main._advance_time_one_minute (seconds, with healing).

## Advances bleeding and blood loss on entity. Optionally advances healing when include_healing is true.
## delta_or_seconds: Combat uses real-time delta; overworld uses SECONDS_PER_MOVE.
static func advance(entity: Node, delta_or_seconds: float, include_healing: bool = false) -> void:
	if entity == null:
		return
	if entity.has_method("process_bleeding"):
		entity.process_bleeding(delta_or_seconds)
	if entity.has_method("process_blood_loss"):
		entity.process_blood_loss(delta_or_seconds)
	if include_healing and entity.has_method("process_healing"):
		entity.process_healing(delta_or_seconds)
