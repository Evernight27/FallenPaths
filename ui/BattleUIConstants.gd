class_name BattleUIConstants
extends RefCounted

## Battle UI layout and labeling constants. Single source for combat scene configuration.
## Body part lists use BodyPartConstants; this file holds battle-specific UI values.

# Body bar dimensions
const BODY_BAR_CELL_WIDTH := 56
const BODY_BAR_HEIGHT := 12
const GAUGE_WIDTH := 160
## Wide enough for `Wind-up 1.2s · Step +14°` + attention fragments (clip_text still on).
const GAUGE_LABEL_MIN_WIDTH := 118

# Combat log
const LOG_MAX_LINES := 80
const LOG_MIN_WIDTH := 1260
const LOG_MIN_HEIGHT := 216
const MAIN_LIST_PATH := "CombatCanvasLayer/UIRoot/ContentVBox/MainHBox"

# Human-readable labels for medical actions in the action bar (self-target)
const MEDICAL_ACTION_LABELS := {"bandage_self": "Bandaging", "pack_wound": "Packing wound", "apply_tourniquet": "Applying tourniquet", "apply_direct_pressure": "Direct pressure"}
# Labels when target is an ally (same move_id, different wording)
const MEDICAL_ACTION_LABELS_ALLY := {"bandage_self": "Bandaging ally", "pack_wound": "Packing ally's wound", "apply_tourniquet": "Tourniquet (ally)", "apply_direct_pressure": "Direct pressure"}

# Progress bar styling for combat UI
static func progress_bar_background_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.2, 0.95)
	style.set_border_width_all(2)
	style.border_color = Color(0.45, 0.45, 0.5)
	style.set_corner_radius_all(2)
	return style
