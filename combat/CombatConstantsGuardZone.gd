class_name CombatConstantsGuardZone
extends RefCounted

const GUARD_ZONE_BONUS := 1.4
const GUARD_ZONE_UNGUARDED_PENALTY := 0.75
const GUARD_DEFAULT := "high"
const PART_TO_LINE: Dictionary = {"head": "high", "chest": "high", "left_arm": "left", "right_arm": "right", "left_leg": "low", "right_leg": "low"}
const LINE_TO_DEFAULT_PART: Dictionary = {"high": "head", "low": "left_leg", "left": "left_arm", "right": "right_arm"}
