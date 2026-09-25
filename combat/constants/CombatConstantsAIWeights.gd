class_name CombatConstantsAIWeights
extends RefCounted

const FeatureFlags := preload("res://combat/constants/CombatConstantsFeatureFlags.gd")

## AI decision weight multipliers — tuned empirically via F5 soak tests and tier regression harness.
## Each constant is a multiplicative modifier applied to an action's base weight in CombatAIActionWeights.
## Values > 1.0 increase likelihood; < 1.0 decrease it. Range typically 0.15–2.5x.
## Tuning rationale tracked in tools/ci/agent_prompts/ and F5 soak logs (gitignored).

const AI_ATTEMPT_CLOSE_BIND_CLOSE_MULT := 1.28  # Mapped wing out of reach — close bind beats wait/shuffle

const AI_ATTEMPT_CLOSE_LONG_CLOSE_ONLY_MULT := 0.82  # Mapped rank-0 LONG close-only — rotate can compete

const AI_ATTEMPT_CLOSE_SPARSE_LINE_MULT := 1.4  # Sparse post-flee front — close to finish beats shuffle

const AI_FIGHT_FINISH_TRUSTED_CLOSE_MIN_WEIGHT := 0.58

const AI_FLEE_CRITICAL_STAMINA_RATIO := 0.12

const AI_WOUNDED_OPPONENT_WEIGHT_MULT := 2.5  # Target heavily wounded — exploit at up to 2.5x attack weight

const AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT := 0.88

const AI_FLEE_HIGH_CASUALTY_MULT := 1.22

const AI_FLEE_HIGH_COHESION_MULT := 0.35

const AI_FLEE_LOSING_SIDE_MULT := 1.28

const AI_FLEE_LOW_COHESION_MULT := 1.08

const AI_FLEE_ROUTINE_WEIGHT := 0.22

const AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT := (
    FeatureFlags.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
)

const AI_ROTATE_FILE_LINE_PLUG_MIN_WEIGHT := 0.62  # Skirmish shuffle when line has rank-0 holes (III-6 maintain)

const AI_ROTATE_FILE_LONG_CLOSE_ONLY_MULT := 1.35  # LONG close-only (no melee) — shuffle can find angle vs close spam

const AI_ROTATE_FILE_WHEN_ENGAGEMENT_LISTED_MULT := 0.35  # Prefer strikes/close over shuffle when both are listed

const AI_SPARSE_LINE_OFFENSE_MULT := 1.35  # Listed melee on sparse post-flee front — fight over focus shuffle

## Open/guarded line bias: a fencer prefers attacking the open side of the opponent's guard.
## Aligned (on-line) attacks carry a penalty because the defender is already covering that line;
## open-line attacks carry a small bonus. The gap is moderate (not dominant) so that timing,
## stamina, wounds and other factors still compete.
## Research: ~2:1 open-to-guarded split at elite level (in-line attacks remain a viable minority,
## observed floor ~25% of options). Guarded mult 0.70 reproduces the 2:1 split on the SELECTION
## metric (which lines the AI picks): measured open:guarded selection 2.10:1 at .70 vs 1.37:1 with
## no bias. The low in-line *hit* share is correct defense behavior (held lines get parried ~40%),
## not a selection defect — do not chase the hit-share.
## The factor is a pure function of line alignment — it must NOT vary with defender footwork or
## state, or the plain-move weight invariants (feint_list footwork tests) break.
const AI_OPEN_LINE_MULT := 1.40
const AI_GUARDED_LINE_MULT := 0.70

## Line-memory repeat suppression: a line that just FAILED (miss/parry/dodge — the defender read it)
## is briefly de-weighted so the attacker varies under pressure instead of hammering a line already
## demonstrated readable. FLOOR is the penalty at zero age (freshest failure); the factor decays to
## 1.0 (neutral) linearly over DECAY_WINDOW_S on the combat clock. A landed hit clears the line's
## entry (AttackResultApplier), so success does NOT suppress — only reads do.
const AI_LINE_FAIL_PENALTY_FLOOR := 0.75
const AI_LINE_FAIL_DECAY_WINDOW_S := 12.0

## Proactive yomi line variation: a line the attacker has been hitting recently (as observed
## by the defender, in the ~5-observation recent window) is getting readable. De-weight it so
## the AI varies BEFORE the defender's guard drift fully matures, not only after a line fails
## (that reactive case is line_fail_weight_mult). MIN_RECENT is how many times the line must
## appear in the recent window before any penalty applies; FLOOR is the penalty at full share
## (attacker is one-dimensional on that line). Kept mild so a working OPEN line is never
## suppressed in favor of predictability — the open/guarded bias dominates this term.
const AI_YOMI_VARY_MIN_RECENT := 2
const AI_YOMI_VARY_FLOOR := 0.85

## Feint open-line follow-up: when a feint has just opened a line on the target
## (PA_FEINT_OPEN_LINE window still live), boost weight for strikes into that line.
## TOP_MULT is the max boost at full openness (lowest stored parry mult ≈ 0.55).
## Kept at the same top as AI_OPEN_LINE_MULT so it nudges but does not dominate.
const AI_FEINT_OPEN_LINE_FOLLOWUP_TOP_MULT := 1.40

## Feint repeat-read damp: after a feint on a line gets READ (miss/parry/dodge), the defender
## now expects that line. Re-telegraphing the same line is the least realistic choice, so feint
## moves that repeat a just-failed line get an extra de-weight on top of line_fail_m, which
## already applies to all moves on that line. Net effect: after a read feint, commit to a real
## strike or vary the line; if returning to that line, do it honestly rather than re-feinting.
## Applies to feint moves only (honest strikes are not affected). Mild; the floor is the
## penalty at the freshest failure, decaying to 1.0 over AI_LINE_FAIL_DECAY_WINDOW_S.
const AI_FEINT_REPEAT_FAIL_DAMP := 0.60

const AI_STAMINA_DEEP_EXHAUST_MULT := 0.40

const AI_STAMINA_DEEP_EXHAUST_RATIO := 0.05

const AI_STAMINA_ENGAGE_FLOOR_RATIO := 0.20

const AI_STAMINA_ENGAGE_LOW_MULT := 0.85

const AI_STAMINA_EXHAUSTION_DEEP_MULT := 0.40

const AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD := 0.05

const AI_WAIT_MOP_UP_FINISH_MULT := 0.4  # Mop-up winner or last-enemy underdog — finish fight, don't idle

const AI_WAIT_NO_STRIKE_MULT := 0.15  # No hostile strikes listed — prefer flee over endless wait loop

const AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT := 0.45  # Post-flee sparse — wait below close/strike finish

## Floor for stamina_ratio denominator in ai_offense_stamina_weight_mult to prevent division-by-zero when
## stamina_ratio is exactly 0 (e.g. at exact zero-stamina frame). Value 0.001 produces negligible slope change
## compared to a true 0-denominator crash; calibrated so that any ratio > 0 is distinguishable from exhaustion floor.
const AI_STAMINA_RATIO_DENOM_FLOOR: float = 0.001

const COWERING_FLEE_AI_WEIGHT := 1.55

const COWERING_SOLO_FALL_BACK_AI_WEIGHT := 1.5

const DUEL_DISARMED_FLEE_AI_WEIGHT := 0.28

const DUEL_DISARMED_WAIT_AI_WEIGHT := 1.35

const DUEL_DISARMED_YIELD_AI_WEIGHT := 2.2

const SWAP_RANK_AI_CRITICAL_FITNESS := 0.42

const SWAP_RANK_AI_HIGH_WEIGHT := 1.0

const SWAP_RANK_AI_LINE_PLUG_WEIGHT := 0.52  # Rear relief when another file has rank-0 hole (III-6 maintain)

const SWAP_RANK_AI_LOW_WEIGHT := 0.02

const SWAP_RANK_AI_MIN_FITNESS_GAP := 0.20

const SWAP_RANK_AI_URGENT_MIN_GAP := 0.10

## XCamp-6 (gladiator): school-fighter tendency multipliers. A school fighter's hidden tendency
## (aggression / parry_bias / target_part, from OpponentFighterProfile) is stamped onto the
## combatant dict as "school_tendency" by CombatManager.register (meta set by
## CompanyMatch.stamp_bout_enemy). The AI reads it so a scouted fighter actually fights to its
## tendency instead of the generic profile. All multipliers are 1.0 when the key is absent, so
## non-school combat (campaign, arena duel, D001) is bit-identical.
const SCHOOL_TENDENCY_AGGRESSION_MIN := 0.75  # aggression 0.0 (cautious) -> attacks at 0.75x weight
const SCHOOL_TENDENCY_AGGRESSION_MAX := 1.25  # aggression 1.0 (all-in)   -> attacks at 1.25x weight
const SCHOOL_TENDENCY_PARRY_MIN := 0.80       # parry_bias 0.0 -> parry capacity at 0.80x
const SCHOOL_TENDENCY_PARRY_MAX := 1.30       # parry_bias 1.0 -> parry capacity at 1.30x
const SCHOOL_TENDENCY_TARGET_PART_MULT := 1.5  # scouted preferred target part gets 1.5x pick weight


## The tendency dict on a combatant ({} when absent / non-dict).
static func school_tendency_dict(c: Dictionary) -> Dictionary:
    var raw: Variant = c.get("school_tendency", {})
    return raw as Dictionary if raw is Dictionary else {}


## Attack-weight multiplier from a combatant's aggression tendency (1.0 when absent).
static func school_tendency_aggression_mult(c: Dictionary) -> float:
    var d: Dictionary = school_tendency_dict(c)
    if not d.has("aggression"):
        return 1.0
    return lerpf(
        SCHOOL_TENDENCY_AGGRESSION_MIN,
        SCHOOL_TENDENCY_AGGRESSION_MAX,
        clampf(float(d["aggression"]), 0.0, 1.0)
    )


## Parry-capacity multiplier from a combatant's parry_bias tendency (1.0 when absent).
static func school_tendency_parry_mult(c: Dictionary) -> float:
    var d: Dictionary = school_tendency_dict(c)
    if not d.has("parry_bias"):
        return 1.0
    return lerpf(
        SCHOOL_TENDENCY_PARRY_MIN,
        SCHOOL_TENDENCY_PARRY_MAX,
        clampf(float(d["parry_bias"]), 0.0, 1.0)
    )


static func ai_offense_stamina_weight_mult(stamina_ratio: float) -> float:
    if stamina_ratio >= AI_STAMINA_ENGAGE_FLOOR_RATIO:
        return 1.0
    var w: float = AI_STAMINA_ENGAGE_LOW_MULT
    if stamina_ratio <= AI_STAMINA_DEEP_EXHAUST_RATIO:
        w = AI_STAMINA_DEEP_EXHAUST_MULT
    elif stamina_ratio < AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD:
        w = lerpf(
            AI_STAMINA_EXHAUSTION_DEEP_MULT,
            AI_STAMINA_ENGAGE_LOW_MULT,
            stamina_ratio / maxf(AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD, AI_STAMINA_RATIO_DENOM_FLOOR)
        )
    return w


static func iv7b_stamina_engage_doc_sync_line() -> String:
    return (
        "IV-7b engage floor: ratio<%.2f -> offense_mult=%.2f"
        % [AI_STAMINA_ENGAGE_FLOOR_RATIO, AI_STAMINA_ENGAGE_LOW_MULT]
    )
