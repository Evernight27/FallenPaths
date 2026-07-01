class_name BattleUIConstants
extends RefCounted

## Battle UI layout and labeling constants. Single source for combat scene configuration.
## Body part lists use BodyPartConstants; this file holds battle-specific UI values.

# Body bar dimensions
const BODY_BAR_CELL_WIDTH := 56
const BODY_BAR_HEIGHT := 12
const GAUGE_WIDTH := 160
## Wide enough for counter + attention + footwork fragments (`clip_text` still on label).
const GAUGE_LABEL_MIN_WIDTH := 176
const FORMATION_HEALTH_BAR_HEIGHT := 4

# Combat log
const LOG_MAX_LINES := 80
const LOG_MIN_WIDTH := 1260
const LOG_MIN_HEIGHT := 216
const MAIN_LIST_PATH := "CombatCanvasLayer/UIRoot/ContentVBox/MainHBox"

# Campaign contract: early exit runs batch_resolve (instant) via finish_battle_interactive; soak uses tick-replay.
const CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_PENDING := (
	"Return to camp and finish medical treatment"
)
const CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_READY := "Return to camp"
const CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_FINISHING := "Finishing medical treatment..."
const SOAK_MEDICAL_EXIT_BUTTON_LABEL_FINISHING := "Finishing triage..."
const CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_PENDING := 360
const CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_READY := 160
const CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_FINISHING := 300
const CAMPAIGN_MEDICAL_VICTORY_LOG_LINE := (
	"\n[color=green] -  -  -  Victory. Click "
	+ CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_PENDING
	+ " to simulate remaining triage time. Any wounds still open after that need Party field care on the map.  -  -  - [/color]\n"
)
const CAMPAIGN_MEDICAL_FINISHED_LOG_LINE := (
	"\n[color=green] -  -  -  Triage complete. Click Return to camp.  -  -  - [/color]\n"
)
const CAMPAIGN_MEDICAL_IDLE_LOG_LINE := (
	"\n[color=green] -  -  -  Triage paused. Click Return to camp and finish medical treatment to leave.  -  -  - [/color]\n"
)
const CAMPAIGN_MEDICAL_EARLY_EXIT_HINT := (
	"Contract battle  -  click Return to camp and finish medical treatment to simulate remaining "
	+ "triage time; use Party field care on the map for any wounds still untreated."
)
const CAMPAIGN_MEDICAL_EARLY_EXIT_HINT_READY := (
	"Contract battle  -  triage complete; click Return to camp."
)
const CAMPAIGN_MEDICAL_TOOLTIP_EXIT_PENDING := (
	"Return to camp  -  finishes in-progress procedures in battle; undressed wounds need Party field care on the map."
)
const CAMPAIGN_MEDICAL_TOOLTIP_EXIT_READY := "Triage complete  -  click Return to camp."
const CAMPAIGN_MEDICAL_FAST_FORWARD_INCOMPLETE_HINT := (
	"Some wounds could not be fully dressed in battle  -  open Party on the map for field care."
)
const MEDICAL_FAST_FORWARD_LOG_LINE := (
	"\n[color=#aab0c0] -  -  -  Simulating remaining triage time...  -  -  - [/color]\n"
)
const CAMPAIGN_MEDICAL_BATCH_LOG_LINE := (
	"\n[color=#aab0c0] -  -  -  Finishing procedures and dressing open wounds...  -  -  - [/color]\n"
)


static func medical_exit_processing_log_line(campaign_contract: bool) -> String:
	return CAMPAIGN_MEDICAL_BATCH_LOG_LINE if campaign_contract else MEDICAL_FAST_FORWARD_LOG_LINE


static func campaign_medical_exit_button_label(can_end_medical_phase: bool) -> String:
	return (
		CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_READY
		if can_end_medical_phase
		else CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_PENDING
	)


static func campaign_medical_exit_button_min_width(can_end_medical_phase: bool) -> int:
	return (
		CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_READY
		if can_end_medical_phase
		else CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_PENDING
	)


static func campaign_medical_exit_button_finishing_min_width() -> int:
	return CAMPAIGN_MEDICAL_EXIT_BUTTON_MIN_WIDTH_FINISHING


static func medical_exit_button_label_finishing(
	campaign_contract: bool,
	open_wounds: int = -1
) -> String:
	var base: String = (
		CAMPAIGN_MEDICAL_EXIT_BUTTON_LABEL_FINISHING
		if campaign_contract
		else SOAK_MEDICAL_EXIT_BUTTON_LABEL_FINISHING
	)
	if open_wounds >= 0:
		return "%s (%d open)" % [base, open_wounds]
	return base


static func campaign_medical_victory_log_line(can_end_medical_phase: bool) -> String:
	if can_end_medical_phase:
		return (
			"\n[color=green] -  -  -  Victory. Click Return to camp.  -  -  - [/color]\n"
		)
	return CAMPAIGN_MEDICAL_VICTORY_LOG_LINE


# Human-readable labels for medical actions in the action bar (self-target)
const MEDICAL_ACTION_LABELS := {
	CombatConstants.MOVE_ID_BANDAGE_SELF: "Bandaging",
	CombatConstants.MOVE_ID_PACK_WOUND: "Packing wound",
	CombatConstants.MOVE_ID_STABILIZE_WOUND: "Stabilizing",
	CombatConstants.MOVE_ID_APPLY_TOURNIQUET: "Applying tourniquet",
	CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE: "Direct pressure",
}
# Labels when target is an ally (same move_id, different wording)
const MEDICAL_ACTION_LABELS_ALLY := {
	CombatConstants.MOVE_ID_BANDAGE_SELF: "Bandaging ally",
	CombatConstants.MOVE_ID_PACK_WOUND: "Packing ally's wound",
	CombatConstants.MOVE_ID_STABILIZE_WOUND: "Stabilizing ally",
	CombatConstants.MOVE_ID_APPLY_TOURNIQUET: "Tourniquet (ally)",
	CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE: "Direct pressure",
}

# Formation actions (player turn-ready log + gauge hints  -  Phase 2 **II-5a**)
const FORMATION_ACTION_LABELS := {
	CombatConstants.MOVE_ID_SWAP_RANK: "Swap rank",
	CombatConstants.MOVE_ID_DRAG_BACK: "Drag back (pair)",
	CombatConstants.MOVE_ID_FALL_BACK: "Fall back",
	CombatConstants.MOVE_ID_ROTATE_FILE: "Rotate file",
	CombatConstants.MOVE_ID_FLEE: "Flee",
	CombatConstants.MOVE_ID_ATTEMPT_CLOSE: "Close distance",
	CombatConstants.MOVE_ID_ORDER_HOLD_LANE: "Order: Hold lane",
	CombatConstants.MOVE_ID_ORDER_PROBING: "Order: Probe",
	CombatConstants.MOVE_ID_ORDER_PINCH_CENTER: "Order: Pinch center",
}

# Progress bar styling for combat UI
static func progress_bar_background_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.2, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.45, 0.5)
	style.set_corner_radius_all(2)
	return style
