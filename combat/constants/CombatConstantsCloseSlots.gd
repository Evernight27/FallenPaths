class_name CombatConstantsCloseSlots
extends RefCounted

const REACH_MID_MIN := 1.2
const MOVE_ID_ATTEMPT_CLOSE := "attempt_close"
const SKIP_TURN_LOG_PASS := "pass"
const SKIP_TURN_LOG_WAIT := "wait"
const SKIP_TURN_LOG_REJECT := "reject"
const CLOSE_SLOTS_PER_TARGET := 3
const CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS := 1
const CLOSE_SLOTS_FULL_TARGETING_MULT := 0.32
const CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S := 1.65


static func max_close_slots_for_density(density: String) -> int:
    var bonus: int = CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS if str(density).strip_edges() == "tight" else 0
    return CLOSE_SLOTS_PER_TARGET + bonus
