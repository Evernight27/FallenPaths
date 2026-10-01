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
## XSurgeon: medical staff are labelled as such so they read as staff rather than an unlabeled,
## weaponless fighter. They are never the party leader, so the leader branch is checked first.
static func format_party_role_suffix(member: Dictionary) -> String:
    var node_ref: Variant = member.get("node_ref")
    if is_instance_valid(node_ref) and node_ref is Node:
        if PlayerCompanionSetup.member_is_surgeon(node_ref as Node):
            return " · Surgeon"
    if member.get(DataKeys.COMBATANT_IS_PARTY_LEADER, false):
        return " · Leader"
    if is_instance_valid(node_ref) and node_ref is Node and node_ref.get(DataKeys.COMBATANT_IS_PARTY_LEADER) == true:
        return " · Leader"
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


## Lower = more urgent (undressed clot = −1; active bleed = ETA seconds to danger band).
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
    var pending_total: int = 0
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        var bonus_val: float = float(prof.get(stat, 0))
        if bonus_val > 0.0:
            var label: String = prof_labels[stat]
            parts.append("+%s:%d" % [label, int(bonus_val)])
    if "training_pending" in entity:
        var tp: Dictionary = entity.training_pending
        for stat in EntityStatsUtil.PROFICIENCY_STATS:
            pending_total += int(float(tp.get(stat, 0.0)))
    if parts.is_empty() and pending_total == 0:
        return ""
    var prefix: String = "%s " % _proficiency_rank(entity)
    var body: String = " | ".join(parts) if not parts.is_empty() else "no bonuses yet"
    if pending_total > 0:
        body += "  (%d drill%s queued)" % [pending_total, "" if pending_total == 1 else "s"]
    return prefix + body


## Highest proficiency tier reached across all stats, as a short rank name.
static func _proficiency_rank(entity: Node) -> String:
    var best: float = 0.0
    if "_proficiency_bonus" in entity:
        var prof: Dictionary = entity._proficiency_bonus
        for stat in EntityStatsUtil.PROFICIENCY_STATS:
            best = maxf(best, float(prof.get(stat, 0.0)))
    if best <= 0.0:
        return "Rookie"
    if best <= float(EntityProficiency.PROFICIENCY_NOVICE_MAX):
        return "Novice"
    if best <= float(EntityProficiency.PROFICIENCY_PROFICIENT_MAX):
        return "Proficient"
    if best <= float(EntityProficiency.PROFICIENCY_VETERAN_MAX):
        return "Veteran"
    if best <= float(EntityProficiency.PROFICIENCY_ELITE_MAX):
        return "Elite"
    return "Master"


## XCamp-4b: weapon + form mastery, derived combat skill, and rust warning for a party member.
## e.g. "Sword 12/20 (Veteran) | Ox 8/20 (Proficient) | Combat skill 78 | Rusting 3d".
## Returns "" when there is no tracked weapon/form proficiency to show.
static func format_proficiency_mastery_line(member: Dictionary, world: Node2D = null) -> String:
    var node_ref: Variant = (member as Dictionary).get("node_ref")
    if not is_instance_valid(node_ref) or not (node_ref is Node):
        return ""
    var node: Node = node_ref as Node
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
    if entity == null or not (entity is CoreEntity):
        return ""
    var weapon_id: String = str(EncounterSpawner.weapon_id_from_entity(entity)).strip_edges()
    var form: String = CombatWeaponForm.normalize_form(str(member.get("stance_preference", "")).strip_edges())
    var weapon_val: float = EntityProficiency.weapon_proficiency_value(entity, weapon_id)
    var form_val: float = EntityProficiency.form_proficiency_value(entity, form)
    if weapon_val <= 0.0 and form_val <= 0.0:
        return ""
    var parts := []
    if weapon_val > 0.0:
        (
            parts
            . append(
                (
                    "%s %.0f/%.0f (%s)"
                    % [
                        str(CompanyGear.WEAPON_SHORT_NAMES.get(weapon_id, weapon_id)),
                        weapon_val,
                        EntityProficiency.WEAPON_PROF_VETERAN_MAX,
                        _proficiency_rank_from_value(weapon_val),
                    ]
                )
            )
        )
    if form_val > 0.0:
        (
            parts
            . append(
                (
                    "%s %.0f/%.0f (%s)"
                    % [
                        CombatWeaponForm.display_name(form),
                        form_val,
                        EntityProficiency.FORM_PROF_VETERAN_MAX,
                        _proficiency_rank_from_value(form_val),
                    ]
                )
            )
        )
    var skill: float = EntityProficiency.melee_skill_for(entity, weapon_id, form)
    parts.append("Combat skill %d" % int(roundf(skill)))
    var rust: String = _proficiency_rust_note(entity, world)
    if not rust.is_empty():
        parts.append(rust)
    return " | ".join(parts)


## Tier name for a 0—20 weapon/form mastery value (veteran caps at the 20 max).
static func _proficiency_rank_from_value(value: float) -> String:
    if value <= float(EntityProficiency.PROFICIENCY_NOVICE_MAX):
        return "Novice"
    if value <= float(EntityProficiency.PROFICIENCY_PROFICIENT_MAX):
        return "Proficient"
    if value <= float(EntityProficiency.WEAPON_PROF_VETERAN_MAX):
        return "Veteran"
    return "Master"


## Decay warning: fighter holds a trainable bonus (>10) and has gone N days without combat.
static func _proficiency_rust_note(entity: Node, world: Node2D) -> String:
    if world == null:
        return ""
    if not CompanyState.read_stub_proficiency_enabled():
        return ""
    if not "_proficiency_bonus" in entity:
        return ""
    var trainable: bool = false
    var prof: Dictionary = entity._proficiency_bonus
    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        if float(prof.get(stat, 0.0)) > 10.0:
            trainable = true
            break
    # Weapon/form familiarity also rusts above the 10.0 foundational floor (same rule as stats), so a
    # fighter whose only trained edge is blade mastery still deserves the rust warning.
    if not trainable:
        var wp: Dictionary = entity._weapon_proficiency if "_weapon_proficiency" in entity else {}
        for v in wp.values():
            if float(v) > 10.0:
                trainable = true
                break
    if not trainable:
        var fp: Dictionary = entity._form_proficiency if "_form_proficiency" in entity else {}
        for v in fp.values():
            if float(v) > 10.0:
                trainable = true
                break
    if not trainable:
        return ""
    var last_fought: int = 0
    if "last_fought_day" in entity:
        last_fought = int(entity.last_fought_day)
    elif "_last_fought_day" in entity:
        last_fought = int(entity.get("_last_fought_day"))
    if last_fought <= 0:
        return ""
    var inactive: int = CompanyState.get_day_index(world) - last_fought
    if inactive < 1:
        return ""
    return "Rusting %dd — fight to hold gains" % inactive


## XCamp-5f: career-arc line for a party member -- "Fame: N (TierLabel)". Returns "" while the
## fighter is a Newcomer (fame 0) so a brand-new roster stays uncluttered; the tier label comes from
## the single source of truth in CompanyState.
static func format_fame_line(member: Dictionary) -> String:
    if not CompanyState.read_stub_fighter_fame_enabled():
        return ""
    var node_ref: Variant = (member as Dictionary).get("node_ref")
    if not is_instance_valid(node_ref) or not (node_ref is Node):
        return ""
    var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref as Node)
    if entity == null or not ("fame" in entity):
        return ""
    var fame: int = int(entity.fame)
    if fame <= 0:
        return ""
    return "Fame: %d (%s)" % [fame, CompanyState.fame_tier_label(fame)]


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
