class_name CombatConstantsParry
extends RefCounted

const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5
const PARRY_STRENGTH_NORM := 100.0
const PARRY_DEFLECT_THRESHOLD := 1.02
const PARRY_TECHNIQUE_VARIANCE := 0.15
const PARRY_V_MIN_FRACTION := 0.2
const PARRY_V_MIN_NEAR_DEFLECT := 0.1
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_BLADE_MOVEMENT_S := 0.13
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0
const PERF_MOD_MIN := 0.35
const COMMITMENT_FRACTION := 0.2
const COMMITMENT_FRACTION_FEINT := 0.35
const RECOVERY_READINESS_EARLY := 0.5
const RECOVERY_READINESS_LATE := 0.85
const OFF_BALANCE_DURATION_S := 0.4
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
const OFF_BALANCE_GAUGE_FILL_MULT := 0.5
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
const GUARD_AFTER_ATTACK := 0.4
const GUARD_RISE_RATE := 0.6
const PARRY_DODGE_STRENGTH_RATIO := 2.2
const PARRY_BLOCK_MASS_THRESHOLD := 0.75
const PARRY_BLOCK_STR_THRESHOLD := 0.85
const PARRY_REDIRECT_BONUS := 0.18
const PARRY_REDIRECT_SKILL_SCALE := 0.35
const PARRY_REDIRECT_ATTEMPT_RATIO := 2.5
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := 0.5
const PARRY_GLANCING_EXPONENT := 0.7
const PARRY_REDIRECT_THRUST_BONUS := 0.22
const PARRY_REDIRECT_BLUNT_PENALTY := 0.12
const PARRY_CUT_TO_BLUNT_SHIFT := 0.28
const PARRY_PENETRATION_ANGLE_MIN := 0.12
## Minimum penetration angle factor for perfect parry (88% reduction). Scaled from 0.15 to align with clinical
## data: a perfectly-timed parry blocks ~70-85% of strike force, leaving only glancing contact damage.
## Legacy: replaced by cosine obliquity model (AttackResolver.penetration_oblique_angle_factor). Kept for harness
## regression tests. Research confirms grazing angles (>60° from normal) produce near-total deflection.
const PARRY_PENETRATION_ALIGNMENT_SCALE := 1.0
## Minimum alignment for "well-aligned" parry preference (cos(45°) ≈ 0.707). Below this, the guard is too misaligned
## to reliably intercept — blade geometry at >45 cannot redirect momentum in HEMA parrying. The decision logic
## prefers dodge when alignment drops below this floor. Alignments between cos(60)=0.5 and 0.707 are "glancing"
## (parry may be chosen but geometric leak is amplified via pow curve); below 0.5, parry is physically ineffective.
const PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD := 0.707
## Glancing floor: alignment at cos(60°). Below this, parry contact geometry is so degraded that even viable capacity
## should not override dodge — the blade cannot meaningfully engage the attack trajectory (near-perpendicular spark).
const PARRY_GLANCING_ALIGNMENT_FLOOR := 0.5
## Parry damage mapping: ctrl should map directly to damage reduction percentage.
## Models HEMA reality — a parry that achieves ctrl=0.6 (absorbs 60% of attack momentum)
## blocks ~40-60% of incoming damage, not just the current 10-25%.
const PARRY_MAX_DAMAGE_REDUCTION := 0.85  # best case: 85% reduction for perfect parry (ctrl~1.0)
## Unarmed parry: bare hands/forearms deflect far less of a blade's force than a weapon parry (documented spec:
## pre_blunt scales by lerp(0.5, 1, parry_remaining_ratio) — max 50% reduction).
const PARRY_UNARMED_MAX_DAMAGE_REDUCTION := 0.5

const PARRY_BIND_CONTROL_THRESHOLD := 0.55
const PARRY_CONTROL_ALIGNMENT_FLOOR := 0.15
## Thrust-specific parry modifiers — HEMA thrusts are linear commitments with distinct geometry:
## No-glance: thrust contact is point-based; a glancing blade-parry cannot "slide" off the point like it would a cutting edge.
## Linear-commitment penalty: failed thrust parries carry more momentum because the attacker's body is committed forward.
## Distinct recovery: deflecting a thrust requires redirecting linear force, which costs different timing than slashing deflection.
const PARRY_THRUST_NO_GLANCE := true             ## Thrusts cannot be grazed — only full block or full hit.
const PARRY_THRUST_LINEAR_COMMITMENT_PENALTY := 0.18   ## Extra momentum carry when thrust parry fails (attacker drives through).
const PARRY_THRUST_RECOVERY_MULT := 1.25           ## Thrust deflections cost 25% more recovery — linear force requires full repositioning.
const PARRY_THRUST_BLOCK_ONLY_THRESHOLD := 1.08    ## Thrusts require slightly higher capacity to fully stop (body weight behind thrust).
const ARCHETYPES_NEVER_BIND: Array[String] = ["pommel_strike", "heavy_blunt"]
const PARRY_BIND_RIPOSTE_BY_PART_CONTACT: Dictionary = {
    "blade": {"stab": 0.55, "cut": 0.78},
    "shaft": {"stab": 0.55, "cut": 0.78, "blunt": 0.90},
    "haft": {"stab": 0.55, "cut": 0.78}
}
const PARRY_BIND_RIPOSTE_MULT_FALLBACK: float = 0.78
const PARRY_BIND_RIPOSTE_GAUGE_BONUS := float(CombatConstantsStamina.PARRY_BIND_RIPOSTE_GAUGE_BONUS)
const PARRY_LATE_CONTROL_FACTOR := 0.6
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7
const PARRY_THRUST_CONTROL_MULT := 0.85
const PARRY_DESPERATE_DODGE_THRESHOLD := 0.06
const PARRY_PREFER_DODGE_FULL_THRESHOLD := 0.04
const PARRY_MASS_DISPARITY_BONUS := 0.18
const PARRY_PROACTIVE_WINDOW_FRAC: float = 0.35
## Proactive parries (initiated before 35% of wind-up) are Langen-ort style — meet the blade early with superior control.
## Reactive parries (>65% wind-up) are late-blocks, weaker and more momentum-dependent.
const PARRY_PROACTIVE_CAPACITY_MULT: float = 1.20
## Proactive parry bonus to control-on-bind (meeting the attack before full commitment).
const PARRY_PROACTIVE_CONTROL_BONUS: float = 0.08
## Reactive late-parry penalty — defender is reacting, not initiating contact.
const PARRY_REACTIVE_CAPACITY_MULT: float = 0.75
const PARRY_LATE_CAPACITY_FLOOR := 0.40
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.94, "haft": 0.96}
const PARRY_DEF_VS_ATK_MOD: Dictionary = {
    "AXE": {"stab": 0.85, "cut": 0.90, "blunt": 0.92},
    "DAGGER": {"stab": 0.88, "cut": 0.92, "blunt": 0.78},
    "MACE": {"blunt": 1.05, "stab": 0.95, "cut": 0.95},
    "SPEAR": {"cut": 0.92, "stab": 1.0, "blunt": 0.88}
}
const PARRY_INERTIA_BLEND: float = 0.5
const PARRY_LEVERAGE_LONG_PART_CM: float = 80.0
const PARRY_LEVERAGE_FLOOR: float = 0.72

const GUARD_TRANSITION_COST_SCALE := 0.4
const GUARD_TRANSITION_MULT_MAX := 1.35
## Maximum absolute time penalty for guard-line transition during recovery (seconds).
## Models HEMA reality: parrying pushes blade away from rest position; repositioning to a different guard line costs extra time.
## 0–45° delta: minimal cost (~0.05s); 90° delta: moderate (~0.15s); 180° delta: significant (~0.25s max).
const GUARD_TRANSITION_RECOVERY_MAX_S := 0.25
const PREFERRED_PART_BONUS_MULT := 1.5
## AI pick: attack parts off defender mental focus / guard line.
const AI_PICK_OFF_FOCUS_PART_MULT := 1.35
const AI_PICK_ON_FOCUS_LINE_PENALTY_MULT := 0.82
const AI_PICK_NOVICE_ON_FOCUS_LINE_PENALTY_MULT := 0.95
## AI pick: yomi habit line pressure vs counter-line surprise.
const AI_PICK_YOMI_HABIT_LINE_PART_MULT := 1.28
const AI_PICK_YOMI_COUNTER_LINE_PART_MULT := 1.32
const AI_PICK_STAT_BASELINE := 100.0
const AI_PICK_STAT_SPREAD := 60.0
const AI_PICK_NOVICE_OFF_FOCUS_MULT := 1.06
const AI_PICK_NOVICE_YOMI_HABIT_MULT := 1.04
const AI_PICK_NOVICE_YOMI_COUNTER_MULT := 1.06
const AI_PICK_NOVICE_PREFERRED_MULT := 1.15

const FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD := 0.9
const FEINT_PRE_REVEAL_READINESS_MULT := 0.5
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS := 0.55
const PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS := "_harness_feint_dodge_eval_bias"
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE := 1.08
const FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG := 0.88


static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool, contact_type: String = "") -> bool:
    var threshold: float = PARRY_DEFLECT_THRESHOLD
    # Thrusts require slightly higher capacity (body weight behind linear commitment).
    if contact_type.to_lower().strip_edges() == "stab":
        threshold = PARRY_THRUST_BLOCK_ONLY_THRESHOLD
    return is_block_parry and c_d >= parry_p_a * threshold


static func parry_edge_deflect_reached(c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool, contact_type: String = "") -> bool:
    if is_block_parry:
        return false
    # Thrusts have no-glance geometry: point contact cannot slide off blade edge. Only full block or miss.
    if contact_type.to_lower().strip_edges() == "stab":
        return alignment >= PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD and c_d >= parry_p_a * PARRY_THRUST_BLOCK_ONLY_THRESHOLD
    # Edge deflect requires reasonable alignment (cos(45°) ≈ 0.707) and sufficient capacity surplus.
    # Alignment below PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD means the guard is too misaligned — glancing only, no clean deflect.
    return alignment >= PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD and c_d >= parry_p_a * PARRY_DEFLECT_THRESHOLD


static func parry_thrust_linear_commitment_bonus(intensity: float) -> float:
    ## Thrusts carry extra momentum when parried partially — attacker's body drives forward on linear commitment.
    ## Models the biomechanical reality that a thrust commits weight behind the point; failed parries carry more force.
    return 1.0 + PARRY_THRUST_LINEAR_COMMITMENT_PENALTY * intensity


static func parry_thrust_recovery_mult(intensity: float) -> float:
    ## Thrust deflections cost more recovery time — redirecting linear body-weight momentum requires full blade repositioning.
    ## Scales slightly with intensity: heavier thrusts = more follow-through to absorb.
    return 1.0 + (PARRY_THRUST_RECOVERY_MULT - 1.0) * clampf(intensity, 0.3, 1.0) / 0.7


static func parry_bind_control_reached(parry_control: float) -> bool:
    return parry_control >= PARRY_BIND_CONTROL_THRESHOLD


static func iii3_baseline_constants_line() -> String:
    return (
        "III-3 constants: unchanged baseline (PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f)"
        % [PARRY_DEFLECT_THRESHOLD, PARRY_BIND_CONTROL_THRESHOLD]
    )


static func p4d_parry_bind_doc_sync_line() -> String:
    var blade: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
    var shaft: Dictionary = PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
    return (
        "P4d bind sync: blade stab=%.2f cut=%.2f shaft blunt=%.2f fallback=%.2f gauge_bonus=%.0f"
        % [
            float(blade["stab"]),
            float(blade["cut"]),
            float(shaft["blunt"]),
            PARRY_BIND_RIPOSTE_MULT_FALLBACK,
            PARRY_BIND_RIPOSTE_GAUGE_BONUS,
        ]
    )


static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
    if not pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges().is_empty():
        return COMMITMENT_FRACTION_FEINT
    return COMMITMENT_FRACTION


static func stats_factor_agi_perc(agi: float, perc: float) -> float:
    return clampf((agi + perc) / 200.0, 0.5, 1.5)


static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
    return pow(clampf(ratio, 0.0, 1.0), exponent)


static func compute_parry_redirect_mult(
    pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float
) -> float:
    var r_bonus: float = pcfg.get(DataKeys.PCFG_REDIRECT_BONUS, PARRY_REDIRECT_BONUS)
    var r_scale: float = pcfg.get(DataKeys.PCFG_REDIRECT_SKILL_SCALE, PARRY_REDIRECT_SKILL_SCALE)
    var redirect_skill: float = stats_factor_agi_perc(agi, perc)
    var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
    var ct: String = contact_type.to_lower()
    if ct == "stab":
        redirect_mult *= 1.0 + pcfg.get(DataKeys.PCFG_REDIRECT_THRUST_BONUS, PARRY_REDIRECT_THRUST_BONUS)
    elif ct == "blunt":
        redirect_mult *= 1.0 - pcfg.get(DataKeys.PCFG_REDIRECT_BLUNT_PENALTY, PARRY_REDIRECT_BLUNT_PENALTY)
    if not is_block_parry and m_a > 0.001 and m_d < m_a:
        var mass_bonus: float = pcfg.get(DataKeys.PCFG_MASS_DISPARITY_BONUS, PARRY_MASS_DISPARITY_BONUS) * (1.0 - m_d / m_a)
        redirect_mult *= 1.0 + mass_bonus
    return redirect_mult


static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
    return c_d_final / maxf(parry_p_a * PARRY_DEFLECT_THRESHOLD, 0.01)


static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
    return clampf((margin_ratio - 1.0) / 1.0, 0.0, 1.0)


static func parry_control_for_bind_deflect(
    c_d_final: float,
    parry_p_a: float,
    alignment: float,
    parry_readiness: float,
    parry_off_balance: bool,
    late_parry: bool,
    contact_type: String
) -> float:
    var margin_ratio: float = parry_deflect_margin_ratio(c_d_final, parry_p_a)

    # Alignment is the dominant factor — blade contact quality determines bind potential.
    # Uses a power curve so that high alignment (>0.7) strongly favors binding,
    # while low alignment (<0.4) still provides meaningful control (HEMA: any blade contact disrupts structure).
    # PARRY_CONTROL_ALIGNMENT_FLOOR prevents absolute zero — even a "miracle" deflect via arm interpose
    # grants minimal positional advantage because the attacker's momentum was wasted and the defender feel
    # the impact point (Waffenfühlen), per Liechtenauer: every parry is the first half of a counterattack.
    var alignment_weight: float = pow(clampf(maxf(alignment, PARRY_CONTROL_ALIGNMENT_FLOOR), 0.0, 1.0), 1.0)

    # Readiness contributes additively to the margin factor (capacity bonus), not multiplicatively.
    # This prevents readiness from acting as a "brake" — instead it helps achieve bind when
    # alignment is decent but capacity is marginal.
    var effective_margin: float

    if margin_ratio >= 1.0:
        # Deflect or better: margin_factor scales with actual capacity surplus.
        effective_margin = clampf(margin_ratio, 0.5, 2.0) + parry_readiness * 0.4
    else:
        # Partial parry regime (below deflect threshold):
        # HEMA realism — even overwhelmed defenders create blade friction and structural disruption.
        # A parry absorbing 80% of momentum should grant ~2x the control of one absorbing 40%.
        # The contact floor ensures ANY blade contact produces non-zero control (HEMA: Waffenfühlen).
        var contact_floor: float = margin_ratio * 0.7 + 0.25  # [0.25, 0.95] when margin_ratio in [0, 1]
        effective_margin = contact_floor + parry_readiness * 0.5

    var p: float = alignment_weight * (effective_margin / 2.0)

    if late_parry:
        p *= PARRY_LATE_CONTROL_FACTOR
    if parry_off_balance:
        p *= PARRY_OFF_BALANCE_CONTROL_FACTOR

    var ct: String = contact_type.to_lower().strip_edges()
    if ct == "stab":
        p *= PARRY_THRUST_CONTROL_MULT

    # Thrusts produce no glancing outcomes — partial thrust parries transfer more residual momentum.
    # This is reflected in the margin ratio calculation for thrusts: below-deflect thrust parries
    # still carry significant attacker force forward (no "slide off" like cutting edge).
    if ct == "stab" and margin_ratio < 1.0:
        # Thrust partial: reduce the contact_floor so residual momentum is higher
        # (attacker drives through rather than glancing off)
        var thrust_penetration_bonus: float = PARRY_THRUST_LINEAR_COMMITMENT_PENALTY * (1.0 - margin_ratio)
        effective_margin += thrust_penetration_bonus

    return clampf(p, 0.0, 1.0)


## Classify parry timing based on proportion of wind-up elapsed at the moment of defender's response.
## Returns "proactive" if parry initiated before `threshold_frac` of wind-up (early initiative / Langen-ort).
## Returns "reactive" if after `1.0 - threshold_frac` (late reaction). Otherwise returns "mid".
static func classify_parry_timing(parried_at_windup_frac: float, proactive_threshold: float = PARRY_PROACTIVE_WINDOW_FRAC) -> String:
    if parried_at_windup_frac < proactive_threshold:
        return "proactive"
    elif parried_at_windup_frac > (1.0 - proactive_threshold):
        return "reactive"
    else:
        return "mid"


## Get capacity multiplier based on parry timing classification. Proactive = initiative advantage, reactive = late block penalty.
static func parry_timing_capacity_mult(timing_class: String) -> float:
    match timing_class:
        "proactive":
            return PARRY_PROACTIVE_CAPACITY_MULT
        "reactive":
            return PARRY_REACTIVE_CAPACITY_MULT
        _:
            return 1.0


## Get control bonus for proactive parries (meeting the attack early in Langen-ort style).
static func parry_timing_control_bonus(timing_class: String) -> float:
    if timing_class == "proactive":
        return PARRY_PROACTIVE_CONTROL_BONUS
    return 0.0
