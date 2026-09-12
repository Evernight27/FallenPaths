class_name CombatConstantsFormation
extends RefCounted

const FormationMove := preload("res://combat/constants/CombatConstantsFormationMove.gd")

const AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN := 1

const COMBAT_FORMATION_PLUG_MOVE_DEBUG := false

const COMBAT_FORMATION_VACANCY_DEBUG := false

const DIST_BAND_MID_FILE_EQUIV_SLACK := 0.38

const EFF_DIST_LANE_OFFSET_FILE_EQUIV := 0.42

const FLANK_PARRY_MOD := 0.8

const FORMATION_AUTOFILL_REPOSITION_COOLDOWN_S := 0.35

const FORMATION_FLEE_BLOOD_VOLUME_MAX := 55.0

const FORMATION_FLEE_CASUALTY_RATIO_MIN := 0.30

const FORMATION_FLEE_DUEL_ARMED_BLOOD_MAX := 28.0

const FORMATION_FLEE_LINE_COHESION_MAX := 0.42

const FORMATION_FLEE_WINNING_STANDING_RATIO := 1.15

const FORMATION_HIT_CANCEL_INTENSITY := 0.72

const FORMATION_HIT_REACTION_EXTRA_S := 0.38

const FORMATION_KEY_SPEAR_LANE_PROFILE := "spear_lane_profile"

const FORMATION_KEY_STANDING_AT_START := "standing_at_start"

const FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE := 1

const FORMATION_LEAVE_MIN_FRONT_FILL_RATIO := 0.45

const FORMATION_MAX_FRONT_FILES_DEFAULT := 5

## Fill-ratio clamp bounds for the engagement line: the fraction of the front line that remains filled
## after casualties. `l_in` (our side) and `l_out` (opposing side) are each clamped to their own range so a
## partially-broken line still presents a coherent front.
const FORMATION_FILL_IN_MIN := 0.40

const FORMATION_FILL_IN_MAX := 0.92

const FORMATION_FILL_OUT_MIN := 0.28

const FORMATION_FILL_OUT_MAX := 0.88

## Margin used when forcing `l_out` below `l_in`: if our fill is within this of the opposing fill, the
## opposing line is pulled back further to preserve a visible engagement gap.
const FORMATION_FILL_MARGIN := 0.03

## Floor for the opposing fill when it must be kept below our fill.
const FORMATION_FILL_OUT_FLOOR := 0.25

## Gap applied to the opposing fill when it must be kept below our fill.
const FORMATION_FILL_GAP := 0.05

const FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE := 2

const FORMATION_MIN_FRONT_FILL_RATIO := 0.67

const FORMATION_MOVEMENT_MOVE_IDS: Array[String] = FormationMove.FORMATION_MOVEMENT_MOVE_IDS

const FORMATION_PLUG_EFFECTIVENESS_EXPONENT := 2.6

const FORMATION_PLUG_FORWARD_COOLDOWN_S := 3.0

const FORMATION_PLUG_PROXIMITY_WEIGHT := 0.28

const FORMATION_PLUG_RANK0_URGENCY_BONUS := 0.75

const FORMATION_PLUG_REAR_CROSS_FILE_READY_PER_FILE_S := 0.18

const FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS := "depth_polearm_ai_doctrine_mults"

const FORMATION_PRESET_KEY_DOCTRINE := "formation_doctrine"

const FORMATION_PRESET_KEY_DOCTRINE_ALT := "doctrine"

const FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"

const FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"

const FORMATION_RETREAT_BLOOD_VOLUME_MAX := 85.0

const FORMATION_UNIT_COUNT_HARD_CAP := 15

const FORMATION_VACANCY_LATERAL_REVERSE_LOCK_S := 1.2

const FORMATION_VACANCY_MICRO_STEPS_MAX := 24

const FORMATION_VACANCY_RECONCILE_MAX_ROUNDS := 16

const INCURSION_LANE_HEADROOM_FACTOR := 0.88

const LANE_OFFSET_ABS_MAX := 0.5

const LANE_OFFSET_DEFAULT := 0.0

const LANE_STRESS_DENSITY_LOOSE := -0.07

const LANE_STRESS_DENSITY_TIGHT := 0.12

const LANE_STRESS_DUAL_LIVING := 0.42

const LINE_DISCIPLINE_LOOSE := "loose"

const LINE_DISCIPLINE_NORMAL := "normal"

const LINE_DISCIPLINE_STRICT := "strict"

const PARRY_FLANK_EFFECTIVE_FILES_MIN := 2.0

const REACH_SAFETY_FACTOR := 0.8

const REAR_PARRY_MOD := 0.7

const ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN := "flee_casualty_ratio_min"

const ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX := "flee_line_cohesion_max"

const SKIRMISH_ROTATE_OUTNUMBER_FILE_MARGIN := 1

const SPACING_LOOSE := 1.8

const SPACING_NORMAL := 1.2

const SPACING_TIGHT := 0.9

const SPEAR_LANE_PROFILE_AUTO := ""

const SPEAR_LANE_PROFILE_OPEN := "open"

const SPEAR_LANE_PROFILE_RESTRICTED := "restricted"

## Lunge reach extension (m) applied to stab-contact moves: a committed thrust is paired with a forward
## step (Schieben) that extends effective reach. 0.15 m ≈ half a pace — enough to bring a sword from
## out-of-measure (ratio < 1.0) back into measure at typical close spacing.
## Cuts and blunts are rotational and do not step forward; they get no extension.
const LUNGE_REACH_EXTENSION_STAB_M := 0.15

const STRIKE_MEASURE_EFF_DIST_FLOOR := 0.2

const STRIKE_MEASURE_RATIO_MAX := 1.12

const STRIKE_MEASURE_RATIO_MIN := 0.75

const TACTICAL_PENETRATION_DEPTH_MAX := 2

const ZOC_ACCESS_THRESHOLD := 0.55

const ZOC_CASUALTY_PER_BODY := 0.12

const ZOC_FLANK_SUPPORT_TO_FRONT := 0.25

const ZOC_FRONT_SUPPORT_TO_FLANK := 0.35

const ZOC_GEOMETRIC_EXTENT_MIN := 0.78

const ZOC_INCURSION_EXPOSURE_FLANK := 0.9

const ZOC_INCURSION_EXPOSURE_FRONT := 1.0

const ZOC_INCURSION_EXPOSURE_REAR := 0.36

const ZOC_INCURSION_ZONE_PENALTY := 0.38

const ZOC_REAR_SUPPORT_FROM_FRONT := 0.2


static func line_discipline_allows_solo_fall_back(discipline: String) -> bool:
    return str(discipline).strip_edges().to_lower() == LINE_DISCIPLINE_LOOSE


static func line_discipline_posture_extra_deltas(discipline: String) -> Vector2:
    var d: String = str(discipline).strip_edges().to_lower()
    if d == LINE_DISCIPLINE_STRICT:
        return Vector2(0.03, 0.04)
    if d == LINE_DISCIPLINE_LOOSE:
        return Vector2(-0.03, -0.04)
    return Vector2.ZERO


static func normalize_spear_lane_profile(raw: Variant) -> String:
    var s: String = str(raw).strip_edges().to_lower()
    if s.is_empty() or s == "auto" or s == "default":
        return SPEAR_LANE_PROFILE_AUTO
    if s in ["open", "full", "wide", "lanes_open"]:
        return SPEAR_LANE_PROFILE_OPEN
    if s in ["restricted", "over_shoulder", "shoulder", "shoulder_only", "tight_lanes"]:
        return SPEAR_LANE_PROFILE_RESTRICTED
    return SPEAR_LANE_PROFILE_AUTO
