class_name PartyRowFormatter
extends RefCounted

## Shared formatting for party/member display (PartyMenu, etc.).
## Centralizes body part label layout and blood/bleeding text.

## Layout for party body part display: pairs per row (head+chest, arms, legs).
const PART_LINES := [["head", "chest"], ["right_arm", "left_arm"], ["left_leg", "right_leg"]]

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
