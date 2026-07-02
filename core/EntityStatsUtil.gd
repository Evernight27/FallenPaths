class_name EntityStatsUtil
extends RefCounted

## Centralized effective stat calculation with proficiency bonus stacking.
## Replaces duplicated _effective_* functions in EntityWounds, EntityDamage, and EntityPainConsciousness.
## Canonical: `get_effective_stat(entity, stat_name)`  -  call this instead of any private variant.

## Stat names that can receive proficiency bonuses (alignment with CoreEntity stat keys).
const PROFICIENCY_STATS := ["strength", "agility", "endurance", "intelligence", "perception"]

## Compute base stat + proficiency bonus for a single stat key.
## `stat_name` must be one of PROFICIENCY_STATS. Returns raw base + bonus as float.
## No stub gate here - _proficiency_bonus exists on CoreEntity (init to 0.0) even when
## proficiency is disabled; gain path is gated at AttackResultApplier.notify_proficiency_gains_from_resolve.
static func get_effective_stat(entity: Node, stat_name: String) -> float:
	if entity == null or not stat_name in PROFICIENCY_STATS:
		return float(entity.get(stat_name) if entity else 0)
	var eff: float = float(entity.get(stat_name))
	if "_proficiency_bonus" in entity:
		eff += float(entity._proficiency_bonus.get(stat_name, 0) or 0)
	return eff
