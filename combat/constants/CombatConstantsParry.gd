class_name CombatConstantsParry
extends RefCounted

const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5
const PARRY_STRENGTH_NORM := 100.0
const PARRY_DEFLECT_THRESHOLD := 0.45
const PARRY_TECHNIQUE_VARIANCE := 0.08
const PARRY_V_MIN_FRACTION := 0.2
const PARRY_V_MIN_NEAR_DEFLECT := 0.1
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_BLADE_MOVEMENT_S := 0.13
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0
const PERF_MOD_MIN := 0.55
const COMMITMENT_FRACTION := 0.2
const COMMITMENT_FRACTION_FEINT := 0.35
const RECOVERY_READINESS_EARLY := 0.5
const RECOVERY_READINESS_LATE := 0.85
const OFF_BALANCE_DURATION_S := 0.4
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
const OFF_BALANCE_GAUGE_FILL_MULT := 0.5
## Additive readiness surcharge (seconds) while off-balance, replacing the multiplicative x2 divisor.
## Regaining footing after a heavy exchange is a fixed bounded cost, not a penalty that stacks
## multiplicatively with stamina/armor/perf degradation (that stack created 13s+ readiness gaps).
const OFF_BALANCE_ACTION_READY_EXTRA_S := 1.5
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
const GUARD_AFTER_ATTACK := 0.4
const GUARD_RISE_RATE := 0.6
const PARRY_DODGE_STRENGTH_RATIO := 2.2
const PARRY_BLOCK_MASS_THRESHOLD := 0.75
const PARRY_BLOCK_STR_THRESHOLD := 0.85
const PARRY_REDIRECT_BONUS := 0.18
const PARRY_REDIRECT_SKILL_SCALE := 0.35
const PARRY_REDIRECT_ATTEMPT_RATIO := 3.5
const PARRY_REDIRECT_ATTEMPT_AGILITY_SCALE := 0.6
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
## Reduced alignment threshold for partial-parry bind eligibility (controls, not deflects).
## A control value of 0.55+ already indicates a competent blade engagement — requiring cos45 alignment is overly strict.
## Partial binds at >= 0.60 still require meaningful alignment but allow glancing intercepts to trigger riposte/flurry chains.
const PARRY_PARTIAL_BIND_ALIGNMENT_THRESHOLD := 0.60
## Functional parry bonus: alignments near the partial guard threshold (cos45) are boosted into a more confident regime.
## A 45° intercept is a legitimate HEMA parry line — it deflects rather than fully blocks, but should not be treated as
## marginal. This small alignment bump prevents the decision system from oscillating between parry/dodge for borderline cases.
const PARRY_FUNCTIONAL_ALIGNMENT_BONUS := 0.12
## Glancing floor: alignment at cos(60°). Below this, parry contact geometry is so degraded that even viable capacity
## should not override dodge — the blade cannot meaningfully engage the attack trajectory (near-perpendicular spark).
const PARRY_GLANCING_ALIGNMENT_FLOOR := 0.5
## Reduced alignment threshold for wide-arc weapons (axe, poleaxe) attacking with adjacent guard lines.
## Wide-face weapons can intercept attacks at specific points along their arc even when not perfectly aligned.
const PARRY_WIDE_ARC_DEFLECT_THRESHOLD := 0.25       # cos75 — allows deflect for wide weapons on adjacent lines
## Wide-arc momentum threshold: slightly above main deflect (0.45) because while alignment floor is lower,
## wide-face weapons deliver higher-momentum strikes that require proportionally more capacity to redirect.
const PARRY_WIDE_ARC_MOMENTUM_THRESHOLD := 0.55
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
const PARRY_THRUST_NO_GLANCE := false             ## Thrusts can glancing at high obliquity (>cos60) — point contact slides off blade edge.
const PARRY_THRUST_LINEAR_COMMITMENT_PENALTY := 0.18   ## Extra momentum carry when thrust parry fails (attacker drives through).
const PARRY_THRUST_RECOVERY_MULT := 1.25           ## Thrust deflections cost 25% more recovery — linear force requires full repositioning.
const PARRY_THRUST_BLOCK_ONLY_THRESHOLD := 1.03    ## Thrusts require slightly higher capacity to fully stop (body weight behind thrust).
const PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR := 0.5   ## cos60 — thrust glancing requires this alignment; below this it's a miss, not a glancing parry.
const ARCHETYPES_NEVER_BIND: Array[String] = ["heavy_blunt"]
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
const PARRY_PREFER_DODGE_FULL_THRESHOLD := 0.35
const PARRY_MASS_DISPARITY_BONUS := 0.18
const PARRY_PROACTIVE_WINDOW_FRAC: float = 0.38
## Proactive parries (initiated before ~1/3 of wind-up) are Langen-ort style — meet the blade early with superior control.
## Threshold at 0.38 balances HEMA "early binding" windows (~25-35% of attack commitment) against gameplay feel:
## too low (<0.30) makes proactive parries nearly impossible; too high (>0.45) removes meaningful reactive penalty.
## Reactive parries (>62% wind-up) are late-blocks, weaker and more momentum-dependent.
const PARRY_PROACTIVE_CAPACITY_MULT: float = 1.25
## Proactive parry bonus to control-on-bind (meeting the attack before full commitment).
const PARRY_PROACTIVE_CONTROL_BONUS: float = 0.08
## Reactive late-parry penalty — defender is reacting, not initiating contact.
const PARRY_REACTIVE_CAPACITY_MULT: float = 0.85
const PARRY_LATE_CAPACITY_FLOOR := 0.45
## Minimum parry capacity as a fraction of attack momentum when alignment is at the partial guard threshold (cos45).
## Prevents the multiplicative modifier cascade from reducing parry_c_d below functional levels — even with heavy
## stamina/exhaustion/pain penalties, a well-aligned defender should always have meaningful parry options.
const PARRY_CAPACITY_FLOOR_RATIO := 0.35
const PARRY_CONTACT_MODIFIERS: Dictionary = {"blade": 1.0, "shaft": 0.94, "haft": 0.96}
const PARRY_DEF_VS_ATK_MOD: Dictionary = {
    "AXE": {"stab": 0.85, "cut": 0.92, "blunt": 0.95},
    "DAGGER": {"stab": 0.90, "cut": 0.94, "blunt": 0.75},
    "MACE": {"blunt": 1.08, "stab": 0.92, "cut": 0.92},
    "SPEAR": {"cut": 0.90, "stab": 1.0, "blunt": 0.85}
}
const PARRY_INERTIA_BLEND: float = 0.5
const PARRY_LEVERAGE_LONG_PART_CM: float = 80.0
const PARRY_LEVERAGE_FLOOR: float = 0.72

# --- Bind friction / leverage physics (HEMA waffenfühlen) ---
## When blades contact in bind, blade geometry determines friction and control transfer.
## Wider blade (greater cross-section) has more surface area for binding, increasing friction and leverage.
## Cross-section shape matters: fuller-less blades (with grooves) have less contact area but higher torsional rigidity;
## flat-ground blades have maximum binding contact but lower torsional stiffness. Actual medieval steel weapons typically
## use a combination: fuller in distal third for weight reduction, flat or slightly convex proximal section for bind control.
const BIND_BLADE_WIDTH_FRICTION_MULT: float = 0.12    # per cm of blade width; wider blade = more friction on bind
const BIND_DEFAULT_BLADE_WIDTH_CM: float = 2.0         # baseline contact width for parry/bind (typical sword blade)
const BIND_CROSS_SECTION_RIGIDITY_FLOOR: float = 0.70  # minimum control gain from rigid cross-section (flat > hollow ground)
## Torsional rigidity bonus: fuller-less blades resist twisting during bind, giving better leverage for follow-through.
## A fully-flat blade has max surface friction but lower torsional stiffness; a deeply-fullered blade has less contact
## but resists deflection during bind — trade-off modeled via cross-section rigidty factor.
const BIND_FULLER_RIGIDITY_BONUS: float = 0.15         # bonus control for high-rigidity (less fuller) blades

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


static func parry_edge_deflect_reached(c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool, contact_type: String = "", attack_line: String = "", guard_line: String = "", is_wide_arc: bool = false) -> bool:
    if is_block_parry:
        return false
    # Thrusts can glancing at high obliquity — point contact slides off blade edge when alignment >= cos60.
    # Below the thrust glance floor, parry is physically ineffective (miss); above it, glancing parry applies.
    if contact_type.to_lower().strip_edges() == "stab":
        if alignment < PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR:
            return false  # below glancing floor — no edge deflect possible for thrusts
        # Thrust edge deflect: requires both sufficient capacity AND reasonable alignment (cos45+).
        return alignment >= PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR and c_d >= parry_p_a * PARRY_THRUST_BLOCK_ONLY_THRESHOLD
    # Wide-arc weapon + adjacent lines → reduced threshold deflect.
    # Historical: Fiore's Azza and Le Jeu de la Hache show wide-face weapons can intercept at specific points
    # along their arc even when guard is not perfectly matched to attack line.
    if is_wide_arc and not attack_line.is_empty() and not guard_line.is_empty():
        var adj = CombatGuardLines.LINE_ADJACENTS.get(attack_line, [])
        if guard_line in adj or attack_line in CombatGuardLines.LINE_ADJACENTS.get(guard_line, []):
            return alignment >= PARRY_WIDE_ARC_DEFLECT_THRESHOLD and c_d >= parry_p_a * PARRY_WIDE_ARC_MOMENTUM_THRESHOLD
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


## Wide-arc weapons (axe, poleaxe, mace) have larger arc spans that can intercept attacks at specific points
## along their swing even when the guard line is not perfectly matched — models Fiore's Azza / Le Jeu de la Hache.
static func is_wide_arc_weapon(weapon: Variant) -> bool:
    if weapon == null or not "weapon_type" in weapon:
        return false
    var wt: String = str(weapon.weapon_type).to_upper()
    return wt == "AXE" or wt == "MACE"


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
    var alignment_weight: float = pow(clampf(maxf(alignment, PARRY_CONTROL_ALIGNMENT_FLOOR), 0.0, 1.0), 1.2)

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
        var contact_floor: float = margin_ratio * 0.7 + 0.35  # [0.35, 1.05] when margin_ratio in [0, 1]; raised from 0.25 floor to give partial parry meaningful bind potential (HEMA: any sustained blade contact creates leverage)
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
## Velocity-based parry difficulty: faster attacks are harder to time/read.
const PARRY_VELOCITY_INTENSITY_MIN_THRESHOLD := 0.75  # Only apply velocity penalty at high intensity (real fast strikes)
const PARRY_VELOCITY_DIFFICULTY_REF_M_S := 8.0  # Below this, no penalty (reasonable strike speed)
const PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY := 0.35  # Max capacity reduction at extreme velocities

static func parry_timing_control_bonus(timing_class: String) -> float:
    if timing_class == "proactive":
        return PARRY_PROACTIVE_CONTROL_BONUS
    return 0.0
