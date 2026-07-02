class_name CombatConstantsFormationMove
extends RefCounted

const SURROUND_MAX_SPLIT_DIVISOR := 4
const SURROUND_AWARENESS_AT_LOW_PERCEPTION := 0.65
const INCURSION_PRESSURE_PER_RANK_ADVANTAGE := 0.12
const INCURSION_PRESSURE_MAX := 0.45
const STANCE_DEFENSIVE := "defensive"
const STANCE_BALANCED := "balanced"
const STANCE_AGGRESSIVE := "aggressive"
const STANCE_CONTROLLING := "controlling"
const STANCE_MIN_STAMINA_AGGRESSIVE_RATIO := 0.30
const STANCE_MIN_STAMINA_CONTROLLING_RATIO := 0.24
const OPPONENT_PRESSURE_DEFENSIVE_STAMINA_RATIO := 0.35
const BASE_FALL_BACK_S := 1.0
const LANE_MOD_CLEAR := 1.0
const LANE_MOD_CROWDED := 1.3
const LANE_MOD_BLOCKED := 1.6
const AI_FORMATION_MOVE_BLOCKED_LANE_MULT := 0.22
const PRESSURE_MOD_DEFENSIVE := 0.9
const PRESSURE_MOD_NEUTRAL := 1.0
const PRESSURE_MOD_AGGRESSIVE := 1.3
const FOOTING_STEP_OVER_MIN := 1.15
const FOOTING_STEP_OVER_MAX := 1.25
const DRAG_BACK_DURATION_MULT := 1.15
const FORMATION_PAIR_ABORT_RETRY_COOLDOWN_S := 0.7
const FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S := 0.8
const FORMATION_ROTATE_FILE_REVERSE_PAIR_LOCK_S := 6.0
const STATE_FALLING_BACK := "falling_back"
const STATE_SWAP_RANK := "swap_rank"
const STATE_PLUG_FORWARD := "plug_forward"
const MOVE_ID_SWAP_RANK := "swap_rank"
const MOVE_ID_DRAG_BACK := "drag_back"
const MOVE_ID_FALL_BACK := "fall_back"
const MOVE_ID_ROTATE_FILE := "rotate_file"
const MOVE_ID_PLUG_FORWARD := "plug_forward"
const FORMATION_MOVE_KIND_SWAP_RANK := MOVE_ID_SWAP_RANK
const FORMATION_MOVE_KIND_DRAG_BACK := MOVE_ID_DRAG_BACK
const FORMATION_MOVE_KIND_FALL_BACK_PAIR := "fall_back_pair"
const MOVE_ID_FLEE := "flee"
const MOVE_ID_YIELD := "yield"
const MOVE_ID_ORDER_HOLD_LANE := "order_hold_lane"
const MOVE_ID_ORDER_PROBING := "order_probing"
const MOVE_ID_ORDER_PINCH_CENTER := "order_pinch_center"
const LEADER_FORMATION_COMMAND_MOVE_IDS: Array[String] = [
	MOVE_ID_ORDER_HOLD_LANE,
	MOVE_ID_ORDER_PROBING,
	MOVE_ID_ORDER_PINCH_CENTER,
]
const FORMATION_MOVEMENT_MOVE_IDS: Array[String] = [
	MOVE_ID_SWAP_RANK, MOVE_ID_DRAG_BACK, MOVE_ID_FALL_BACK, MOVE_ID_ROTATE_FILE, MOVE_ID_FLEE, MOVE_ID_PLUG_FORWARD
]

static func is_formation_movement_move(move_id: String) -> bool:
	return move_id in FORMATION_MOVEMENT_MOVE_IDS

static func is_leader_formation_command_move(move_id: String) -> bool:
	return move_id in LEADER_FORMATION_COMMAND_MOVE_IDS

static func is_formation_reposition_move(move_id: String) -> bool:
	return is_formation_movement_move(move_id) and str(move_id) != MOVE_ID_FLEE

static func is_partner_formation_move(move_id: String) -> bool:
	var mid := move_id
	return mid == MOVE_ID_SWAP_RANK or mid == MOVE_ID_DRAG_BACK or mid == MOVE_ID_FALL_BACK or mid == MOVE_ID_PLUG_FORWARD

static func is_plug_forward_move(move_id: String) -> bool:
	return move_id == MOVE_ID_PLUG_FORWARD

static func is_formation_pair_move_kind(move_kind: String) -> bool:
	var k := str(move_kind)
	return (
		k == FORMATION_MOVE_KIND_SWAP_RANK
		or k == FORMATION_MOVE_KIND_DRAG_BACK
		or k == FORMATION_MOVE_KIND_FALL_BACK_PAIR
		or k == MOVE_ID_PLUG_FORWARD
	)

static func formation_pair_move_kind_for_menu_move(move_id: String) -> String:
	match move_id:
		MOVE_ID_SWAP_RANK:
			return FORMATION_MOVE_KIND_SWAP_RANK
		MOVE_ID_DRAG_BACK:
			return FORMATION_MOVE_KIND_DRAG_BACK
		MOVE_ID_FALL_BACK:
			return FORMATION_MOVE_KIND_FALL_BACK_PAIR
		MOVE_ID_PLUG_FORWARD:
			return MOVE_ID_PLUG_FORWARD
		_:
			return str(move_id)
