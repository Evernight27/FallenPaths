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

# Human-readable labels for medical actions in the action bar (self-target)
const MEDICAL_ACTION_LABELS := {
	CombatConstants.MOVE_ID_BANDAGE_SELF: "Bandaging",
	CombatConstants.MOVE_ID_PACK_WOUND: "Packing wound",
	CombatConstants.MOVE_ID_APPLY_TOURNIQUET: "Applying tourniquet",
	CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE: "Direct pressure",
}
# Labels when target is an ally (same move_id, different wording)
const MEDICAL_ACTION_LABELS_ALLY := {
	CombatConstants.MOVE_ID_BANDAGE_SELF: "Bandaging ally",
	CombatConstants.MOVE_ID_PACK_WOUND: "Packing ally's wound",
	CombatConstants.MOVE_ID_APPLY_TOURNIQUET: "Tourniquet (ally)",
	CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE: "Direct pressure",
}

# Formation actions (player turn-ready log + gauge hints — Phase 2 **II-5a**)
const FORMATION_ACTION_LABELS := {
	CombatConstants.MOVE_ID_SWAP_RANK: "Swap rank",
	CombatConstants.MOVE_ID_DRAG_BACK: "Drag back (pair)",
	CombatConstants.MOVE_ID_FALL_BACK: "Fall back",
	CombatConstants.MOVE_ID_ROTATE_FILE: "Rotate file",
	CombatConstants.MOVE_ID_FLEE: "Flee",
	CombatConstants.MOVE_ID_ATTEMPT_CLOSE: "Close distance",
}

# Progress bar styling for combat UI
static func progress_bar_background_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.2, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.45, 0.5)
	style.set_corner_radius_all(2)
	return style
