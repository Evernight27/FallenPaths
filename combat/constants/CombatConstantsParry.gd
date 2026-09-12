class_name CombatConstantsParry
extends RefCounted

const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5
const PARRY_STRENGTH_NORM := 100.0
const PARRY_DEFLECT_THRESHOLD := 0.45
const PARRY_TECHNIQUE_VARIANCE := 0.12
const PARRY_V_MIN_FRACTION := 0.2
const PARRY_V_MIN_NEAR_DEFLECT := 0.1
## Partial-parry follow-through velocity physics (DefenseResolutionHandler).
const PARRY_FOLLOW_THROUGH_VEL_CLAMP := 1.1      ## Follow-through velocity cannot exceed 110% of intent velocity.
const PARRY_V_MIN_FALLBACK_MASS_KG := 0.45      ## Light-weapon fallback strike mass (dagger class) for v_min mass scaling.
const PARRY_V_MIN_REFERENCE_MASS_KG := 2.7      ## Heavy-weapon reference strike mass (spear class) for v_min mass scaling.
const PARRY_V_MIN_MASS_SCALE_THRESHOLD := 0.3   ## Remaining-ratio threshold below which mass-scaled v_min applies.
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_BLADE_MOVEMENT_S := 0.13
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0
const PERF_MOD_MIN := 0.55
const COMMITMENT_FRACTION := 0.2
const COMMITMENT_FRACTION_FEINT := 0.35
const OFF_BALANCE_DURATION_S := 0.4
## Off-balance after a missed attack scales with commitment: a light probe barely disturbs balance,
## a heavy committed swing that overextends leaves the fighter extended and vulnerable.
const MISS_OFF_BALANCE_INTENSITY_SCALE_S := 0.3
## HEMA: a failed feint leaves the attacker more committed than a failed direct strike —
## the deceptive path (extra wind-up, body rotation, blade on a different arc) makes recovery
## slower. This extra time is added to the base off-balance when the missed/deflected move was a feint.
const FEINT_COMMIT_OFF_BALANCE_EXTRA_S := 0.25
## HEMA: a whiffed or parried thrust/lunge commits the body far forward — the center of gravity is
## well past the feet, making recovery harder than for a cutting swing of the same intensity.
## Additive on top of the base off-balance window.
const THRUST_COMMIT_OFF_BALANCE_EXTRA_S := 0.20


const OFF_BALANCE_DEFLECT_DURATION_S := 1.0          ## Base off-balance after parry deflect — extends beyond recovery so the action_ready surcharge fires.
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
## HEMA: an off-balance defender's stepping ability is impaired — a compromised center of gravity
## makes it harder to step away from an incoming strike. Symmetric with the parry-capacity penalty.
const OFF_BALANCE_DODGE_CHANCE_MULT := 0.80
## HEMA: an off-balance attacker's strike is weaker — compromised center of gravity reduces
## transfer of body weight through the weapon. Symmetric with the defensive parry-capacity penalty.
const OFF_BALANCE_ATTACK_DMG_MULT := 0.7
## Additive readiness surcharge (seconds) while off-balance, replacing the multiplicative x2 divisor.
## Regaining footing after a heavy exchange is a fixed bounded cost, not a penalty that stacks
## multiplicatively with stamina/armor/perf degradation (that stack created 13s+ readiness gaps).
const OFF_BALANCE_ACTION_READY_EXTRA_S := 1.5
## Wind-up slow multiplier while off-balance: a fighter who is re-stabilizing (from a hit taken,
## a whiffed over-extended swing, or a parry-deflect) cannot commit to a new strike at full speed.
## Wind-up duration is divided by this value (0.85 → ~18% slower). Distinct from the action-ready
## surcharge (decision delay) and parry capacity reduction (reactive ability): this is the
## *commitment* cost of re-establishing footing before the next swing.
const OFF_BALANCE_WINDUP_SLOW_MULT := 0.85
## Defender who takes a clean hit: impact disrupts bracing/proprioception. Base + intensity-scaled —
## a heavier blow jolts the stance longer. Distinct from the attacker's off-balance (failed attack,
## OFF_BALANCE_DURATION_S) and the parry-deflect window (attacker who got parried,
## OFF_BALANCE_DEFLECT_DURATION_S). Feeds PA_OFF_BALANCE_UNTIL on the defender, which the existing
## OFF_BALANCE_PARRY_CAPACITY_MULT / OFF_BALANCE_DODGE_CHANCE_MULT / OFF_BALANCE_ATTACK_DMG_MULT / angle-variance paths already read.
const HIT_DEFENDER_OFF_BALANCE_BASE_S := 0.5
const HIT_DEFENDER_OFF_BALANCE_INTENSITY_SCALE_S := 0.3
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
const PARRY_BONUS_MULT_MIN := 1.05              ## Marginal parry (low control): 5% capacity boost.
const PARRY_BONUS_MULT_MAX := 1.15              ## Perfect parry (high control): 15% capacity boost.
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
## Exponent for the glancing-velocity factor on dodge/twist: a dodger avoids late in the attack arc and
## retains less incoming velocity than a parry-redirect, so the decay curve is steeper (0.5 vs parry 0.7).
## `glancing_factor(ratio, exp) = ratio^exp` — lower exp → more aggressive velocity loss at partial dodges.
const DODGE_GLANCING_EXPONENT := 0.5
## Agility scaling factor for parry-technique variance: a fighter with agility 130 gets 1.0 - 0.15 = 0.85×
## the base variance range. Higher agility → tighter, more consistent parry timing → less random scatter.
const PARRY_VARIANCE_AGILITY_SCALE := 0.5
## Floor for the alignment used in the parry-variance geometry scale (1/alignment). Prevents division by
## near-zero alignment when the defender's blade is almost perpendicular to the incoming line.
const PARRY_VARIANCE_GEOM_MIN := 0.2
## Ceiling for the parry-variance geometry scale (1/alignment). When alignment is very high (nearly face-on),
## variance is capped so a perfect-angle parry does not produce absurd scatter.
const PARRY_VARIANCE_GEOM_MAX := 2.5
const PARRY_REDIRECT_THRUST_BONUS := 0.22
## Below this fraction of remaining strike energy after a parry, no deflection damage is applied and the
## defender's guard holds cleanly (a well-executed parry absorbs essentially all of the blow).
const PARRY_REMAINING_DEFLECT_THRESHOLD := 0.1
## Above this remaining-energy fraction the parried strike carries enough follow-through to continue as a
## live strike (the parry did not fully neutralize the attack).
const PARRY_FOLLOW_THROUGH_THRESHOLD := 0.3
## Minimum deflection damage before it is applied as a blunt shock to the defender's arm. Suppresses the
## sub-0.5 noise from light parries so that a clean, light parry is effectively free.
const PARRY_DEFLECTION_MIN_DAMAGE := 0.5
## Denominator/ceiling of the deflection-ratio curve: (remaining - PARRY_REMAINING_DEFLECT_THRESHOLD) is
## clamped to [0, this] so that a full un-parried strike maps to a ratio of 1.0.
const PARRY_DEFLECTION_RATIO_MAX := 0.9
const PARRY_REDIRECT_BLUNT_PENALTY := 0.12
const PARRY_CUT_TO_BLUNT_SHIFT := 0.28
const PARRY_PENETRATION_ANGLE_MIN := 0.12
## Minimum penetration angle factor for perfect parry (88% reduction). Tuned so a perfectly-timed parry
## neutralizes most of the incoming strike and leaves only glancing contact damage. Legacy: replaced by the
## cosine obliquity model (AttackResolver.penetration_oblique_angle_factor), which models deflection as a
## function of oblique angle — grazing (shallow) angles deflect far more than square-on hits. Kept here for
## harness regression tests; the value is a design heuristic, not a measured constant.
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
## HEMA bind pressure (Waffenfühlen): opponent pressing the bind reduces defender's parry capacity.
## Linear map: at opponent pressure 0 → 1.0 (no effect), at pressure 1.0 → floor (30% reduction).
## Correctly reads the OPPONENT's pressure, not the defender's (the original was inverted and removed).
const BIND_PRESSURE_DEFENDER_PARRY_CAP_FLOOR: float = 0.70

const PARRY_BIND_CONTROL_THRESHOLD := 0.48
const PARRY_CONTROL_ALIGNMENT_FLOOR := 0.15
## Thrust-specific parry modifiers — HEMA thrusts are linear commitments with distinct geometry:
## Linear-commitment penalty: failed thrust parries carry more momentum because the attacker's body is committed forward.
## Distinct recovery: deflecting a thrust requires redirecting linear force, which costs different timing than slashing deflection.
const PARRY_THRUST_LINEAR_COMMITMENT_PENALTY := 0.18   ## Extra momentum carry when thrust parry fails (attacker drives through).
const PARRY_THRUST_RECOVERY_MULT := 1.25           ## Thrust deflections cost 25% more recovery — linear force requires full repositioning.
const PARRY_DEFLECT_RECOVERY_MULT := 1.20          ## Deflected attacks cost 20% more recovery — blade knocked offline requires extra repositioning.
## Parry-vs-dodge decision tuning (DefenseChoiceResolver).
const PASSIVE_DEFENSE_BIAS := 0.90                 ## Historical combat favors blade defense — parry energy discounted 10% vs dodge.
const PARRY_BELOW_GLANCING_DODGE_BOOST := 1.25     ## Below glancing floor: parry is physically ineffective, dodge gets +25%.
const PARRY_GLANCING_DODGE_BOOST := 1.15           ## Glancing tier: parry needs capacity surplus, dodge gets +15%.
## Twist-dodge after partial parry (DefenseResolutionHandler).
const TWIST_DODGE_MIN_TIME_FACTOR := 0.35          ## Insufficient-react-time twist still has meaningful dodge capacity, not near-zero.
const TWIST_DODGE_PARRY_QUALITY_SLOPE := 0.30      ## Better parry = better dodge position; 30% max reduction at full remaining ratio.
const TWIST_DODGE_PARRY_QUALITY_FLOOR := 0.70      ## Dodge capacity floor when parry quality is worst (full remaining ratio).
## Reach disparity parry penalty (DefenseChoiceResolver._reach_disparity_parry_penalty).
## When the attacker's weapon is longer than the defender's, the defender's parry capacity is penalized.
const REACH_DISPARITY_THRESHOLD_M := 0.30          ## Reach delta below this (meters) is free — no penalty.
const REACH_DISPARITY_PENALTY_SLOPE := 0.30        ## Capacity lost per meter of excess reach delta.
const REACH_DISPARITY_PENALTY_FLOOR := 0.25        ## Parry capacity floor — reach disparity can't reduce capacity below 25%.
## Reach-based parry readiness bonus (DefenseChoiceResolver._reach_parry_readiness_bonus).
## HEMA "Langen-ort": longer weapons extend the blade into the attack trajectory earlier.
const REACH_READINESS_SCALE_PER_M := 0.06          ## 6% readiness bonus per meter of net reach advantage.
const REACH_READINESS_CAP := 0.15                  ## Cap at +/-15% — beyond this, other factors dominate.
const PARRY_THRUST_BLOCK_ONLY_THRESHOLD := 0.88    ## Thrusts can be deflected via blade leverage (strong vs weak) — below 1.0 reflects cross-guard catch.
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
## Committed-weapon (mid-swing) blade-control penalty. A defender already in their own wind-up has their
## blade locked in their own attack arc — they cannot reposition it to meet the incoming strike, so their
## reflexive parry is a fixed late catch with reduced blade control. Applied ON TOP of the late-parry floor
## (which is timing-based and shared with any slow-reaction parry from a waiting defender). A mid-swing
## defender should be strictly weaker than a waiting defender who simply reacted slowly.
const PARRY_MID_SWING_CAPACITY_MULT := 0.80
## Parry recoil mass-scale bounds. A heavier parrying weapon absorbs more of the impact, reducing the
## recoil transmitted to the arm. The recoil scales with the mass ratio (m_a / m_d), clamped to these
## bounds. At equal masses (D001 SWORD mirror) the scale is 1.0 — no behavior change.
const PARRY_RECOIL_MASS_SCALE_MIN := 0.5
const PARRY_RECOIL_MASS_SCALE_MAX := 1.5
## Two-handed bracing. A two-handed grip braces the weapon into the torso/core, creating a longer lever
## and distributing the impact across both arms. This (a) transmits less recoil to any single arm and
## (b) holds parry structure better against a strong blow. SWORD/DAGGER/MACE/AXE are one-handed (neutral
## 1.0); only SPEAR is two-handed, so the D001 SWORD soak is unaffected.
const PARRY_TWO_HANDED_RECOIL_MULT := 0.70
const PARRY_TWO_HANDED_CAPACITY_BONUS := 1.10
## Parry recoil alignment scale. A square-on catch (high alignment) drives the full force of the blow
## straight into the blade and arm; a glancing catch (low alignment) deflects the force along the blade,
## so less reaches the wrist. Recoil scales linearly from GLANCING (least) to SQUARE (most) with alignment.
## At alignment 0.5 the scale is ~1.0 (neutral). The D001 SWORD soak's light parries stay below the recoil
## damage gate, so this does not shift the mandatory signoff.
const PARRY_RECOIL_GLANCING_MULT := 0.85
const PARRY_RECOIL_SQUARE_MULT := 1.15
## Parry recoil blade-flex scale. A flexible (slender) blade flexes on impact, spreading the impulse
## over a longer contact time (lower peak force) so less recoil reaches the arm; a stiff (wide) blade
## transmits a sharper, higher-peak impulse so more recoil. Driven by the blade-flex factor
## (CombatConstantsAttackPath.flex_factor_for_slenderness), which is 1.0 at the SWORD reference
## slenderness — so the D001 SWORD soak is neutral.
const PARRY_RECOIL_FLEX_MULT_MIN := 0.7
const PARRY_RECOIL_FLEX_MULT_MAX := 1.3
## Parry recoil forte/schwach scale. A well-timed parry meets the blade early (near the forte/handle),
## a short lever arm from the hand so less recoil reaches the wrist; a late parry meets it late (near
## the schwach/tip), a long lever arm so more recoil. Driven by parry progress (weapon-independent),
## linear from FORTE (least recoil) to SCHWACH (most recoil). At progress 0.5 the scale is ~1.0 (neutral).
## The D001 SWORD soak's light parries stay below the recoil damage gate, so this does not shift signoff.
const PARRY_RECOIL_FORTE_MULT := 0.90
const PARRY_RECOIL_SCHWACH_MULT := 1.10
## Parry recoil body-mass scale (Newtonian inertia / footing). A heavier, well-rooted defender has more
## inertia, so the same impulse produces less acceleration and less arm shock. Recoil scales as
## reference_mass / body_mass, clamped to [MIN, MAX]. At the reference mass (adult human, 75 kg) the
## scale is 1.0 (neutral). A missing/unknown mass (0.0) yields neutral 1.0 — D001 entities carry no
## species, so the SWORD soak is unaffected.
const PARRY_RECOIL_BODY_MASS_REFERENCE_KG := CombatDesignAnchors.REFERENCE_ADULT_MASS_KG
const PARRY_RECOIL_BODY_MASS_SCALE_MIN := 0.85
const PARRY_RECOIL_BODY_MASS_SCALE_MAX := 1.15
## Minimum parry capacity as a fraction of attack momentum when alignment is at the partial guard threshold (cos45).
## Prevents the multiplicative modifier cascade from reducing parry_c_d below functional levels — even with heavy
## stamina/exhaustion/pain penalties, a well-aligned defender should always have meaningful parry options.
const PARRY_CAPACITY_FLOOR_RATIO := 0.35
## Cascade floor: minimum fraction of raw c_d retained after multiplicative modifiers (alignment, fatigue, etc.).
## Applied in DefenseChoiceResolver before small gameplay modifiers (spacing/reach/fatigue); guards:
## raw c_d must exceed PARRY_CASCADE_FLOOR_RAW_MIN and guard must exceed PARRY_CASCADE_FLOOR_GUARD_MIN.
## Separate from PARRY_CAPACITY_FLOOR_RATIO — that one governs on-time partial viability, this governs the cascade.
const PARRY_CASCADE_CAPACITY_FLOOR := 0.35
const PARRY_CASCADE_FLOOR_RAW_MIN := 2.0  ## Minimum raw c_d for cascade floor to apply — below this, capacity is genuinely low
const PARRY_CASCADE_FLOOR_GUARD_MIN := 0.15  ## Minimum guard for cascade floor — unguarded defenders should not benefit
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
## Bind friction from the parrying weapon's blade width (HEMA waffenfühlen). A wider parrying blade has
## more contact surface -> more friction -> a better catch. Only blade-contact parries benefit; shaft/haft
## parries use leverage, not blade friction, so they return 1.0. The baseline (BIND_DEFAULT_BLADE_WIDTH_CM)
## yields exactly 1.0, so the default sword is unchanged.
static func bind_friction_mult_for_weapon(def_weapon: Variant) -> float:
    if def_weapon == null:
        return 1.0
    if str(def_weapon.get_parry_contact_type()) != "blade":
        return 1.0
    var w: float = float(def_weapon.blade_width)
    return 1.0 + BIND_BLADE_WIDTH_FRICTION_MULT * (w - BIND_DEFAULT_BLADE_WIDTH_CM)


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


static func parry_thrust_recovery_mult(intensity: float) -> float:
    ## Thrust deflections cost more recovery time — redirecting linear body-weight momentum requires full blade repositioning.
    ## Scales slightly with intensity: heavier thrusts = more follow-through to absorb.
    return 1.0 + (PARRY_THRUST_RECOVERY_MULT - 1.0) * clampf(intensity, 0.3, 1.0) / 0.7


static func parry_deflect_recovery_mult(intensity: float) -> float:
    ## Deflected attacks cost extra recovery — blade knocked offline requires extra repositioning vs a clean miss.
    ## Scales with intensity: heavier attacks = more blade displacement = more recovery. At unit intensity the
    ## full PARRY_DEFLECT_RECOVERY_MULT boost applies; at zero intensity a minimum boost (the 0.3 clamp floor)
    ## still applies because even a light deflect displaces the blade.
    var min_mult: float = 1.0 + (PARRY_DEFLECT_RECOVERY_MULT - 1.0) * 0.3 / 0.7
    return lerpf(min_mult, PARRY_DEFLECT_RECOVERY_MULT, clampf(intensity, 0.0, 1.0))


static func off_balance_deflect_duration(intensity: float) -> float:
    ## Off-balance after parry deflect scales with intensity — heavier deflection = more disorientation.
    ## Low intensity: 0.5x base (0.5s). High intensity: 1.0x base (1.0s).
    ## Must exceed typical recovery duration (0.5-1.5s) for the action_ready surcharge to fire.
    return OFF_BALANCE_DEFLECT_DURATION_S * lerpf(0.5, 1.0, clampf(intensity, 0.0, 1.0))


static func miss_off_balance_duration(intensity: float) -> float:
    ## Attacker who whiffs a committed strike stays off-balance longer than a light probe.
    ## Base is the historical OFF_BALANCE_DURATION_S (0.4s) at zero intensity; a full-committed
    ## swing adds up to MISS_OFF_BALANCE_INTENSITY_SCALE_S of extra off-balance time.
    return OFF_BALANCE_DURATION_S + MISS_OFF_BALANCE_INTENSITY_SCALE_S * clampf(intensity, 0.0, 1.0)


static func hit_defender_off_balance_duration(intensity: float) -> float:
    ## Defender who takes a clean hit: impact disrupts bracing/proprioception for a short window.
    ## Base 0.5s + up to 0.3s scaled by blow intensity (0.5s light -> 0.8s heavy). Shorter than the
    ## attacker's parry-deflect window (0.5-1.0s) — landing a hit is less disruptive to the *defender's*
    ## next action than getting parried is to the attacker. Feeds PA_OFF_BALANCE_UNTIL; the existing
    ## OFF_BALANCE_PARRY_CAPACITY_MULT / OFF_BALANCE_DODGE_CHANCE_MULT / OFF_BALANCE_ATTACK_DMG_MULT / angle-variance paths already read it.
    return HIT_DEFENDER_OFF_BALANCE_BASE_S + HIT_DEFENDER_OFF_BALANCE_INTENSITY_SCALE_S * clampf(intensity, 0.0, 1.0)


static func parry_bonus_mult(parry_control: float) -> float:
    ## Post-parry capacity bonus scales with parry quality — a clean blade catch gives a bigger
    ## tempo advantage than a marginal deflect. Linear map from MIN (low control) to MAX (high control).
    var t: float = clampf((parry_control - PARRY_BIND_CONTROL_THRESHOLD) / (1.0 - PARRY_BIND_CONTROL_THRESHOLD), 0.0, 1.0)
    return lerpf(PARRY_BONUS_MULT_MIN, PARRY_BONUS_MULT_MAX, t)


static func parry_recoil_mass_scale(m_a: float, m_d: float) -> float:
    ## Recoil mass-scale: a heavier parrying weapon absorbs more of the impact, reducing the recoil
    ## transmitted to the arm. Scales with the mass ratio (m_a / m_d), clamped to [MIN, MAX].
    ## At equal masses (D001 SWORD mirror) the scale is 1.0 — no behavior change.
    if m_a <= 0.0 or m_d <= 0.0:
        return 1.0
    return clampf(m_a / m_d, PARRY_RECOIL_MASS_SCALE_MIN, PARRY_RECOIL_MASS_SCALE_MAX)


static func parry_two_handed_recoil_mult(is_two_handed: bool) -> float:
    ## A two-handed parry braces the weapon into the torso, distributing the impact across both arms
    ## and the core, so less recoil is transmitted to any single arm. One-handed: neutral 1.0.
    return PARRY_TWO_HANDED_RECOIL_MULT if is_two_handed else 1.0


static func parry_two_handed_capacity_mult(is_two_handed: bool) -> float:
    ## A two-handed parry holds structure better (longer lever + torso bracing), giving a small
    ## capacity bonus. One-handed: neutral 1.0.
    return PARRY_TWO_HANDED_CAPACITY_BONUS if is_two_handed else 1.0


static func parry_recoil_alignment_mult(alignment: float) -> float:
    ## Recoil alignment scale: a square-on catch (alignment 1.0) drives the full force of the blow
    ## straight into the blade and arm, while a glancing catch (alignment 0.0) deflects the force
    ## along the blade so less reaches the wrist. Linear map from GLANCING (least recoil) to
    ## SQUARE (most recoil). At alignment 0.5 the scale is ~1.0 (neutral).
    return lerpf(PARRY_RECOIL_GLANCING_MULT, PARRY_RECOIL_SQUARE_MULT, clampf(alignment, 0.0, 1.0))


static func parry_recoil_flex_mult(flex_factor: float) -> float:
    ## Recoil blade-flex scale: a flexible (slender) blade flexes on impact, spreading the impulse
    ## over a longer contact time (lower peak force) so less recoil reaches the arm; a stiff (wide)
    ## blade transmits a sharper, higher-peak impulse so more recoil. The flex factor (from
    ## CombatConstantsAttackPath.flex_factor_for_slenderness) is 1.0 at the SWORD reference, which
    ## maps to a neutral 1.0 here — the D001 SWORD soak is unaffected.
    var t: float = clampf(
        (flex_factor - CombatConstantsAttackPath.FLEX_FACTOR_MIN)
        / (CombatConstantsAttackPath.FLEX_FACTOR_MAX - CombatConstantsAttackPath.FLEX_FACTOR_MIN),
        0.0, 1.0
    )
    return lerpf(PARRY_RECOIL_FLEX_MULT_MAX, PARRY_RECOIL_FLEX_MULT_MIN, t)


static func parry_recoil_progress_mult(parry_progress: float) -> float:
    ## Recoil forte/schwach scale: a well-timed parry meets the blade early (near the forte/handle),
    ## a short lever arm from the hand so less recoil reaches the wrist; a late parry meets it late
    ## (near the schwach/tip), a long lever arm so more recoil. Linear map from FORTE (least recoil)
    ## to SCHWACH (most recoil) with parry progress. At progress 0.5 the scale is ~1.0 (neutral).
    return lerpf(PARRY_RECOIL_FORTE_MULT, PARRY_RECOIL_SCHWACH_MULT, clampf(parry_progress, 0.0, 1.0))


static func parry_recoil_body_mass_scale(body_mass_kg: float) -> float:
    ## Recoil body-mass scale (Newtonian inertia / footing): a heavier, well-rooted defender has more
    ## inertia, so the same impulse produces less acceleration and less arm shock. Scales as
    ## reference_mass / body_mass, clamped to [MIN, MAX]. At the reference mass (adult human) the
    ## scale is 1.0 (neutral). A missing/unknown mass (0.0) yields neutral 1.0 — D001 entities carry
    ## no species, so the SWORD soak is unaffected.
    if body_mass_kg <= 0.0:
        return 1.0
    return clampf(
        PARRY_RECOIL_BODY_MASS_REFERENCE_KG / body_mass_kg,
        PARRY_RECOIL_BODY_MASS_SCALE_MIN,
        PARRY_RECOIL_BODY_MASS_SCALE_MAX
    )


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
    contact_type: String,
    bind_friction_mult: float = 1.0
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
    var ct: String = contact_type.to_lower().strip_edges()
    var effective_margin: float

    if margin_ratio >= 1.0:
        # Deflect or better: margin_factor scales with actual capacity surplus.
        # Floored at the partial-parry contact floor at unity so control is monotone across the
        # full-stop threshold — a clean deflect never binds worse than the near-miss that just fell short.
        effective_margin = maxf(minf(margin_ratio, 2.0), _partial_parry_contact_floor(1.0)) + parry_readiness * 0.4
    else:
        # Partial parry regime (below deflect threshold):
        # HEMA realism — even overwhelmed defenders create blade friction and structural disruption.
        # A parry absorbing 80% of momentum should grant ~2x the control of one absorbing 40%.
        # The contact floor ensures ANY blade contact produces non-zero control (HEMA: Waffenfühlen).
        var contact_floor: float = _partial_parry_contact_floor(margin_ratio)
        # Thrusts produce no glancing outcomes — a driven-through thrust carries the attacker's residual
        # momentum forward instead of converting to a clean bind, so below-deflect thrust parries grant
        # the defender LESS blade control. Mirrors DefenseResolutionHandler's damage-side reduction via
        # parry_thrust_commitment_penalty: both sides agree a partial thrust parry keeps momentum high.
        if ct == "stab":
            contact_floor -= PARRY_THRUST_LINEAR_COMMITMENT_PENALTY * (1.0 - margin_ratio)
        effective_margin = contact_floor + parry_readiness * 0.5

    var p: float = alignment_weight * (effective_margin / 2.0)

    if late_parry:
        p *= PARRY_LATE_CONTROL_FACTOR
    if parry_off_balance:
        p *= PARRY_OFF_BALANCE_CONTROL_FACTOR

    if ct == "stab":
        p *= PARRY_THRUST_CONTROL_MULT

    # Blade-width friction (HEMA waffenfühlen): a wider parrying blade grips the bind better. Applied
    # before the clamp so a narrow blade can slip below the bind threshold (ctrl < 0.48).
    p *= bind_friction_mult

    return clampf(p, 0.0, 1.0)


## Partial-parry contact floor: any blade contact creates non-zero bind potential (HEMA: Waffenfühlen).
## At unity margin the floor is 0.7*1 + 0.42 = 1.12 — the deflect branch must never start below this
## so control stays monotone across the full-stop threshold.
static func _partial_parry_contact_floor(margin_ratio: float) -> float:
    return margin_ratio * 0.7 + 0.42


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
const PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY := 0.25  # Max capacity reduction — fast attacks harder but not devastating for trained fencers

static func parry_timing_control_bonus(timing_class: String) -> float:
    if timing_class == "proactive":
        return PARRY_PROACTIVE_CONTROL_BONUS
    return 0.0
