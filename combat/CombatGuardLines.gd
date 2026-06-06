class_name CombatGuardLines
extends RefCounted

## HEMA Method C: eight diagonal guard/attack lines (45° sectors).
## Cardinals remain valid; **`normalize_line`** maps four-line guard ids into eight-line octants.
## Footing: UI via **`display_short_for_line`**; octant PA step table via **`position_angle_offset_deg_for_line`** when eight-guard flag on — LIVE_PATHS **`#wf-form-guard-pa-matrix`** · hub **`#wf-tier-44-pa`**.

const LINE_HIGH := "high"
const LINE_HIGH_RIGHT := "high_right"
const LINE_RIGHT := "right"
const LINE_LOW_RIGHT := "low_right"
const LINE_LOW := "low"
const LINE_LOW_LEFT := "low_left"
const LINE_LEFT := "left"
const LINE_HIGH_LEFT := "high_left"

const ALL_LINES: Array = [
	LINE_HIGH,
	LINE_HIGH_RIGHT,
	LINE_RIGHT,
	LINE_LOW_RIGHT,
	LINE_LOW,
	LINE_LOW_LEFT,
	LINE_LEFT,
	LINE_HIGH_LEFT,
]

const LINE_TO_ANGLE_DEG: Dictionary = {
	LINE_HIGH: 0.0,
	LINE_HIGH_RIGHT: 45.0,
	LINE_RIGHT: 90.0,
	LINE_LOW_RIGHT: 135.0,
	LINE_LOW: 180.0,
	LINE_LOW_LEFT: 225.0,
	LINE_LEFT: 270.0,
	LINE_HIGH_LEFT: 315.0,
}

## Four-line cardinal labels → primary octant (path tables keyed by cardinal).
const FOUR_LINE_TO_OCTANT: Dictionary = {
	"high": LINE_HIGH,
	"right": LINE_RIGHT,
	"low": LINE_LOW,
	"left": LINE_LEFT,
}

const LINE_TO_CARDINAL: Dictionary = {
	LINE_HIGH: LINE_HIGH,
	LINE_HIGH_RIGHT: LINE_HIGH,
	LINE_RIGHT: LINE_RIGHT,
	LINE_LOW_RIGHT: LINE_LOW,
	LINE_LOW: LINE_LOW,
	LINE_LOW_LEFT: LINE_LOW,
	LINE_LEFT: LINE_LEFT,
	LINE_HIGH_LEFT: LINE_HIGH,
}

const LINE_ADJACENTS: Dictionary = {
	LINE_HIGH: [LINE_HIGH_LEFT, LINE_HIGH_RIGHT],
	LINE_HIGH_RIGHT: [LINE_HIGH, LINE_RIGHT],
	LINE_RIGHT: [LINE_HIGH_RIGHT, LINE_LOW_RIGHT],
	LINE_LOW_RIGHT: [LINE_RIGHT, LINE_LOW],
	LINE_LOW: [LINE_LOW_RIGHT, LINE_LOW_LEFT],
	LINE_LOW_LEFT: [LINE_LOW, LINE_LEFT],
	LINE_LEFT: [LINE_LOW_LEFT, LINE_HIGH_LEFT],
	LINE_HIGH_LEFT: [LINE_LEFT, LINE_HIGH],
}

const LINE_TO_DEFAULT_PART: Dictionary = {
	LINE_HIGH: "head",
	LINE_HIGH_RIGHT: "head",
	LINE_RIGHT: "right_arm",
	LINE_LOW_RIGHT: "right_leg",
	LINE_LOW: "left_leg",
	LINE_LOW_LEFT: "left_leg",
	LINE_LEFT: "left_arm",
	LINE_HIGH_LEFT: "head",
}

## Tier 4.4 PA step offsets (°) per octant — cardinals match **`CombatConstants`** 4-key table; diagonals blend adjacent cardinals.
const POSITION_ANGLE_OFFSET_DEG_BY_LINE: Dictionary = {
	LINE_HIGH: 0.0,
	LINE_HIGH_RIGHT: -7.0,
	LINE_RIGHT: -14.0,
	LINE_LOW_RIGHT: -4.0,
	LINE_LOW: 6.0,
	LINE_LOW_LEFT: 10.0,
	LINE_LEFT: 14.0,
	LINE_HIGH_LEFT: 7.0,
}

## Compact UI labels (gauge / formation diagram) — distinct octants at a glance.
const LINE_DISPLAY_SHORT: Dictionary = {
	LINE_HIGH: "Hi",
	LINE_HIGH_RIGHT: "HiR",
	LINE_RIGHT: "Rt",
	LINE_LOW_RIGHT: "LoR",
	LINE_LOW: "Lo",
	LINE_LOW_LEFT: "LoL",
	LINE_LEFT: "Lf",
	LINE_HIGH_LEFT: "HiL",
}

const LINE_DISPLAY_LONG: Dictionary = {
	LINE_HIGH: "High",
	LINE_HIGH_RIGHT: "High right",
	LINE_RIGHT: "Right",
	LINE_LOW_RIGHT: "Low right",
	LINE_LOW: "Low",
	LINE_LOW_LEFT: "Low left",
	LINE_LEFT: "Left",
	LINE_HIGH_LEFT: "High left",
}


static func normalize_line(line: String) -> String:
	var k: String = str(line).strip_edges()
	if k in ALL_LINES:
		return k
	if FOUR_LINE_TO_OCTANT.has(k):
		return str(FOUR_LINE_TO_OCTANT[k])
	return LINE_HIGH


static func is_known_line(line: String) -> bool:
	var k: String = str(line).strip_edges()
	return k in ALL_LINES or FOUR_LINE_TO_OCTANT.has(k)


static func line_to_angle(line: String) -> float:
	return float(LINE_TO_ANGLE_DEG.get(normalize_line(line), 0.0))


static func angle_to_line(angle_deg: float) -> String:
	var a: float = fmod(angle_deg + 360.0, 360.0)
	var idx: int = int(floor((a + 22.5) / 45.0)) % 8
	return str(ALL_LINES[idx])


static func opposite_line(line: String) -> String:
	return angle_to_line(line_to_angle(line) + 180.0)


static func cardinal_for_path_lookup(line: String) -> String:
	return str(LINE_TO_CARDINAL.get(normalize_line(line), LINE_HIGH))


static func default_part_for_line(line: String) -> String:
	return str(LINE_TO_DEFAULT_PART.get(normalize_line(line), "head"))


static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
	var d: float = fmod(absf(a_deg - b_deg) + 360.0, 360.0)
	return minf(d, 360.0 - d) if d > 180.0 else d


static func alignment_from_lines(attack_line: String, guard_line: String, floor_align: float) -> float:
	var theta: float = angle_diff_deg(line_to_angle(attack_line), line_to_angle(guard_line))
	return maxf(floor_align, cos(theta * PI / 180.0))


static func position_angle_offset_deg_for_line(line: String) -> float:
	return float(POSITION_ANGLE_OFFSET_DEG_BY_LINE.get(normalize_line(line), 0.0))


static func display_short_for_line(line: String) -> String:
	return str(LINE_DISPLAY_SHORT.get(normalize_line(line), ""))


static func display_long_for_line(line: String) -> String:
	return str(LINE_DISPLAY_LONG.get(normalize_line(line), "High"))


static func build_line_angle_deg_matrix(floor_align: float) -> Dictionary:
	var out: Dictionary = {}
	for g in ALL_LINES:
		var row: Dictionary = {}
		for a in ALL_LINES:
			row[a] = int(round(rad_to_deg(acos(alignment_from_lines(a, g, floor_align)))))
		out[g] = row
	return out
