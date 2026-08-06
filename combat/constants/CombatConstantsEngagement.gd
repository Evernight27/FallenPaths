class_name CombatConstantsEngagement
extends RefCounted

const AI_ATTRITION_LOW_STANDING_MAX := 2

const COHESION_BASE_FLOOR := 0.35

const COHESION_FILL_SCALE := 0.65

const COHESION_LANE_STRESS_WEIGHT := 0.45

## Minimum active combatants per side before engagement enters FORMATION mode (vs duel or skirmish).
## Set to 4: below this, encounters are too small for formation tactics (rank/file depth matters); at 4+,
## squad-level maneuvers like plug gaps, staggered ranks, and flank pressure become meaningful.
const ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE := 4

const ENGAGEMENT_MODE_CODE_DUEL := 0

const ENGAGEMENT_MODE_CODE_FORMATION := 2

const ENGAGEMENT_MODE_CODE_SKIRMISH := 1

const ENGAGEMENT_MODE_DUEL := "duel"

const ENGAGEMENT_MODE_FORMATION := "formation"

const ENGAGEMENT_MODE_SKIRMISH := "skirmish"

const ENGAGEMENT_POSTURE_DUEL := "duel"

const ENGAGEMENT_POSTURE_LINE := "line"

const ENGAGEMENT_POSTURE_OPEN := "open"

const ENGAGEMENT_ROLE_LINE := "line"

const LINE_COHESION_POSTURE_ENTER_LINE_MIN := 0.62

const LINE_COHESION_POSTURE_LEAVE_LINE_BELOW := 0.50

const MENTAL_STACK_L9_VULNERABILITY_BLOOD_THRESHOLD := 60.0

const MORALE_COHESION_FACTOR_MIN := 0.15

const POSTURE_ASYMMETRY_COH_COUPLE_STRENGTH := 0.12
