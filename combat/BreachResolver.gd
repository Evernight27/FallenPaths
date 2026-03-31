class_name BreachResolver
extends RefCounted

## Hold vs drive for crash / breach (INCURSION_BREACH_MIGRATION_PLAN Phase C). No continuous (x,y) — uses reach, spacing, ZoC.
## Wire from CombatManager.resolve_action when MOVE_ID_CRASH is available.

static func clamp_tactical_penetration_depth(depth: int) -> int:
	return mini(maxi(0, depth), CombatConstants.TACTICAL_PENETRATION_DEPTH_MAX)

## Placeholder: returns no success until hold/drive math and action integration land.
static func contest_crash(_manager: Node, _attacker_id: int, _defender_formation_side: String) -> Dictionary:
	return {"ok": false, "tactical_penetration_depth": 0, "breached_files": {}}
