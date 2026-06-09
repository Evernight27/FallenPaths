class_name CombatFormationMoveIds
extends RefCounted

## Formation move IDs, predicates, and related constants.
## Extracted from CombatConstants for modular organization.
##
## Read order: movement move IDs → leader commands → focus/wait → attempt_close → skip turn → partner/pair helpers

# --- Formation movement move IDs ---
const MOVE_ID_SWAP_RANK := "swap_rank"
const MOVE_ID_DRAG_BACK := "drag_back"
const MOVE_ID_FALL_BACK := "fall_back"
const MOVE_ID_ROTATE_FILE := "rotate_file"
## Tier 6.2: leave the engagement (not a rank swap / solo fall_back within the line).
const MOVE_ID_FLEE := "flee"

## Formation move kind constants (for pair-move dispatch).
const FORMATION_MOVE_KIND_SWAP_RANK := MOVE_ID_SWAP_RANK
const FORMATION_MOVE_KIND_DRAG_BACK := MOVE_ID_DRAG_BACK
const FORMATION_MOVE_KIND_FALL_BACK_PAIR := "fall_back_pair"

## State strings for formation moves.
const STATE_FALLING_BACK := "falling_back"
const STATE_SWAP_RANK := "swap_rank"

# --- Leader formation command move IDs (IV-11) ---
const MOVE_ID_ORDER_HOLD_LANE := "order_hold_lane"
const MOVE_ID_ORDER_PROBING := "order_probing"
const MOVE_ID_ORDER_PINCH_CENTER := "order_pinch_center"
const LEADER_FORMATION_COMMAND_MOVE_IDS: Array[String] = [
	MOVE_ID_ORDER_HOLD_LANE,
	MOVE_ID_ORDER_PROBING,
	MOVE_ID_ORDER_PINCH_CENTER,
]

## Swap / drag / fall back / rotate / flee — used so "only formation moves" still offers wait.
const FORMATION_MOVEMENT_MOVE_IDS: Array[String] = [
	MOVE_ID_SWAP_RANK, MOVE_ID_DRAG_BACK, MOVE_ID_FALL_BACK, MOVE_ID_ROTATE_FILE, MOVE_ID_FLEE
]

# --- Focus / wait move IDs ---
## Explicit no-op: pass turn, schedule next action_ready (same delays as skip_turn).
const MOVE_ID_WAIT := "wait"
## Tier 4.3.7: retarget mental focus_part + guard_line while waiting (no strike).
const MOVE_ID_FOCUS_HIGH := "focus_high"
const MOVE_ID_FOCUS_LOW := "focus_low"
const MOVE_ID_FOCUS_LEFT := "focus_left"
const MOVE_ID_FOCUS_RIGHT := "focus_right"
const FOCUS_LINE_MOVE_IDS: Array[String] = [
	MOVE_ID_FOCUS_HIGH,
	MOVE_ID_FOCUS_LOW,
	MOVE_ID_FOCUS_LEFT,
	MOVE_ID_FOCUS_RIGHT,
]

# --- Attempt close ---
const MOVE_ID_ATTEMPT_CLOSE := "attempt_close"

# --- Skip turn log values ---
const SKIP_TURN_LOG_PASS := "pass"
const SKIP_TURN_LOG_WAIT := "wait"
const SKIP_TURN_LOG_REJECT := "reject"

# --- Close combat constants (IV-2 / M4f) ---
## Max living opponents at DISTANCE_CLOSE vs one defender. Tight formation +1.
const CLOSE_SLOTS_PER_TARGET := 3
const CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS := 1
## When defender close slots are full, damp listed/AI weight toward that defender (IV-2 spread).
const CLOSE_SLOTS_FULL_TARGETING_MULT := 0.32
## After a failed close vs a defender, attempt_close vs that same defender is withheld until combat_clock passes this.
const CLOSE_ATTEMPT_SAME_TARGET_COOLDOWN_S := 1.65


# --- Formation move membership predicates ---
static func is_formation_movement_move(move_id: String) -> bool:
	return str(move_id) in FORMATION_MOVEMENT_MOVE_IDS


static func is_leader_formation_command_move(move_id: String) -> bool:
	return str(move_id) in LEADER_FORMATION_COMMAND_MOVE_IDS


static func is_formation_reposition_move(move_id: String) -> bool:
	return is_formation_movement_move(move_id) and str(move_id) != MOVE_ID_FLEE


static func is_partner_formation_move(move_id: String) -> bool:
	var mid := str(move_id)
	return mid == MOVE_ID_SWAP_RANK or mid == MOVE_ID_DRAG_BACK or mid == MOVE_ID_FALL_BACK


static func is_formation_pair_move_kind(move_kind: String) -> bool:
	var k := str(move_kind)
	return (
		k == FORMATION_MOVE_KIND_SWAP_RANK
		or k == FORMATION_MOVE_KIND_DRAG_BACK
		or k == FORMATION_MOVE_KIND_FALL_BACK_PAIR
	)


static func formation_pair_move_kind_for_menu_move(move_id: String) -> String:
	match str(move_id):
		MOVE_ID_SWAP_RANK:
			return FORMATION_MOVE_KIND_SWAP_RANK
		MOVE_ID_DRAG_BACK:
			return FORMATION_MOVE_KIND_DRAG_BACK
		MOVE_ID_FALL_BACK:
			return FORMATION_MOVE_KIND_FALL_BACK_PAIR
		_:
			return str(move_id)


static func max_close_slots_for_density(density: String) -> int:
	var bonus: int = (
		CLOSE_SLOTS_PER_TARGET_TIGHT_BONUS if str(density).strip_edges() == "tight" else 0
	)
	return CLOSE_SLOTS_PER_TARGET + bonus
