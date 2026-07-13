class_name PartyRowFormatter
extends RefCounted

## Shared formatting for party/member display (PartyMenu, etc.).
## Centralizes body part label layout and blood/bleeding text.

const ATLS_CLASS_LABELS := {
    1: "Class I (minimal)",
    2: "Class II (moderate)",
    3: "Class III (severe)",
    4: "Class IV (critical)",
}

## Layout for party body part display: pairs per row (head+chest, arms, legs).
const PART_LINES := [["head", "chest"], ["right_arm", "left_arm"], ["left_leg", "right_leg"]]
const BODY_LABELS_SHORT := {
    "head": "Hd", "chest": "Ch", "right_arm": "RA", "left_arm": "LA", "left_leg": "LL", "right_leg": "RL"
}


## Read-only body stat dicts from a party/battle member row.
static func read_body_stat_dicts(row: Dictionary) -> Dictionary:
    return {
        "body_cutting": CombatantEntityAccess.nested_dictionary_read(row, "body_cutting"),
        "body_blunt": CombatantEntityAccess.nested_dictionary_read(row, "body_blunt"),
        "body_max": CombatantEntityAccess.nested_dictionary_read(row, "body_max"),
        "bone_health": CombatantEntityAccess.nested_dictionary_read(row, "bone_health"),
        "bone_max": CombatantEntityAccess.nested_dictionary_read(row, "bone_max"),
    }


## Combined tissue + bone remaining across all body parts (0—"1). Matches battle body-bar tissue = min(cut, blunt).
static func total_body_health_ratio(stats_row: Dictionary) -> float:
    var body_stats: Dictionary = read_body_stat_dicts(stats_row)
    var bc: Dictionary = body_stats["body_cutting"]
    var bb: Dictionary = body_stats["body_blunt"]
    var bm: Dictionary = body_stats["body_max"]
    var bone_h: Dictionary = body_stats["bone_health"]
    var bone_m: Dictionary = body_stats["bone_max"]
    var total_cur: float = 0.0
    var total_max: float = 0.0
    for part in BodyPartConstants.BODY_PARTS:
        var tissue_mx: float = bm.get(part, 0)
        if tissue_mx > 0.0:
            total_cur += minf(bc.get(part, 0.0), bb.get(part, 0.0))
            total_max += tissue_mx
        var bo_mx: int = bone_m.get(part, 0)
        if bo_mx > 0:
            total_cur += bone_h.get(part, 0.0)
            total_max += float(bo_mx)
    if total_max <= 0.0:
        return 1.0
    return clampf(total_cur / total_max, 0.0, 1.0)


## Average limb/torso functionality (arms, legs, head, chest) for formation health-bar tinting.
static func body_functionality_ratio(combatant: Dictionary, manager: Node = null) -> float:
    var node: Node = null
    if manager != null:
        node = CombatantEntityAccess.get_entity_from_manager(manager, combatant)
    if node == null:
        node = CombatantEntityAccess.scene_node(combatant)
    if node == null:
        var perf: float = CombatantEntityAccess.stats_dict(combatant).get("performance_modifier", 1.0)
        return clampf(perf, 0.0, 1.0)
    var samples: PackedFloat32Array = PackedFloat32Array(
        [
            BodyPartQuery.get_arm_functionality(node, "right_arm"),
            BodyPartQuery.get_arm_functionality(node, "left_arm"),
            BodyPartQuery.get_leg_functionality(node),
        ]
    )
    for part in ["head", "chest"]:
        if BodyPartQuery.is_part_physically_operable(node, part):
            samples.append(BodyPartQuery.get_bone_functionality_factor(node, part))
        else:
            samples.append(0.0)
    if samples.is_empty():
        return 1.0
    var sum: float = 0.0
    for v in samples:
        sum += float(v)
    return clampf(sum / float(samples.size()), 0.0, 1.0)


## Formation diagram health bar fill: green at full function, red when impaired.
static func formation_health_bar_fill_color(functionality_ratio: float) -> Color:
    var t: float = 1.0 - clampf(functionality_ratio, 0.0, 1.0)
    return Color(0.28, 0.72, 0.38).lerp(Color(0.88, 0.22, 0.2), t)


## Autowrap in VBox/ScrollContainer needs expand fill or width collapses (one char per line).
static func configure_wrapped_label(lbl: Label) -> void:
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Short labels for cramped battle UI (body bar cells ~56px wide).


## Formats a single body part label: "Part C:cur/max B:cur/max Bo:cur/max".
static func format_body_part(
    part: String, bc: Dictionary, bb: Dictionary, bm: Dictionary, bone_h: Dictionary, bone_m: Dictionary
) -> String:
    var mx: float = bm.get(part, 0)
    if mx <= 0:
        return ""
    var c_cur: float = bc.get(part, 0.0)
    var b_cur: float = bb.get(part, 0.0)
    var bo_cur: float = bone_h.get(part, 0.0)
    var bo_mx = bone_m.get(part, 0)
    return (
        BodyPartConstants.BODY_LABELS.get(part, part)
        + " C:%.2f/%.0f B:%.2f/%.0f Bo:%.2f/%d" % [c_cur, mx, b_cur, mx, bo_cur, bo_mx]
    )


## Compact format for battle UI body bars: "Hd 30|0|0" or "Hd 29.8|0.2|0" when tissue chipped sub-integer.
static func _compact_tissue_cell(cur: float) -> String:
    if absf(cur - roundf(cur)) < 0.05:
        return str(int(roundf(cur)))
    return "%.1f" % cur


static func format_body_part_compact(
    part: String, bc: Dictionary, bb: Dictionary, bm: Dictionary, bone_h: Dictionary, _bone_m: Dictionary
) -> String:
    var mx: float = bm.get(part, 0)
    if mx <= 0:
        return ""
    var short: String = BODY_LABELS_SHORT.get(part, part)
    var c_cur: float = bc.get(part, 0.0)
    var b_cur: float = bb.get(part, 0.0)
    var bo_cur: float = bone_h.get(part, 0.0)
    return (
        "%s %s|%s|%s" % [short, _compact_tissue_cell(c_cur), _compact_tissue_cell(b_cur), _compact_tissue_cell(bo_cur)]
    )


## IV-11 slice 7: roster name suffix for party leader (`PartyMenu`).
static func format_party_role_suffix(member: Dictionary) -> String:
    if member.get("is_party_leader", false):
        return " . Leader"
    var node_ref: Variant = member.get("node_ref")
    if is_instance_valid(node_ref) and node_ref is Node and node_ref.get("is_party_leader") == true:
        return " . Leader"
    return ""


## Formats blood volume only: "Blood: X%".
static func format_blood_only(bv: float) -> String:
    return "Blood: %d%%" % int(clampf(bv, 0.0, 100.0))


## Formats bleeding rate only: "Bleeding: X.X/s" or "" if zero.
static func format_bleeding_only(bleed_rate: float) -> String:
    return "Bleeding: %.1f/s" % bleed_rate if bleed_rate > 0.0 else ""


## Formats blood volume and bleeding rate for display.
static func format_blood_line(bv: float, bleed_rate: float) -> String:
    var text: String = format_blood_only(bv)
    if bleed_rate > 0.0:
        text += "  " + format_bleeding_only(bleed_rate)
    return text


## Seconds until blood volume crosses **`MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING`** at current bleed (INF if no bleed).
static func seconds_to_danger_band(blood_volume_pct: float, total_bleeding_rate: float) -> float:
    return BleedingConstants.seconds_to_exsanguination_at_death_threshold(
        total_bleeding_rate,
        clampf(blood_volume_pct, 0.0, BleedingConstants.MAX_BLOOD_VOLUME),
        BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
    )


static func format_atls_band_label(blood_volume_pct: float) -> String:
    var cls: int = BleedingConstants.atls_hemorrhage_class_from_remaining_pct(blood_volume_pct)
    return "ATLS %s" % ATLS_CLASS_LABELS.get(cls, "Class %d" % cls)


static func format_danger_eta_phrase(blood_volume_pct: float, total_bleeding_rate: float) -> String:
    if total_bleeding_rate <= 0.0:
        return ""
    var eta_s: float = seconds_to_danger_band(blood_volume_pct, total_bleeding_rate)
    if eta_s <= 0.0:
        return "at danger"
    if eta_s == INF:
        return ""
    if eta_s < 60.0:
        return "~%ds to danger" % int(ceilf(eta_s))
    return "~%dm to danger" % int(ceilf(eta_s / 60.0))


## Camp-3.2 triage row: ATLS band + bleed rate + ETA to danger band (party menu).
static func danger_blood_threshold() -> float:
    return BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING


static func format_triage_line(blood_volume_pct: float, total_bleeding_rate: float) -> String:
    var parts: PackedStringArray = PackedStringArray([format_atls_band_label(blood_volume_pct)])
    if total_bleeding_rate > 0.0:
        parts.append(format_bleeding_only(total_bleeding_rate).strip_edges())
        var eta: String = format_danger_eta_phrase(blood_volume_pct, total_bleeding_rate)
        if not eta.is_empty():
            parts.append(eta)
    return " · ".join(parts)


## Campaign scar stat lines (stamina / pain mults from `campaign_afflictions`).
static func format_affliction_effects_line(member: Dictionary) -> String:
    var raw: Variant = member.get("affliction_effects", "")
    if raw is String and not (raw as String).is_empty():
        return raw
    return ""


## Bleeding stopped but part still counts as undressed for camp rest.
static func format_dressing_gate_line(member: Dictionary) -> String:
    if not member.get("has_untreated_wounds", false):
        return ""
    var bleed: float = member.get("total_bleeding_rate", 0.0)
    if bleed > BleedingConstants.BLEEDING_RATE_EPSILON:
        return ""
    return "Bleeding controlled — bandage/pack/TQ still required before camp rest."


## Consciousness, wounds, and mobility between fights (party menu / overworld).
static func format_vitality_status(member: Dictionary) -> String:
    if member.get("is_unconscious", false):
        return "Unconscious — cannot fight until recovered."
    var parts: PackedStringArray = []
    var con: float = member.get("effective_consciousness", 100.0)
    parts.append("Consciousness: %d%%" % int(roundf(con)))
    var wn: int = member.get("wounded_part_count", 0)
    if wn > 0:
        var wound_line: String = "Wounds: %d part(s)" % wn
        if member.get("has_untreated_wounds", false):
            var up: Variant = member.get("untreated_parts", [])
            if not (up is PackedStringArray and (up as PackedStringArray).size() > 0):
                wound_line += " — needs dressing (Party field care)"
        parts.append(wound_line)
    if not member.get("can_flee_or_fall_back", true) and not member.get("is_unconscious", false):
        parts.append("Legs too damaged to retreat")
    return " · ".join(parts)


## Member row needs triage attention on the map (active bleed or undressed wound).
static func member_needs_triage_attention(member: Dictionary) -> bool:
    var bleed: float = member.get("total_bleeding_rate", 0.0)
    if bleed > BleedingConstants.BLEEDING_RATE_EPSILON:
        return true
    return member.get("has_untreated_wounds", false)


## Lower = more urgent (undressed clot = Ã¢Ë'1; active bleed = ETA seconds to danger band).
static func member_triage_priority(member: Dictionary) -> float:
    if not member_needs_triage_attention(member):
        return INF
    var bleed: float = member.get("total_bleeding_rate", 0.0)
    if bleed > BleedingConstants.BLEEDING_RATE_EPSILON:
        return seconds_to_danger_band(member.get("blood_volume", 100.0), bleed)
    return -1.0


## One-line triage summary for banners (settlement worst row, map bleed HUD).
static func format_member_triage_banner_line(member: Dictionary) -> String:
    var bleed: float = member.get("total_bleeding_rate", 0.0)
    if bleed > BleedingConstants.BLEEDING_RATE_EPSILON:
        return format_triage_line(member.get("blood_volume", 100.0), bleed)
    var dressing: String = format_dressing_gate_line(member)
    return dressing


## XCamp-4: formats proficiency bonus line for a party member —" "+STR:3 AGI:2 INT:1 END:4 PER:0" or "" if no bonuses.
static func format_proficiency_bonus_line(member: Dictionary) -> String:
    var node_ref: Variant = (member as Dictionary).get("node_ref")
    if not is_instance_valid(node_ref) or not (node_ref is Node):
        return ""
    var node: Node = node_ref as Node
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
    if entity == null or not "_proficiency_bonus" in entity:
        return ""
    var prof: Dictionary = entity._proficiency_bonus
    var parts := []
    var prof_labels := {
        "strength": "STR", "agility": "AGI", "intelligence": "INT", "endurance": "END", "perception": "PER"
    }
    for stat in ["strength", "agility", "intelligence", "endurance", "perception"]:
        var bonus_val: float = float(prof.get(stat, 0) or 0)
        if bonus_val > 0.0:
            var label: String = prof_labels[stat]
            parts.append("+%s:%d" % [label, int(bonus_val)])
    if parts.is_empty():
        return ""
    return " | ".join(parts)


## Highest-urgency living member from live party snapshots (or summary fallback rows).
static func worst_triage_from_member_rows(rows: Array) -> Dictionary:
    var worst: Dictionary = {}
    var worst_pri: float = INF
    for raw in rows:
        if raw is not Dictionary:
            continue
        var member: Dictionary = raw
        if not member_needs_triage_attention(member):
            continue
        var pri: float = member_triage_priority(member)
        if pri < worst_pri:
            worst_pri = pri
            worst = {
                "name": str(member.get("name", "?")),
                "triage_line": format_member_triage_banner_line(member),
            }
    return worst
