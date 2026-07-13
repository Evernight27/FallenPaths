class_name CombatConstantsGuardLinesHelpers
extends RefCounted


static func guard_line_for_body_part(part: String) -> String:
    var p: String = str(part).strip_edges()
    if p.is_empty():
        return CombatConstantsGuardZone.GUARD_DEFAULT
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        match p:
            "head", "neck", "face", "scalp", "chest":
                return CombatGuardLines.LINE_HIGH
            "left_leg":
                return CombatGuardLines.LINE_LOW_LEFT
            "right_leg":
                return CombatGuardLines.LINE_LOW_RIGHT
            "left_arm":
                return CombatGuardLines.LINE_LEFT
            "right_arm":
                return CombatGuardLines.LINE_RIGHT
        for line_key in CombatGuardLines.LINE_TO_DEFAULT_PART:
            if str(CombatGuardLines.LINE_TO_DEFAULT_PART[line_key]) == p:
                return str(line_key)
        return CombatGuardLines.LINE_HIGH
    match p:
        "head", "neck", "face", "scalp", "chest":
            return "high"
        "left_leg", "right_leg":
            return "low"
        "left_arm":
            return "left"
        "right_arm":
            return "right"
    for line_key in CombatConstantsGuardZone.LINE_TO_DEFAULT_PART:
        if str(CombatConstantsGuardZone.LINE_TO_DEFAULT_PART[line_key]) == p:
            return str(line_key)
    return CombatConstantsGuardZone.GUARD_DEFAULT


static func guard_zone_for_guard_line(line: String) -> String:
    if CombatConstantsFeatureFlags.is_feature_hema_eight_guard_lines_enabled():
        return CombatGuardLines.guard_zone_part_for_line(line)
    return str(CombatConstantsGuardZone.LINE_TO_DEFAULT_PART.get(str(line), "head"))
