class_name CombatConstantsFootworkPA
extends RefCounted

const COMBATANT_KEY_CONTROLLING_CLOSE_TURN_HINT := "controlling_close_turn_hint"

const COMBATANT_KEY_FORMATION_MOVES_TURN_HINT := "formation_moves_turn_hint"

const COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT := "hold_line_focus_only_hint"

const COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG := "position_angle_offset_deg"

const COMBATANT_KEY_POSITION_ANGLE_UI_HINT := "position_angle_ui_hint"

const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE := 0.85

const POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY := 0.55

static func position_angle_defender_offset_deg_for_line(line: String, scale: float) -> float:
    return position_angle_offset_deg_for_attack_line(line) * scale

static func position_angle_offset_deg_for_attack_line(line: String) -> float:
    var k: String = line.strip_edges()
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.position_angle_offset_deg_for_line(k)
    # Fallback for harness/tests with eight-guard flag off — delegate to guard lines module.
    return CombatGuardLines.position_angle_offset_deg_for_line(k)
