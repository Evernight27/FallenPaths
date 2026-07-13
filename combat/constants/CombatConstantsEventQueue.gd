class_name CombatConstantsEventQueue
extends RefCounted

const EVENT_ACTION_READY := "action_ready"
const EVENT_MELEE_ATTACK := "melee_attack"
const EVENT_RECOVERY_END := "recovery_end"
const EVENT_SWAP_RANK_RESOLVE := "swap_rank_resolve"
const EVENT_FALL_BACK_SOLO_RESOLVE := "fall_back_solo_resolve"
const EVENT_ROTATE_FILE_RESOLVE := "rotate_file_resolve"
const EVENT_PLUG_FORWARD_RESOLVE := "plug_forward_resolve"

const COOLDOWN_ACTION_READY_BASE := 2.0
const READY_DELAY_SKIP_DEFAULT_S := 0.5
const READY_DELAY_SKIP_BACK_RANK_S := 2.0
const READY_DELAY_SKIP_BACK_RANK_DEPTH_LANE_S := 1.0
const READY_DELAY_FORMATION_RECHECK_S := 0.2
const READY_DELAY_AFTER_PROMOTION_S := 0.15
const READY_DELAY_PARRY_RIPOSTE_S := 0.02
const READY_DELAY_CLOSE_ATTEMPT_S := 0.3
