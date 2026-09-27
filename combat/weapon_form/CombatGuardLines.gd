class_name CombatGuardLines
extends RefCounted

## HEMA Method C: eight diagonal guard/attack lines (45f→deg sectors).
## Cardinals remain valid; **`normalize_line`** maps four-line guard ids into eight-line octants.
## Footing: UI via **`display_short_for_line`**; octant PA step table via **`position_angle_offset_deg_for_line`** when
## eight-guard flag on — LIVE_PATHS **`#wf-form-guard-pa-matrix`** . hub **`#wf-tier-44-pa`**.

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

## Tier 4.4 PA step offsets (f→deg) per octant — cardinals match **`CombatConstants`** 4-key table.
## WF-T1 (2026-06-07): diagonals bias toward dominant adjacent cardinal (Camp-5 soak; was 50/50 blend):
## high_right 57% right . low_right 55% right . low_left 65% left . high_left 65% left.
const POSITION_ANGLE_OFFSET_DEG_BY_LINE: Dictionary = {
    LINE_HIGH: 0.0,
    LINE_HIGH_RIGHT: -8.0,
    LINE_RIGHT: -14.0,
    LINE_LOW_RIGHT: -5.0,
    LINE_LOW: 6.0,
    LINE_LOW_LEFT: 11.0,
    LINE_LEFT: 14.0,
    LINE_HIGH_LEFT: 9.0,
}

## XCamp-4: the open-line window scales with the commitment of the opening event instead of a
## flat FEINT_OPEN_LINE_DURATION_S. A heavier strike (higher intensity) leaves the defender more
## off-line, so the line stays open longer; added on top of the base, bounded by the cap.
const OPEN_LINE_DURATION_INTENSITY_SCALE_S: float = 1.5
## A circumscription (verwunden) goes AROUND the committed blade — the compound motion leaves the
## far side open longer than a same-line follow-up.
const CIRCUMSCRIPTION_OPEN_LINE_DURATION_EXTRA_S: float = 0.75
## Hard cap so intensity + circumscription cannot run the window open-ended.
const OPEN_LINE_DURATION_MAX_S: float = 5.25
## XCamp-4: shape of the open-line recovery curve. openness = (1 - t)^EASE over the window.
## 1.0 is linear (the whole window equally open — too forgiving of a slow close). 2.0 (default) is an
## ease-out: the defender re-balance the acute off-line / blade-commitment quickly, then only the fine
## blade re-coverage to the exact line lingers, so the opening is most exploitable the instant it
## appears and closes fastest at the start of the window. Monotonic, preserves the 0/1 endpoints.
const OPEN_LINE_RECOVERY_EASE: float = 2.0
## XCamp-4: fraction of the *remaining* open-line window that a partial parry preserves. A full
## parry onto the open line is a demonstrated re-coverage (clears the window, see
## close_open_line_on_recover); a partial parry only catches the blade partway, so the line is
## re-covered only partially — the window shrinks to this fraction of its remaining time instead of
## disappearing. Holding the stored duration while moving `until` earlier makes the eased openness
## drop by F^OPEN_LINE_RECOVERY_EASE and end sooner, monotonically (a light follow-up cannot re-open it).
const OPEN_LINE_PARTIAL_RECOVER_FRACTION: float = 0.5

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
    var k: String = line.strip_edges()
    if k in ALL_LINES:
        return k
    if FOUR_LINE_TO_OCTANT.has(k):
        return str(FOUR_LINE_TO_OCTANT[k])
    return LINE_HIGH


static func is_known_line(line: String) -> bool:
    var k: String = line.strip_edges()
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


static func is_flank_diagonal_guard_line(line: String) -> bool:
    var norm: String = normalize_line(line)
    return norm in [LINE_HIGH_LEFT, LINE_LOW_LEFT, LINE_HIGH_RIGHT, LINE_LOW_RIGHT]


## IV-4: diagonal guards use flank cardinal for **`ATTACK_PATHS_BY_GUARD`** (high_left→ 'left, not high).
static func guard_cardinal_for_attack_path(line: String) -> String:
    var norm: String = normalize_line(line)
    match norm:
        LINE_HIGH_LEFT, LINE_LOW_LEFT:
            return LINE_LEFT
        LINE_HIGH_RIGHT, LINE_LOW_RIGHT:
            return LINE_RIGHT
        _:
            return cardinal_for_path_lookup(norm)


static func default_part_for_line(line: String) -> String:
    return str(LINE_TO_DEFAULT_PART.get(normalize_line(line), "head"))


## IV-4: passive **`guard_zone`** / feint read — flank diagonals cover same limb band as
## **`guard_cardinal_for_attack_path`** paths.
static func guard_zone_part_for_line(line: String) -> String:
    var norm: String = normalize_line(line)
    match norm:
        LINE_HIGH_LEFT, LINE_LOW_LEFT:
            return "left_arm"
        LINE_HIGH_RIGHT, LINE_LOW_RIGHT:
            return "right_arm"
        _:
            return default_part_for_line(norm)


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


## IV-5 BP6: attack-side arm that can cross to meet a flank blow when guard line is misaligned.
static func interpose_arm_for_misaligned_guard(attack_line: String, guard_line: String) -> String:
    var atk_norm: String = normalize_line(attack_line)
    var atk_card: String = cardinal_for_path_lookup(atk_norm)
    if atk_card == LINE_RIGHT or atk_norm in [LINE_HIGH_RIGHT, LINE_LOW_RIGHT]:
        return "right_arm"
    if atk_card == LINE_LEFT or atk_norm in [LINE_HIGH_LEFT, LINE_LOW_LEFT]:
        return "left_arm"
    var grd_path: String = guard_cardinal_for_attack_path(guard_line)
    if grd_path == LINE_LEFT:
        return "right_arm"
    if grd_path == LINE_RIGHT:
        return "left_arm"
    return ""


static func guard_attack_misaligned_for_interpose(attack_line: String, guard_line: String) -> bool:
    var theta: float = angle_diff_deg(line_to_angle(attack_line), line_to_angle(guard_line))
    return theta >= CombatConstants.ARM_INTERPOSE_MIN_ANGLE_DEG


## Returns `{ active, arm, align_boost, path_index }` when misaligned guard can still meet blade via limb on path.
static func arm_interpose_eval(
    attack_line: String, guard_line: String, alignment: float, targetable: Array
) -> Dictionary:
    var empty: Dictionary = {"active": false, "arm": "", "align_boost": 0.0, "path_index": -1}
    if not CombatConstants.is_feature_arm_interpose_enabled():
        return empty
    # Only when guard is imperfectly aligned — fully aligned blades do not need a limb cross.
    if alignment >= CombatConstants.ARM_INTERPOSE_MAX_ALIGN:
        return empty
    if not guard_attack_misaligned_for_interpose(attack_line, guard_line):
        return empty
    var arm: String = interpose_arm_for_misaligned_guard(attack_line, guard_line)
    if arm.is_empty() or not targetable.has(arm):
        return empty
    var path: Array = CombatConstants.get_attack_path(attack_line, guard_line)
    if path.is_empty():
        return empty
    var arm_idx: int = path.find(arm)
    if arm_idx < 0 or arm_idx > CombatConstants.ARM_INTERPOSE_MAX_PATH_INDEX:
        return empty
    # MIN_ALIGN..MAX_ALIGN spans the boost ramp; below MIN_ALIGN → full boost (worst misalignment).
    var t: float = clampf(
        (
            (CombatConstants.ARM_INTERPOSE_MAX_ALIGN - alignment)
            / maxf(0.001, CombatConstants.ARM_INTERPOSE_MAX_ALIGN - CombatConstants.ARM_INTERPOSE_MIN_ALIGN)
        ),
        0.0,
        1.0
    )
    var boost: float = CombatConstants.ARM_INTERPOSE_ALIGNMENT_BOOST * t
    return {"active": true, "arm": arm, "align_boost": boost, "path_index": arm_idx}


## XCamp-4: the open-line window length for a given opening event. Base FEINT_OPEN_LINE_DURATION_S
## plus an intensity-scaled extension (heavier commitment = longer off-line), plus a circumscription
## extra (the compound cut goes AROUND the committed blade), capped at OPEN_LINE_DURATION_MAX_S.
## Written to PA_FEINT_OPEN_LINE_DURATION_S at the stamp site and read back by open_line_openness
## so the decay is computed over the same window the stamp actually opened.
static func open_line_duration_s(intensity: float, is_circumscription: bool) -> float:
    var d: float = CombatConstants.FEINT_OPEN_LINE_DURATION_S + clampf(intensity, 0.0, 1.0) * OPEN_LINE_DURATION_INTENSITY_SCALE_S
    if is_circumscription:
        d += CIRCUMSCRIPTION_OPEN_LINE_DURATION_EXTRA_S
    return minf(d, OPEN_LINE_DURATION_MAX_S)


## Computes the defender's current open-line exposure level (0.0 = not open, 1.0 = fully open).
## Returns 0.0 when no live feint/deflect/circumscription open-line window exists on `defender`.
## Within the window, openness decays over the stamped duration
## (PA_FEINT_OPEN_LINE_DURATION_S, defaulting to FEINT_OPEN_LINE_DURATION_S) as
## openness = (1 - t)^OPEN_LINE_RECOVERY_EASE with t = elapsed/duration. The ease-out (EASE=2.0)
## models the biomechanical recovery: the acute off-line / blade-commitment resolves quickly, so the
## defender re-covers the most vulnerable portion of the line fast, and only the fine re-coverage to
## the exact line lingers — the opening is most exploitable the instant it appears and closes fastest
## at the start of the window (vs. a linear decay that would hold the line uniformly open and
## overstate late-window vulnerability). Monotonic: no guard-position dependence, so it cannot invert
## when the post-hit guard happens to sit on the open line; preserves the 1.0 -> 0.0 endpoints.
## Shared by the offensive AI (CombatAIActionWeights) and the parry model (DefenseChoiceResolver).
static func open_line_openness(defender: Dictionary) -> float:
    if defender.is_empty():
        return 0.0
    var until: float = float(defender.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    if until <= 0.0:
        return 0.0
    var now: float = CombatTiming.now_seconds()
    if now >= until:
        return 0.0
    var open_line: String = str(defender.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return 0.0
    var stored_dur: float = float(defender.get(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S, -1.0))
    var duration: float = stored_dur if stored_dur > 0.0 else CombatConstants.FEINT_OPEN_LINE_DURATION_S
    var t: float = clampf((now - (until - duration)) / duration, 0.0, 1.0)
    return pow(1.0 - t, OPEN_LINE_RECOVERY_EASE)


## XCamp-4: stamp the live open-line window on `combatant`. Writes all four open-line keys together
## so they can never drift apart. Re-opening a line that is already open (a second commitment on the
## same line while the window is live) does NOT shorten or reset the window: if the existing window
## already extends at least as far as the new one, it is preserved — a lighter follow-up must not
## close a heavier opening. Opening a *different* line, or a longer window on the same line,
## re-stamps fresh (openness back to 1.0, decay restarted from now).
static func stamp_open_line(combatant: Dictionary, line: String, duration: float, parry_mult: float) -> void:
    if combatant.is_empty() or line.is_empty() or duration <= 0.0:
        return
    var now: float = CombatTiming.now_seconds()
    var existing_until: float = float(combatant.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    var existing_line: String = str(combatant.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if (
        not existing_line.is_empty()
        and existing_until > now
        and normalize_line(existing_line) == normalize_line(line)
        and existing_until >= now + duration
    ):
        return
    combatant[DataKeys.PA_FEINT_OPEN_LINE] = line
    combatant[DataKeys.PA_FEINT_OPEN_LINE_UNTIL] = now + duration
    combatant[DataKeys.PA_FEINT_OPEN_LINE_DURATION_S] = duration
    combatant[DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT] = parry_mult


## XCamp-4: close the defender's open line when they fully re-cover it. A *full* parry into a line
## the defender was open on is a demonstrated re-coverage: the "you're open on this line" state no
## longer holds, so the window is cleared immediately rather than left to decay passively. (A
## *partial* parry only re-covers the line partway — use shrink_open_line_on_partial_recover.)
## No-op when the defender has no live open line, or it is on a different line (defending elsewhere
## says nothing about this line).
static func close_open_line_on_recover(combatant: Dictionary, defended_line: String) -> void:
    if combatant.is_empty() or defended_line.is_empty():
        return
    var open_line: String = str(combatant.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return
    var until: float = float(combatant.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    if until <= CombatTiming.now_seconds():
        return
    if normalize_line(open_line) != normalize_line(defended_line):
        return
    combatant.erase(DataKeys.PA_FEINT_OPEN_LINE)
    combatant.erase(DataKeys.PA_FEINT_OPEN_LINE_UNTIL)
    combatant.erase(DataKeys.PA_FEINT_OPEN_LINE_DURATION_S)
    combatant.erase(DataKeys.PA_FEINT_OPEN_LINE_PARRY_MULT)


## XCamp-4: partially re-cover the defender's open line. A *partial* parry into a line the defender
## was open on catches the blade partway — the line is re-covered only partially, so the live window
## shrinks to OPEN_LINE_PARTIAL_RECOVER_FRACTION of its remaining time instead of being cleared (as
## a full parry does via close_open_line_on_recover). The stored duration is held, so the eased
## openness (open_line_openness) drops by F^OPEN_LINE_RECOVERY_EASE and the window ends sooner —
## monotonic, never a jump upward. No-op when there is no live open line, or it is on a different
## line (defending elsewhere says nothing about this line).
static func shrink_open_line_on_partial_recover(combatant: Dictionary, defended_line: String) -> void:
    if combatant.is_empty() or defended_line.is_empty():
        return
    var open_line: String = str(combatant.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return
    var now: float = CombatTiming.now_seconds()
    var until: float = float(combatant.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    if until <= now:
        return
    if normalize_line(open_line) != normalize_line(defended_line):
        return
    var remaining: float = until - now
    combatant[DataKeys.PA_FEINT_OPEN_LINE_UNTIL] = now + remaining * OPEN_LINE_PARTIAL_RECOVER_FRACTION


## XCamp-4: true when `combatant` has a live open-line window on `line` (line matches after
## normalization and the stamped window has not yet expired). Used to gate the dodge "deepen"
## path: only a dodge that actually hits the defender's open line re-commits the body off it.
static func has_live_open_line(combatant: Dictionary, line: String) -> bool:
    if combatant.is_empty() or line.is_empty():
        return false
    var open_line: String = str(combatant.get(DataKeys.PA_FEINT_OPEN_LINE, ""))
    if open_line.is_empty():
        return false
    if normalize_line(open_line) != normalize_line(line):
        return false
    var until: float = float(combatant.get(DataKeys.PA_FEINT_OPEN_LINE_UNTIL, -1.0))
    return until > CombatTiming.now_seconds()
