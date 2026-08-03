class_name CombatConstantsAIWeights
extends RefCounted

const FeatureFlags := preload("res://combat/constants/CombatConstantsFeatureFlags.gd")

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

const AI_STAMINA_DEEP_EXHAUST_MULT := 0.40

const AI_STAMINA_DEEP_EXHAUST_RATIO := 0.05

const AI_STAMINA_ENGAGE_FLOOR_RATIO := 0.20

const AI_STAMINA_ENGAGE_LOW_MULT := 0.85

const AI_STAMINA_EXHAUSTION_DEEP_MULT := 0.40

const AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD := 0.05

const AI_WAIT_MOP_UP_FINISH_MULT := 0.4  # Mop-up winner or last-enemy underdog — finish fight, don't idle

const AI_WAIT_NO_STRIKE_MULT := 0.15  # No hostile strikes listed — prefer flee over endless wait loop

const AI_WAIT_SPARSE_ENGAGEMENT_LISTED_MULT := 0.45  # Post-flee sparse — wait below close/strike finish

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
            stamina_ratio / maxf(AI_STAMINA_EXHAUSTION_DEEP_THRESHOLD, 0.001)
        )
    return w


static func iv7b_stamina_engage_doc_sync_line() -> String:
    return (
        "IV-7b engage floor: ratio<%.2f -> offense_mult=%.2f"
        % [AI_STAMINA_ENGAGE_FLOOR_RATIO, AI_STAMINA_ENGAGE_LOW_MULT]
    )
