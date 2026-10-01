class_name CombatParryMath
extends RefCounted

## Parry computation math, extracted from **`CombatConstantsParry`** (pure code-motion split).
## All tuning constants referenced via `CombatConstantsParry.` by class_name (no preload).


## Bind friction from the parrying weapon's blade width (HEMA waffenfühlen). A wider parrying blade has
## more contact surface -> more friction -> a better catch. Only blade-contact parries benefit; shaft/haft
## parries use leverage, not blade friction, so they return 1.0. The baseline
## (CombatConstantsParry.BIND_DEFAULT_BLADE_WIDTH_CM) yields exactly 1.0, so the default sword is unchanged.
static func bind_friction_mult_for_weapon(def_weapon: Variant) -> float:
    if def_weapon == null:
        return 1.0
    if str(def_weapon.get_parry_contact_type()) != "blade":
        return 1.0
    var w: float = float(def_weapon.blade_width)
    return (
        1.0
        + CombatConstantsParry.BIND_BLADE_WIDTH_FRICTION_MULT * (w - CombatConstantsParry.BIND_DEFAULT_BLADE_WIDTH_CM)
    )


static func parry_full_stop_reached(
    c_d: float, parry_p_a: float, is_block_parry: bool, contact_type: String = ""
) -> bool:
    var threshold: float = CombatConstantsParry.PARRY_DEFLECT_THRESHOLD
    # Thrusts require slightly higher capacity (body weight behind linear commitment).
    if contact_type.to_lower().strip_edges() == "stab":
        threshold = CombatConstantsParry.PARRY_THRUST_BLOCK_ONLY_THRESHOLD
    return is_block_parry and c_d >= parry_p_a * threshold


static func parry_edge_deflect_reached(
    c_d: float,
    parry_p_a: float,
    alignment: float,
    is_block_parry: bool,
    contact_type: String = "",
    attack_line: String = "",
    guard_line: String = "",
    is_wide_arc: bool = false
) -> bool:
    if is_block_parry:
        return false
    # Thrusts can glancing at high obliquity — point contact slides off blade edge when alignment >= cos60.
    # Below the thrust glance floor, parry is physically ineffective (miss); above it, glancing parry applies.
    if contact_type.to_lower().strip_edges() == "stab":
        if alignment < CombatConstantsParry.PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR:
            return false  # below glancing floor — no edge deflect possible for thrusts
        # Thrust edge deflect: requires both sufficient capacity AND reasonable alignment (cos45+).
        return (
            alignment >= CombatConstantsParry.PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR
            and c_d >= parry_p_a * CombatConstantsParry.PARRY_THRUST_BLOCK_ONLY_THRESHOLD
        )
    # Wide-arc weapon + adjacent lines → reduced threshold deflect.
    # Historical: Fiore's Azza and Le Jeu de la Hache show wide-face weapons can intercept at specific points
    # along their arc even when guard is not perfectly matched to attack line.
    if is_wide_arc and not attack_line.is_empty() and not guard_line.is_empty():
        var adj = CombatGuardLines.LINE_ADJACENTS.get(attack_line, [])
        if guard_line in adj or attack_line in CombatGuardLines.LINE_ADJACENTS.get(guard_line, []):
            return (
                alignment >= CombatConstantsParry.PARRY_WIDE_ARC_DEFLECT_THRESHOLD
                and c_d >= parry_p_a * CombatConstantsParry.PARRY_WIDE_ARC_MOMENTUM_THRESHOLD
            )
    # Edge deflect requires reasonable alignment (cos(45°) ≈ 0.707) and sufficient capacity surplus.
    # Alignment below CombatConstantsParry.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD means the guard is too
    # misaligned — glancing only, no clean deflect.
    return (
        alignment >= CombatConstantsParry.PARRY_PARTIAL_GUARD_ALIGNMENT_THRESHOLD
        and c_d >= parry_p_a * CombatConstantsParry.PARRY_DEFLECT_THRESHOLD
    )


static func parry_thrust_recovery_mult(intensity: float) -> float:
    ## Thrust deflections cost more recovery time — redirecting linear body-weight momentum requires full blade
    ## repositioning.
    ## Scales slightly with intensity: heavier thrusts = more follow-through to absorb.
    return 1.0 + (CombatConstantsParry.PARRY_THRUST_RECOVERY_MULT - 1.0) * clampf(intensity, 0.3, 1.0) / 0.7


static func parry_deflect_recovery_mult(intensity: float) -> float:
    ## Deflected attacks cost extra recovery — blade knocked offline requires extra repositioning vs a clean miss.
    ## Scales with intensity: heavier attacks = more blade displacement = more recovery. At unit intensity the
    ## full CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT boost applies; at zero intensity a minimum boost
    ## (the 0.3 clamp floor) still applies because even a light deflect displaces the blade.
    var min_mult: float = 1.0 + (CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT - 1.0) * 0.3 / 0.7
    return lerpf(min_mult, CombatConstantsParry.PARRY_DEFLECT_RECOVERY_MULT, clampf(intensity, 0.0, 1.0))


static func off_balance_deflect_duration(intensity: float) -> float:
    ## Off-balance after parry deflect scales with intensity — heavier deflection = more disorientation.
    ## Low intensity: 0.5x base (0.5s). High intensity: 1.0x base (1.0s).
    ## Must exceed typical recovery duration (0.5-1.5s) for the action_ready surcharge to fire.
    return CombatConstantsParry.OFF_BALANCE_DEFLECT_DURATION_S * lerpf(0.5, 1.0, clampf(intensity, 0.0, 1.0))


## Formation-move settling window: a fighter who just moved in the line is mid-replant and less braced
## for a beat. Scaled by move kind (rotate > fall-back > swap/drag). Plug-forward is a deliberate
## fast advance that gains tempo, so it settles at 0.0 (no penalty). Unknown move kinds default to
## the base (treated like a rank swap). D001-neutral: no formation moves in the SWORD soak.


static func formation_settle_off_balance_duration(move_kind: String) -> float:
    match move_kind:
        CombatConstants.MOVE_ID_PLUG_FORWARD:
            return 0.0
        CombatConstants.MOVE_ID_ROTATE_FILE:
            return (
                CombatConstantsParry.FORMATION_SETTLE_OFF_BALANCE_BASE_S
                * CombatConstantsParry.FORMATION_SETTLE_ROTATE_SCALE
            )
        CombatConstants.MOVE_ID_FALL_BACK, CombatConstants.FORMATION_MOVE_KIND_FALL_BACK_PAIR:
            return (
                CombatConstantsParry.FORMATION_SETTLE_OFF_BALANCE_BASE_S
                * CombatConstantsParry.FORMATION_SETTLE_FALL_BACK_SCALE
            )
        _:
            return CombatConstantsParry.FORMATION_SETTLE_OFF_BALANCE_BASE_S


## Cower re-plant window: a fighter getting back to his feet after cowering is not instantly braced.
## Base is the arms-only re-plant. When the legs are still weakened (functionality below the
## compromised threshold), the re-plant takes longer — a leg-collapsed fighter must re-weight through
## a bad knee before the guard is trustworthy. D001-neutral: D001 never enters cower.


static func cower_replant_off_balance_duration(leg_functionality: float) -> float:
    if leg_functionality < CombatConstantsParry.COWER_REPLANT_LEGS_COMPROMISED_THRESHOLD:
        return CombatConstantsParry.COWER_REPLANT_OFF_BALANCE_BASE_S * CombatConstantsParry.COWER_REPLANT_LEGS_SCALE
    return CombatConstantsParry.COWER_REPLANT_OFF_BALANCE_BASE_S


static func miss_off_balance_duration(intensity: float) -> float:
    ## Attacker who whiffs a committed strike stays off-balance longer than a light probe.
    ## Base is the historical CombatConstantsParry.OFF_BALANCE_DURATION_S (0.4s) at zero intensity; a full-committed
    ## swing adds up to CombatConstantsParry.MISS_OFF_BALANCE_INTENSITY_SCALE_S of extra off-balance time.
    return (
        CombatConstantsParry.OFF_BALANCE_DURATION_S
        + CombatConstantsParry.MISS_OFF_BALANCE_INTENSITY_SCALE_S * clampf(intensity, 0.0, 1.0)
    )


static func dodge_off_balance_duration(intensity: float) -> float:
    ## Defender who lands a clean full dodge: they moved off their base of support, so re-centering
    ## takes a short bounded window. Base 0.25s (below the whiff base: a braced reactive dodge
    ## re-centers faster than a committed over-extension) + up to 0.20s scaled by the incoming
    ## strike's intensity (harder blow = bigger evasive motion).
    return (
        CombatConstantsParry.DODGE_OFF_BALANCE_BASE_S
        + CombatConstantsParry.DODGE_OFF_BALANCE_INTENSITY_SCALE_S * clampf(intensity, 0.0, 1.0)
    )


static func hit_defender_off_balance_duration(intensity: float) -> float:
    ## Defender who takes a clean hit: impact disrupts bracing/proprioception for a short window.
    ## Base 0.5s + up to 0.3s scaled by blow intensity (0.5s light -> 0.8s heavy). Shorter than the
    ## attacker's parry-deflect window (0.5-1.0s) — landing a hit is less disruptive to the *defender's*
    ## next action than getting parried is to the attacker. Feeds PA_OFF_BALANCE_UNTIL; the existing
    ## OFF_BALANCE_PARRY_CAPACITY_MULT / OFF_BALANCE_DODGE_CHANCE_MULT / OFF_BALANCE_ATTACK_DMG_MULT / angle-variance
    ## paths already read it.
    return (
        CombatConstantsParry.HIT_DEFENDER_OFF_BALANCE_BASE_S
        + CombatConstantsParry.HIT_DEFENDER_OFF_BALANCE_INTENSITY_SCALE_S * clampf(intensity, 0.0, 1.0)
    )


## Strike-location off-balance multiplier: where the hit lands on the defender scales how long their
## footing is disrupted, independent of intensity. Head (vestibular startle) and legs (striking the
## base of support) disrupt balance most; a torso hit is the neutral baseline; an arm hit disturbs
## balance least (an arm is not a balance-critical region). Returns 1.0 for unknown/empty parts so the
## window degrades gracefully when no part is recorded.


static func hit_part_off_balance_mult(part: String) -> float:
    match part:
        "head":
            return CombatConstantsParry.HIT_OFF_BALANCE_PART_HEAD_MULT
        "left_leg", "right_leg":
            return CombatConstantsParry.HIT_OFF_BALANCE_PART_LEG_MULT
        "left_arm", "right_arm":
            return CombatConstantsParry.HIT_OFF_BALANCE_PART_ARM_MULT
    return 1.0


## Off-balance outcome multiplier: how much of the defender's off-balance window a landed strike
## should actually consume, by result outcome. A clean "hit" disrupts at full strength (1.0). A
## "glancing" hit (blade grazes, tissue well below the glancing floor) only half-disrupts
## (CombatConstantsParry.HIT_GLANCING_OFF_BALANCE_MULT). A "negligible" hit (damage floored to ~0, the swing never
## really connected) disrupts nothing (0.0). Multiplied onto the intensity × part × recovery
## off-balance window in the hit path. Unknown/empty outcomes degrade to 1.0 (treat as clean hit)
## so a missing outcome key can never silently zero out a legitimate stagger.


static func hit_off_balance_outcome_mult(outcome: String) -> float:
    match outcome:
        "glancing":
            return CombatConstantsParry.HIT_GLANCING_OFF_BALANCE_MULT
        "negligible":
            return 0.0
    return 1.0


## Off-balance impulse multiplier from the strike's kinetic energy (J): a balance disruption scales
## with the impulse delivered, not just commitment. Maps the combat-realistic band (35-95 J) to
## [CombatConstantsParry.HIT_STAGGER_IMPULSE_MIN_MULT, CombatConstantsParry.HIT_STAGGER_IMPULSE_MAX_MULT]
## with 1.0 at the mid-band, so a typical sword strike is D001-neutral. No KE data (ke_j <= 0) stays neutral 1.0.


static func hit_impulse_stagger_mult(ke_j: float) -> float:
    if ke_j <= 0.0:
        return 1.0
    var t: float = clampf(
        (
            (ke_j - CombatDesignAnchors.COMBAT_REALISTIC_KE_J_MIN)
            / (CombatDesignAnchors.COMBAT_REALISTIC_KE_J_MAX - CombatDesignAnchors.COMBAT_REALISTIC_KE_J_MIN)
        ),
        0.0,
        1.0
    )
    return lerpf(
        CombatConstantsParry.HIT_STAGGER_IMPULSE_MIN_MULT, CombatConstantsParry.HIT_STAGGER_IMPULSE_MAX_MULT, t
    )


## Head-impact startle floor: minimum off-balance window (s) for a clean head hit carrying real
## impact energy, or 0.0 when not applicable (not a head, not a clean hit, or below the KE
## threshold). The startle reflex is involuntary, so the caller applies this as a hard floor AFTER
## agility/recovery scaling — a fast fighter cannot undercut it.


static func hit_startle_min_s(part: String, outcome: String, ke_j: float) -> float:
    if part != "head" or outcome != "hit" or ke_j < CombatConstantsParry.STARTLE_HEAD_IMPACT_KE_MIN_J:
        return 0.0
    return CombatConstantsParry.STARTLE_HEAD_IMPACT_MIN_S


## Off-balance orientation multiplier: a hit that meets the defender's flank or rear disrupts
## balance more than a frontal hit. A frontal blow meets the sagittal brace (feet set deep along
## the attack line); a lateral blow crosses the support base, where bipedal stabilization is
## weakest; a rear blow arrives with no visual anticipation or counter-stiffening. Driven by the
## defender's stamped PA_ENGAGEMENT_ANGLE ("front" / "flank" / "rear"). Unknown/empty values
## degrade to 1.0 so a missing stamp never fabricates a penalty.


static func hit_orientation_stagger_mult(angle: String) -> float:
    match angle:
        "flank":
            return CombatConstantsParry.HIT_ORIENTATION_FLANK_MULT
        "rear":
            return CombatConstantsParry.HIT_ORIENTATION_REAR_MULT
    return 1.0


## Facing-turn window duration: how long the lingering turned-posture lasts after a flank or rear
## strike resolves. "rear" takes longer to recover from (no anticipation) than "flank". Any other
## angle (including "front", "", or unknown) returns 0.0 so D001 front-on duels are unaffected.


static func facing_turn_window_s(angle: String) -> float:
    match angle:
        "flank":
            return CombatConstantsParry.FACING_TURN_WINDOW_FLANK_S
        "rear":
            return CombatConstantsParry.FACING_TURN_WINDOW_REAR_S
    return 0.0


## Off-balance armor-inertia multiplier for a defender taking a hit: heavy armor braces the body
## (distributed mass raises effective inertia), so a given impact produces less stagger. 1.0 with
## no armor, down to (1 - CombatConstantsParry.HIT_ARMOR_INERTIA_REDUCTION) at full armor.
## `armor_ratio` clamps to [0,1].


static func hit_armor_inertia_mult(armor_ratio: float) -> float:
    return lerpf(1.0, 1.0 - CombatConstantsParry.HIT_ARMOR_INERTIA_REDUCTION, clampf(armor_ratio, 0.0, 1.0))


## Off-balance armor-inertia multiplier for an attacker whiffing: heavy armor adds swing mass, so
## the follow-through takes longer to arrest and the fighter stays off-balance longer. 1.0 with no
## armor, up to (1 + CombatConstantsParry.WHIFF_ARMOR_INERTIA_EXTENSION) at full armor. `armor_ratio` clamps to [0,1].


static func whiff_armor_inertia_mult(armor_ratio: float) -> float:
    return lerpf(1.0, 1.0 + CombatConstantsParry.WHIFF_ARMOR_INERTIA_EXTENSION, clampf(armor_ratio, 0.0, 1.0))


## Off-balance recovery multiplier from leg functionality and agility. Multiply an off-balance
## duration by this to reflect how fast the fighter re-establishes footing. Pure in (leg, agi) so
## it is callable from constants without entity access. Returns a factor: <1.0 re-roots faster,
## >1.0 lingers off-balance longer. Neutral 1.0 at healthy leg (1.0) + default agility, so the
## D001 SWORD soak (no species, default stats) is unaffected.


static func off_balance_recovery_mult(leg: float, agi: float) -> float:
    var leg_term: float = 1.0 + (1.0 - clampf(leg, 0.0, 1.0)) * CombatConstantsParry.OFF_BALANCE_RECOVERY_LEG_RANGE
    var agi_term: float = clampf(
        (
            1.0
            - (
                (agi - float(CombatConstantsParry.Misc.DEFAULT_STAT_VALUE))
                * CombatConstantsParry.OFF_BALANCE_RECOVERY_AGI_PER_POINT
            )
        ),
        CombatConstantsParry.OFF_BALANCE_RECOVERY_AGI_MIN,
        CombatConstantsParry.OFF_BALANCE_RECOVERY_AGI_MAX
    )
    return clampf(
        leg_term * agi_term,
        CombatConstantsParry.OFF_BALANCE_RECOVERY_MIN,
        CombatConstantsParry.OFF_BALANCE_RECOVERY_MAX
    )


## Leg-wound parry-brace multiplier: a compromised base weakens the bracing platform that a parry
## relies on to absorb the incoming impulse. 1.0 at full leg functionality, lerping down to
## CombatConstantsParry.LEG_STANCE_PARRY_MULT_MIN as the base fails. Pure in `leg` so it is callable from constants
## without entity access. D001-neutral at leg == 1.0.


static func leg_stance_parry_mult(leg: float) -> float:
    return lerpf(1.0, CombatConstantsParry.LEG_STANCE_PARRY_MULT_MIN, 1.0 - clampf(leg, 0.0, 1.0))


## Torso-wound parry-brace multiplier: a parry is braced through the core, not just the legs — a
## compromised chest (ribs/sternum/core muscle) weakens the central brace that absorbs the incoming
## blow. Symmetric complement to leg_stance_parry_mult (the *base* axis); this is the *core* axis.
## 1.0 at a healthy core, lerping down to CombatConstantsParry.TORSO_STANCE_PARRY_MULT_MIN as the core fails. Pure in
## `torso` so it is callable from constants without entity access. D001-neutral at torso == 1.0.
## Distinct from arm limb-impairment (weapon handling) and from arm-wound grip (blade delivery speed).


static func torso_stance_parry_mult(torso: float) -> float:
    return lerpf(1.0, CombatConstantsParry.TORSO_STANCE_PARRY_MULT_MIN, 1.0 - clampf(torso, 0.0, 1.0))


## Base-of-support susceptibility multiplier: a compromised leg narrows the support base and weakens
## the corrective push, so an incoming impact tips the fighter more easily. Multiplied onto the
## off-balance window in hit_off_balance_window. Distinct from off_balance_recovery_mult (re-rooting
## speed) — a wounded fighter is BOTH more easily knocked off-balance AND slower to re-center.
## Neutral 1.0 at full leg functionality; up to +35% window at total leg loss. D001-neutral.


static func hit_off_balance_leg_susceptibility_mult(leg: float) -> float:
    return 1.0 + CombatConstantsParry.HIT_OFF_BALANCE_LEG_SUSCEPTIBILITY_RANGE * (1.0 - clampf(leg, 0.0, 1.0))


## Guard-transition off-balance multiplier: a staggered defender re-centers their blade more slowly.
## Multiplied onto the computed guard-transition cost. `depth` is off-balance depth (0.0 settled,
## 1.0 fully staggered). Returns 1.0 + depth * SCALE, clamped to [1.0, 1.0 + SCALE]. D001-neutral:
## a settled fighter (depth 0) gets exactly 1.0.


static func guard_transition_off_balance_mult(depth: float) -> float:
    return 1.0 + clampf(depth, 0.0, 1.0) * CombatConstantsParry.GUARD_TRANSITION_OFF_BALANCE_SCALE


## Guard-transition fatigue multiplier: sustained muscle fatigue in the striking limb slows blade
## re-centering after a parry. Multiplied onto the computed guard-transition cost alongside the
## off-balance term. `fatigue` is the dominant striking-limb fatigue (0.0 fresh, 1.0 exhausted).
## Returns 1.0 + fatigue * SCALE, clamped to [1.0, 1.0 + SCALE]. D001-neutral at fatigue 0.0.


static func guard_transition_fatigue_mult(fatigue: float) -> float:
    return 1.0 + clampf(fatigue, 0.0, 1.0) * CombatConstantsParry.GUARD_TRANSITION_FATIGUE_SCALE


## Arm-wound wind-up slowdown: a compromised striking arm accelerates the blade more slowly.
## `grip` is the arm-wound function factor (1.0 healthy, down to ARM_WOUND_GRIP_FLOOR at a full
## localized wound). Returns a multiplier >= 1.0 to extend wind-up duration. D001-neutral at grip 1.0.


static func arm_wound_windup_slow_mult(grip: float) -> float:
    return 1.0 + CombatConstantsParry.ARM_WINDUP_WOUND_SLOW_RANGE * (1.0 - clampf(grip, 0.0, 1.0))


## Close-advance lead-leg drive multiplier (Tier 2.1 v2): a wounded lead leg weakens the committed
## forward lunge that closes distance. `leg` is the lead-leg functionality (1.0 healthy, lower when
## the lead leg is wounded/destroyed). Lerps 1.0 down to
## CombatConstantsParry.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN as the lead leg fails. Pure in `leg` so it is
## callable from constants without entity access. Distinct axis
## from the momentary off-balance close penalty (a fading stagger) — this is a persistent lead-leg
## deficit. D001-neutral at leg == 1.0.


static func close_advance_lead_leg_mult(leg: float) -> float:
    return lerpf(1.0, CombatConstantsParry.CLOSE_ADVANCE_LEAD_LEG_MULT_MIN, 1.0 - clampf(leg, 0.0, 1.0))


static func parry_bonus_mult(parry_control: float) -> float:
    ## Post-parry capacity bonus scales with parry quality — a clean blade catch gives a bigger
    ## tempo advantage than a marginal deflect. Linear map from MIN (low control) to MAX (high control).
    var t: float = clampf(
        (
            (parry_control - CombatConstantsParry.PARRY_BIND_CONTROL_THRESHOLD)
            / (1.0 - CombatConstantsParry.PARRY_BIND_CONTROL_THRESHOLD)
        ),
        0.0,
        1.0
    )
    return lerpf(CombatConstantsParry.PARRY_BONUS_MULT_MIN, CombatConstantsParry.PARRY_BONUS_MULT_MAX, t)


static func parry_recoil_mass_scale(m_a: float, m_d: float) -> float:
    ## Recoil mass-scale: a heavier parrying weapon absorbs more of the impact, reducing the recoil
    ## transmitted to the arm. Scales with the mass ratio (m_a / m_d), clamped to [MIN, MAX].
    ## At equal masses (D001 SWORD mirror) the scale is 1.0 — no behavior change.
    if m_a <= 0.0 or m_d <= 0.0:
        return 1.0
    return clampf(
        m_a / m_d, CombatConstantsParry.PARRY_RECOIL_MASS_SCALE_MIN, CombatConstantsParry.PARRY_RECOIL_MASS_SCALE_MAX
    )


static func parry_two_handed_recoil_mult(is_two_handed: bool) -> float:
    ## A two-handed parry braces the weapon into the torso, distributing the impact across both arms
    ## and the core, so less recoil is transmitted to any single arm. One-handed: neutral 1.0.
    return CombatConstantsParry.PARRY_TWO_HANDED_RECOIL_MULT if is_two_handed else 1.0


static func parry_two_handed_capacity_mult(is_two_handed: bool) -> float:
    ## A two-handed parry holds structure better (longer lever + torso bracing), giving a small
    ## capacity bonus. One-handed: neutral 1.0.
    return CombatConstantsParry.PARRY_TWO_HANDED_CAPACITY_BONUS if is_two_handed else 1.0


static func parry_recoil_alignment_mult(alignment: float) -> float:
    ## Recoil alignment scale: a square-on catch (alignment 1.0) drives the full force of the blow
    ## straight into the blade and arm, while a glancing catch (alignment 0.0) deflects the force
    ## along the blade so less reaches the wrist. Linear map from GLANCING (least recoil) to
    ## SQUARE (most recoil). At alignment 0.5 the scale is ~1.0 (neutral).
    return lerpf(
        CombatConstantsParry.PARRY_RECOIL_GLANCING_MULT,
        CombatConstantsParry.PARRY_RECOIL_SQUARE_MULT,
        clampf(alignment, 0.0, 1.0)
    )


static func parry_recoil_flex_mult(flex_factor: float) -> float:
    ## Recoil blade-flex scale: a flexible (slender) blade flexes on impact, spreading the impulse
    ## over a longer contact time (lower peak force) so less recoil reaches the arm; a stiff (wide)
    ## blade transmits a sharper, higher-peak impulse so more recoil. The flex factor (from
    ## CombatConstantsAttackPath.flex_factor_for_slenderness) is 1.0 at the SWORD reference, which
    ## maps to a neutral 1.0 here — the D001 SWORD soak is unaffected.
    var t: float = clampf(
        (
            (flex_factor - CombatConstantsAttackPath.FLEX_FACTOR_MIN)
            / (CombatConstantsAttackPath.FLEX_FACTOR_MAX - CombatConstantsAttackPath.FLEX_FACTOR_MIN)
        ),
        0.0,
        1.0
    )
    return lerpf(CombatConstantsParry.PARRY_RECOIL_FLEX_MULT_MAX, CombatConstantsParry.PARRY_RECOIL_FLEX_MULT_MIN, t)


static func parry_recoil_progress_mult(parry_progress: float) -> float:
    ## Recoil forte/schwach scale: a well-timed parry meets the blade early (near the forte/handle),
    ## a short lever arm from the hand so less recoil reaches the wrist; a late parry meets it late
    ## (near the schwach/tip), a long lever arm so more recoil. Linear map from FORTE (least recoil)
    ## to SCHWACH (most recoil) with parry progress. At progress 0.5 the scale is ~1.0 (neutral).
    return lerpf(
        CombatConstantsParry.PARRY_RECOIL_FORTE_MULT,
        CombatConstantsParry.PARRY_RECOIL_SCHWACH_MULT,
        clampf(parry_progress, 0.0, 1.0)
    )


static func parry_recoil_body_mass_scale(body_mass_kg: float) -> float:
    ## Recoil body-mass scale (Newtonian inertia / footing): a heavier, well-rooted defender has more
    ## inertia, so the same impulse produces less acceleration and less arm shock. Scales as
    ## reference_mass / body_mass, clamped to [MIN, MAX]. At the reference mass (adult human) the
    ## scale is 1.0 (neutral). A missing/unknown mass (0.0) yields neutral 1.0 — D001 entities carry
    ## no species, so the SWORD soak is unaffected.
    if body_mass_kg <= 0.0:
        return 1.0
    return clampf(
        CombatConstantsParry.PARRY_RECOIL_BODY_MASS_REFERENCE_KG / body_mass_kg,
        CombatConstantsParry.PARRY_RECOIL_BODY_MASS_SCALE_MIN,
        CombatConstantsParry.PARRY_RECOIL_BODY_MASS_SCALE_MAX
    )


static func parry_bind_control_reached(parry_control: float) -> bool:
    return parry_control >= CombatConstantsParry.PARRY_BIND_CONTROL_THRESHOLD


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
        % [CombatConstantsParry.PARRY_DEFLECT_THRESHOLD, CombatConstantsParry.PARRY_BIND_CONTROL_THRESHOLD]
    )


static func p4d_parry_bind_doc_sync_line() -> String:
    var blade: Dictionary = CombatConstantsParry.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
    var shaft: Dictionary = CombatConstantsParry.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
    return (
        "P4d bind sync: blade stab=%.2f cut=%.2f shaft blunt=%.2f fallback=%.2f gauge_bonus=%.0f"
        % [
            float(blade["stab"]),
            float(blade["cut"]),
            float(shaft["blunt"]),
            CombatConstantsParry.PARRY_BIND_RIPOSTE_MULT_FALLBACK,
            CombatConstantsParry.PARRY_BIND_RIPOSTE_GAUGE_BONUS,
        ]
    )


static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
    if not pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges().is_empty():
        return CombatConstantsParry.COMMITMENT_FRACTION_FEINT
    return CombatConstantsParry.COMMITMENT_FRACTION


static func stats_factor_agi_perc(agi: float, perc: float) -> float:
    return clampf((agi + perc) / 200.0, 0.5, 1.5)


static func glancing_factor(ratio: float, exponent: float = CombatConstantsParry.PARRY_GLANCING_EXPONENT) -> float:
    return pow(clampf(ratio, 0.0, 1.0), exponent)


static func compute_parry_redirect_mult(
    pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float
) -> float:
    var r_bonus: float = pcfg.get(DataKeys.PCFG_REDIRECT_BONUS, CombatConstantsParry.PARRY_REDIRECT_BONUS)
    var r_scale: float = pcfg.get(DataKeys.PCFG_REDIRECT_SKILL_SCALE, CombatConstantsParry.PARRY_REDIRECT_SKILL_SCALE)
    var redirect_skill: float = stats_factor_agi_perc(agi, perc)
    var redirect_mult: float = 1.0 + r_bonus + (redirect_skill - 0.5) * r_scale
    var ct: String = contact_type.to_lower()
    if ct == "stab":
        redirect_mult *= (
            1.0 + pcfg.get(DataKeys.PCFG_REDIRECT_THRUST_BONUS, CombatConstantsParry.PARRY_REDIRECT_THRUST_BONUS)
        )
    elif ct == "blunt":
        redirect_mult *= (
            1.0 - pcfg.get(DataKeys.PCFG_REDIRECT_BLUNT_PENALTY, CombatConstantsParry.PARRY_REDIRECT_BLUNT_PENALTY)
        )
    if not is_block_parry and m_a > 0.001 and m_d < m_a:
        var mass_bonus: float = (
            pcfg.get(DataKeys.PCFG_MASS_DISPARITY_BONUS, CombatConstantsParry.PARRY_MASS_DISPARITY_BONUS)
            * (1.0 - m_d / m_a)
        )
        redirect_mult *= 1.0 + mass_bonus
    return redirect_mult


static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
    return c_d_final / maxf(parry_p_a * CombatConstantsParry.PARRY_DEFLECT_THRESHOLD, 0.01)


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
    # CombatConstantsParry.PARRY_CONTROL_ALIGNMENT_FLOOR prevents absolute zero — even a "miracle" deflect via
    # arm interpose grants minimal positional advantage because the attacker's momentum was wasted and the
    # defender feel
    # the impact point (Waffenfühlen), per Liechtenauer: every parry is the first half of a counterattack.
    var alignment_weight: float = pow(
        clampf(maxf(alignment, CombatConstantsParry.PARRY_CONTROL_ALIGNMENT_FLOOR), 0.0, 1.0), 1.2
    )

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
            contact_floor -= CombatConstantsParry.PARRY_THRUST_LINEAR_COMMITMENT_PENALTY * (1.0 - margin_ratio)
        effective_margin = contact_floor + parry_readiness * 0.5

    var p: float = alignment_weight * (effective_margin / 2.0)

    if late_parry:
        p *= CombatConstantsParry.PARRY_LATE_CONTROL_FACTOR
    if parry_off_balance:
        p *= CombatConstantsParry.PARRY_OFF_BALANCE_CONTROL_FACTOR

    if ct == "stab":
        p *= CombatConstantsParry.PARRY_THRUST_CONTROL_MULT

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


static func classify_parry_timing(
    parried_at_windup_frac: float, proactive_threshold: float = CombatConstantsParry.PARRY_PROACTIVE_WINDOW_FRAC
) -> String:
    if parried_at_windup_frac < proactive_threshold:
        return "proactive"
    if parried_at_windup_frac > (1.0 - proactive_threshold):
        return "reactive"
    return "mid"


## Get capacity multiplier based on parry timing classification. Proactive = initiative advantage, reactive = late block
## penalty.


static func parry_timing_capacity_mult(timing_class: String) -> float:
    match timing_class:
        "proactive":
            return CombatConstantsParry.PARRY_PROACTIVE_CAPACITY_MULT
        "reactive":
            return CombatConstantsParry.PARRY_REACTIVE_CAPACITY_MULT
        _:
            return 1.0


## Get control bonus for proactive parries (meeting the attack early in Langen-ort style).
## Velocity-based parry difficulty: faster attacks are harder to time/read.


# Max capacity reduction — fast attacks harder but not devastating for trained fencers
static func parry_timing_control_bonus(timing_class: String) -> float:
    if timing_class == "proactive":
        return CombatConstantsParry.PARRY_PROACTIVE_CONTROL_BONUS
    return 0.0
