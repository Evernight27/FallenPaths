class_name PartyRowFormatter
extends RefCounted

## Shared formatting for party/member display (PartyMenu, etc.).
## Centralizes body part label layout and blood/bleeding text.

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

const ATLS_CLASS_LABELS := {
	1: "Class I (minimal)",
	2: "Class II (moderate)",
	3: "Class III (severe)",
	4: "Class IV (critical)",
}

## Layout for party body part display: pairs per row (head+chest, arms, legs).
const PART_LINES := [["head", "chest"], ["right_arm", "left_arm"], ["left_leg", "right_leg"]]


## Read-only body stat dicts from a party/battle member row.
static func read_body_stat_dicts(row: Dictionary) -> Dictionary:
	return {
		"body_cutting": _EntityAccess.nested_dictionary_read(row, "body_cutting"),
		"body_blunt": _EntityAccess.nested_dictionary_read(row, "body_blunt"),
		"body_max": _EntityAccess.nested_dictionary_read(row, "body_max"),
		"bone_health": _EntityAccess.nested_dictionary_read(row, "bone_health"),
		"bone_max": _EntityAccess.nested_dictionary_read(row, "bone_max"),
	}


## Autowrap in VBox/ScrollContainer needs expand fill or width collapses (one char per line).
static func configure_wrapped_label(lbl: Label) -> void:
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Short labels for cramped battle UI (body bar cells ~56px wide).
const BODY_LABELS_SHORT := {"head": "Hd", "chest": "Ch", "right_arm": "RA", "left_arm": "LA", "left_leg": "LL", "right_leg": "RL"}

## Formats a single body part label: "Part C:cur/max B:cur/max Bo:cur/max".
static func format_body_part(part: String, bc: Dictionary, bb: Dictionary, bm: Dictionary, bone_h: Dictionary, bone_m: Dictionary) -> String:
	var mx: float = bm.get(part, 0)
	if mx <= 0:
		return ""
	var c_cur: float = bc.get(part, 0.0)
	var b_cur: float = bb.get(part, 0.0)
	var bo_cur: float = bone_h.get(part, 0.0)
	var bo_mx = bone_m.get(part, 0)
	return BodyPartConstants.BODY_LABELS.get(part, part) + " C:%.2f/%.0f B:%.2f/%.0f Bo:%.2f/%d" % [c_cur, mx, b_cur, mx, bo_cur, bo_mx]

## Compact format for battle UI body bars: "Hd 30|0|0" or "Hd 29.8|0.2|0" when tissue chipped sub-integer.
static func _compact_tissue_cell(cur: float) -> String:
	if absf(cur - roundf(cur)) < 0.05:
		return str(int(roundf(cur)))
	return "%.1f" % cur


static func format_body_part_compact(part: String, bc: Dictionary, bb: Dictionary, bm: Dictionary, bone_h: Dictionary, _bone_m: Dictionary) -> String:
	var mx: float = bm.get(part, 0)
	if mx <= 0:
		return ""
	var short: String = BODY_LABELS_SHORT.get(part, part)
	var c_cur: float = float(bc.get(part, 0.0))
	var b_cur: float = float(bb.get(part, 0.0))
	var bo_cur: float = float(bone_h.get(part, 0.0))
	return "%s %s|%s|%s" % [short, _compact_tissue_cell(c_cur), _compact_tissue_cell(b_cur), _compact_tissue_cell(bo_cur)]

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
	return _Bleeding.seconds_to_exsanguination_at_death_threshold(
		total_bleeding_rate,
		clampf(blood_volume_pct, 0.0, _Bleeding.MAX_BLOOD_VOLUME),
		_Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING
	)


static func format_atls_band_label(blood_volume_pct: float) -> String:
	var cls: int = _Bleeding.atls_hemorrhage_class_from_remaining_pct(blood_volume_pct)
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
	return _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING


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
	if raw is String and not str(raw).is_empty():
		return str(raw)
	return ""


## Consciousness, wounds, and mobility between fights (party menu / overworld).
static func format_vitality_status(member: Dictionary) -> String:
	if bool(member.get("is_unconscious", false)):
		return "Unconscious — cannot fight until recovered."
	var parts: PackedStringArray = []
	var con: float = float(member.get("effective_consciousness", 100.0))
	parts.append("Consciousness: %d%%" % int(roundf(con)))
	var wn: int = int(member.get("wounded_part_count", 0))
	if wn > 0:
		var wound_line: String = "Wounds: %d part(s)" % wn
		if bool(member.get("has_untreated_wounds", false)):
			wound_line += " — untreated (treat in camp or party menu)"
		parts.append(wound_line)
	if not bool(member.get("can_flee_or_fall_back", true)) and not bool(member.get("is_unconscious", false)):
		parts.append("Legs too damaged to retreat")
	return " · ".join(parts)
