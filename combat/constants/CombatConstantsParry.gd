class_name CombatConstantsParry

extends RefCounted

const Misc := preload("res://combat/constants/CombatConstantsMisc.gd")

const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5

const PARRY_STRENGTH_NORM := 100.0

const PARRY_DEFLECT_THRESHOLD := 0.45

const PARRY_TECHNIQUE_VARIANCE := 0.12

const PARRY_V_MIN_FRACTION := 0.2

const PARRY_V_MIN_NEAR_DEFLECT := 0.1

## Partial-parry follow-through velocity physics (DefenseResolutionHandler).
const PARRY_FOLLOW_THROUGH_VEL_CLAMP := 1.1  ## Follow-through velocity cannot exceed 110% of intent velocity.

const PARRY_V_MIN_FALLBACK_MASS_KG := 0.45  ## Light-weapon fallback strike mass (dagger class) for v_min mass scaling.

const PARRY_V_MIN_REFERENCE_MASS_KG := 2.7  ## Heavy-weapon reference strike mass (spear class) for v_min mass scaling.

const PARRY_V_MIN_MASS_SCALE_THRESHOLD := 0.3  ## Remaining-ratio threshold below which mass-scaled v_min applies.

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

## HEMA: a full dodge is a movement off the base of support (lateral step, duck, pull-back). The
## dodger is briefly off-balance until they re-stabilize, so they are exposed to the next incoming
## strike for a short window. Modeled as an off-balance window on the DODGER, distinct from the
## *recovery* duration (the "cannot act" period, already handled by recovery_duration_with_form).
## Base is below the whiff base (OFF_BALANCE_DURATION_S 0.4s): a braced, reactive dodge re-centers
## faster than a forward-committed whiff. The incoming strike's intensity sets how far the defender
## had to move to avoid it (harder strike = bigger evasive motion = longer re-stabilization). Scaled
## by off_balance_recovery_mult (agility / legs / exhaustion / concussion), unifying dodge
## re-stabilization with the hit re-stabilization path. D001 is unaffected: combatants dodge with
## default stats (recovery ~1.0) and the window is short and bounded.
const DODGE_OFF_BALANCE_BASE_S := 0.25

const DODGE_OFF_BALANCE_INTENSITY_SCALE_S := 0.20

const OFF_BALANCE_DEFLECT_DURATION_S := 1.0

## Base off-balance after parry deflect — extends beyond recovery so the action_ready surcharge fires.
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7

## HEMA: an off-balance defender's stepping ability is impaired — a compromised center of gravity
## makes it harder to step away from an incoming strike. Symmetric with the parry-capacity penalty.
const OFF_BALANCE_DODGE_CHANCE_MULT := 0.80

## HEMA: an off-balance attacker's strike is weaker — compromised center of gravity reduces
## transfer of body weight through the weapon. Symmetric with the defensive parry-capacity penalty.
const OFF_BALANCE_ATTACK_DMG_MULT := 0.7

## HEMA: an off-balance attacker also lands less precisely — a staggered center of gravity makes it
## harder to drive the blade to the intended target line, so base hit chance is reduced. Kept mild
## (0.85) and depth-faded because off-balance already widens angle variance (aim) and slows wind-up;
## this is the distinct *precision* axis, applied to the hit-chance roll, not the damage/angle paths.
const OFF_BALANCE_HIT_CHANCE_MULT := 0.85

## HEMA: the mirror of OFF_BALANCE_HIT_CHANCE_MULT, applied to the *target* — an off-balance defender
## is a looser, slower-to-recover target (guard compromised, recovery degraded), so the attacker's
## clean-hit rate rises. The mirror of the attacker's own 0.85 precision penalty, kept at the same
## 15% magnitude and depth-faded, so a settled target is unaffected (D001-neutral). This is a boost
## (> 1.0): off_balance_penalty_mult interpolates 1.0 -> this value by target off-balance depth.
const OFF_BALANCE_TARGET_HIT_CHANCE_MULT := 1.15

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
## OFF_BALANCE_PARRY_CAPACITY_MULT / OFF_BALANCE_DODGE_CHANCE_MULT / OFF_BALANCE_ATTACK_DMG_MULT / angle-variance paths
## already read.
const HIT_DEFENDER_OFF_BALANCE_BASE_S := 0.5

const HIT_DEFENDER_OFF_BALANCE_INTENSITY_SCALE_S := 0.3

## --- Off-balance strike-location scaling (realism) ---
## HEMA: where a hit lands matters for balance independently of how hard it is. A strike to the head
## disrupts the vestibular/proprioceptive system (startle, dizziness); a strike to the legs hits the
## base of support; a torso hit displaces central mass; an arm hit barely disturbs balance (it may
## disable the striking arm, but that is a separate arm-functionality mechanic). Multiplied onto the
## intensity × recovery off-balance window on a landed hit. Chest is the neutral 1.0 baseline.
const HIT_OFF_BALANCE_PART_HEAD_MULT := 1.30

const HIT_OFF_BALANCE_PART_LEG_MULT := 1.25

const HIT_OFF_BALANCE_PART_ARM_MULT := 0.90

## HEMA: how much a *glancing* hit disrupts the defender's balance, relative to a clean hit. A graze
## (blade clips, tissue_dmg below the glancing floor) carries far less of the blow into the body than
## a clean strike, so the off-balance window is cut in half rather than applied at full strength. Kept
## distinct from the part multipliers (where it lands) and intensity (how hard): this is *how much of
## the swing actually landed*. Negligible outcomes (damage floored to ~0) get no off-balance window at
## all — handled by hit_off_balance_outcome_mult, not a constant.
const HIT_GLANCING_OFF_BALANCE_MULT := 0.5

## --- Off-balance impulse scaling (physics) ---
## HEMA/physics: balance disruption scales with the kinetic energy (impulse) the blow delivers, not
## just commitment. Maps the combat-realistic KE band (CombatDesignAnchors.COMBAT_REALISTIC_KE_J_MIN/
## MAX, 35-95 J) to a stagger multiplier: light taps 0.8x, heavy blows 1.2x, and exactly 1.0x at the
## mid-band (~65 J, a typical sword strike) so D001 pacing is unchanged by construction.
const HIT_STAGGER_IMPULSE_MIN_MULT := 0.80

const HIT_STAGGER_IMPULSE_MAX_MULT := 1.20

## --- Head-impact startle floor (physiology) ---
## HEMA/physiology: a sudden impact to the head triggers the startle reflex — an involuntary flinch
## and vestibular jolt that delays voluntary re-balancing. Model as a hard floor on the off-balance
## window for a clean head hit above a meaningful KE threshold. Applied AFTER agility/recovery
## scaling (the reflex precedes voluntary re-rooting, so a fast fighter cannot undercut it). 0.55s
## sits just above the lightest clean head-hit window (~0.54s at intensity 0, 40 J) so the reflex
## does not fade with blow size: it binds on light head hits and passes through on everything heavier.
const STARTLE_HEAD_IMPACT_MIN_S := 0.55

const STARTLE_HEAD_IMPACT_KE_MIN_J := 40.0

## --- Off-balance engagement-angle (orientation) scaling (physiology) ---
## HEMA/physiology: where a blow meets the body relative to its facing matters for balance,
## independent of force. A frontal impact meets the sagittal brace with the feet set deep along the
## line of attack; a lateral impact arrives roughly across the support base, where a biped
## stabilizes far worse (lateral steps are slower and shorter); a rear impact arrives with no
## anticipation or visual counter-stiffening. Driven by the defender's stamped PA_ENGAGEMENT_ANGLE.
## Front is the neutral 1.0 baseline, so D001 1v1 duels (always face-on) are unaffected.
const HIT_ORIENTATION_FLANK_MULT := 1.15

const HIT_ORIENTATION_REAR_MULT := 1.30

## --- Persistent facing / turn-to (Tier 3.1, physiology + HEMA) ---
## HEMA: once a fighter turns to answer a flank or rear attack, they stay turned for a beat —
## they do not snap back to front-on between every exchange. A decaying facing-turn window captures
## that lingering posture. It is stamped on the defender at a flank/rear resolve and consumed as a
## small bounded parry-capacity dip (blade off-line on the new exposure line). Distinct axis from
## off-balance (balance/feet), so the two timed decays never stack into a double stagger.
## D001-neutral: the SWORD soak always resolves front-on, so it never stamps a facing turn.
const FACING_TURN_WINDOW_FLANK_S := 1.2

const FACING_TURN_WINDOW_REAR_S := 1.5

## Max parry-capacity dip at full facing depth: a still-turning fighter's blade is off-line on the
## newly-exposed line, so the parry is at most this weak. 1.0 when settled, lerped toward this min.
const FACING_TURN_PARRY_CAPACITY_MULT_MIN := 0.90

## Cap on the total facing-turn window when flank/rear events pile on. Mirrors OFF_BALANCE_MAX_WINDOW_S:
## repeated flank/rear hits keep the fighter turned longer, but a stacked turn can never exceed this,
## so a fighter is never pinned off-line indefinitely. Slightly above the single rear window (1.5s)
## so two rear hits can visibly extend the turn before the cap clamps.
const FACING_TURN_MAX_WINDOW_S := 2.5

## --- Off-balance armor-mass (inertia) scaling (physics) ---
## HEMA/physics: the mass a fighter carries matters for balance in two opposing ways. A defender in
## heavy plate is braced — the armor's distributed mass raises the body's effective inertia, so the
## same impact jolts the center of mass less and stagger is *reduced*. An attacker in heavy plate
## whiffs into a heavier commitment — the swing carried more mass, so the follow-through takes longer
## to arrest and over-extension *increases*. Driven by the equipped-armor mass ratio (the IV-7
## armor-burden axis that already slows movement). No armor -> 1.0 neutral, so D001 (bare fighters)
## is unaffected. Bounded to a modest band so armor never dominates the off-balance window.
const HIT_ARMOR_INERTIA_REDUCTION := 0.15

const WHIFF_ARMOR_INERTIA_EXTENSION := 0.15

## --- Off-balance medical wind-up slow (realism) ---
## HEMA: tending a wound (bandage / pack / tourniquet) is careful manual work. A medic who is off-balance
## — hands unsteady, center of gravity off — works slower, so the medical wind-up duration is divided by
## this factor (mildly slower than the strike wind-up: 0.85 -> ~18%; here 0.90 -> ~11%) when the performer
## is off-balance. Fades with depth like the strike wind-up slow.
const OFF_BALANCE_MEDICAL_WINDUP_SLOW_MULT := 0.90

## --- Cumulative off-balance cap (realism) ---
## HEMA: repeated off-balance events pile on (a second whiff while already wobbly is worse than a
## fresh single whiff). When a fighter is already off-balance and takes another off-balance event,
## the new window adds onto the remaining time instead of resetting to the fresh duration. This cap
## bounds how long stacked events can keep a fighter off-balance, so repeated hits cannot pin them
## permanently. Single events (0.4-1.2s) never approach the cap; only rapid repeated events do.
const OFF_BALANCE_MAX_WINDOW_S := 3.0

## --- Off-balance in bind contests (realism) ---
## HEMA: an off-balance fighter's compromised center of gravity weakens the bind too — they cannot
## drive or hold pressure as effectively. Applied to the off-balance side's contest power (both the
## presser in bind_press and either side in bind_wrestle) via off_balance_penalty_mult, so it fades
## with depth like the other off-balance penalties. Mild (0.75) vs the 0.70 strike/parry penalties:
## the bind is a static grapple, not a dynamic strike.
const OFF_BALANCE_BIND_CONTEST_MULT := 0.75

## --- Off-balance execute (coup de gràce) fumble (realism) ---
## HEMA: a staggered fighter's center of gravity is compromised, so a committed finishing strike on a
## downed foe is less likely to land cleanly. At full off-balance depth the coup de gràce can fumble
## (turn consumed, target stays downed — you can re-attempt once settled). Fades linearly with depth
## via off_balance_depth so a nearly-settled fighter finishes as reliably as a settled one. Bounded
## well under certainty even at full depth: a wobbly fighter usually still lands on a prostrate enemy.
const OFF_BALANCE_EXECUTE_FAIL_CHANCE_MAX := 0.30

## --- Off-balance close-attempt (movement) penalty (realism) ---
## HEMA: advancing on an opponent is a leg-driven, committed lunge. A fighter whose footing is off
## can't drive that advance as effectively, so the off-balance attacker's close pressure is scaled
## down (fades with depth). Models the movement side of "compromised center of gravity".
const OFF_BALANCE_CLOSE_PRESSURE_MULT := 0.80

## --- Close-advance lead-leg drive (Tier 2.1 v2, HEMA) ---
## HEMA: closing distance is a committed leg-driven lunge where the lead leg steps *into* the opponent
## (the propulsive drive). A wounded lead leg can't generate that forward drive, so the attacker's close
## pressure is reduced. Floor when the lead leg is fully destroyed: the fighter can still lunge a little
## off the trail leg, so it never reaches 0. Set slightly below the momentary off-balance close floor
## (0.80) because a destroyed lead leg is a persistent deficit, not a fading stagger. D001-neutral at
## full lead-leg functionality (1.0 -> 1.0 mult).
const CLOSE_ADVANCE_LEAD_LEG_MULT_MIN := 0.70

## --- Off-balance recovery scaling (realism) ---
## Re-establishing footing is a proprioceptive/motor skill, not a flat clock: a healthy, agile
## fighter re-roots faster, a leg-wounded one lingers. This factor multiplies the off-balance
## duration computed by the miss/deflect/hit/bind writers (and the action-ready surcharge window).
## Neutral 1.0 at a healthy leg (leg = 1.0) and default agility (Misc.DEFAULT_STAT_VALUE = 100),
## so the D001 SWORD soak (no species, default stats) is unaffected.
## Leg term: healthy (1.0) -> 1.0; both legs destroyed (0.08) -> ~1.46 (re-rooting far slower).
const OFF_BALANCE_RECOVERY_LEG_RANGE := 0.5

## Agility term: neutral at default; 0.2% per stat point, clamped to these bounds (+/-50 stat
## -> +/-10% recovery window).
const OFF_BALANCE_RECOVERY_AGI_PER_POINT := 0.002

const OFF_BALANCE_RECOVERY_AGI_MIN := 0.85

const OFF_BALANCE_RECOVERY_AGI_MAX := 1.15

## Overall clamp: recovery can never make off-balance shorter than 0.75x or longer than 1.6x base.
const OFF_BALANCE_RECOVERY_MIN := 0.75

const OFF_BALANCE_RECOVERY_MAX := 1.6

## Floor for the exhaustion inverse: how much exhaustion alone may stretch re-rooting. A fully spent
## fighter re-roots slower, but this keeps the single-factor stretch bounded before the overall clamp.
const OFF_BALANCE_RECOVERY_EXHAUSTION_FLOOR := 0.6

## --- Leg-wound parry bracing (realism) ---
## HEMA: a parry is a force redirect that terminates in the ground — the impulse runs blade -> arm ->
## shoulder -> spine -> feet, so the brace is only as strong as the base planted underneath it. A
## compromised base (a wounded leg) weakens the *capacity* to absorb/redirect (the blade deflects a
## little more, follow-through is softer) rather than the *timing* (the leg contributes little to the
## vision -> CNS -> muscle reaction window). Kept mild (floor 0.85, i.e. ~15% at a destroyed leg)
## because parry bracing is far less leg-dependent than dodge (which needs full lateral displacement);
## the leg is a secondary brace, the arm/torso structure is primary. Distinct from the arm limb-impairment
## parry penalty (primary weapon handling) and from the momentary off-balance penalty. D001-neutral: a
## healthy leg (leg == 1.0) yields exactly 1.0.
const LEG_STANCE_PARRY_MULT_MIN := 0.85

## --- Off-balance base-of-support susceptibility (realism) ---
## HEMA/physics: whether an incoming impact tips the center of mass outside the support base depends
## on the base's width and the corrective force the legs can generate. A wounded leg narrows the
## effective support base and weakens the corrective push, so the *same* blow tips the fighter more
## easily. This is the *susceptibility* axis (how hard a hit must be to start an off-balance window)
## and is deliberately separate from off_balance_recovery_mult (the *re-rooting* axis — how fast a
## fighter recovers once already off-balance). A leg-wounded defender is both more easily knocked
## off-balance AND slower to re-center. Applied only to the incoming-impact (hit) path: a dodge or
## whiff is a self-initiated displacement, not an external tip, so the base-of-support threshold does
## not apply there. Neutral 1.0 at a healthy leg; at total leg loss the window is stretched by up to
## ~35% (within the researched 20-40% band for a compromised base). D001 SWORD soak is unaffected
## (no species / default stats -> healthy legs -> 1.0).
const HIT_OFF_BALANCE_LEG_SUSCEPTIBILITY_RANGE := 0.35

## --- Torso-wound parry bracing (realism) ---
## HEMA: a parry is braced through the core — the chest/rib cage transfers the blade-on-blade impulse
## into the ground through the spine and legs. A structurally compromised core (ribs fractured, sternum
## bruised, core tissue damaged) leaks that brace, so the same catch that a healthy fighter absorbs
## with minimal displacement costs a wounded fighter more displacement and control. This is the *core*
## axis; leg_stance_parry_mult is the *base* axis. Kept at the same 0.85 floor as the leg term because
## the core is a single vital part (no two-part averaging), so a full compromise is already severe.
## Distinct from arm limb-impairment (weapon handling) and arm-wound grip (blade delivery).
## D001-neutral: healthy chest -> torso 1.0 -> exactly 1.0.
const TORSO_STANCE_PARRY_MULT_MIN := 0.85

## --- Formation-move settling (realism) ---
## HEMA: a fighter who just stepped / rotated / fell back in the line is mid-replant — weight is
## shifting and the base is not yet braced, so they are briefly less stable than a settled fighter.
## Modeled as a short off-balance window (reusing the existing window system, no new state), shorter
## than a whiff because the move was deliberate, not a committed blow. Move-kind scaled: rotating the
## file and falling back shift the base more than a rank swap. Plug-forward is a fast deliberate
## advance that gains tempo, so it settles at 0.0. D001 SWORD soak has no formation movement, so it is
## unaffected.
const FORMATION_SETTLE_OFF_BALANCE_BASE_S := 0.35

const FORMATION_SETTLE_ROTATE_SCALE := 1.2

const FORMATION_SETTLE_FALL_BACK_SCALE := 1.1

## Cower re-plant: a fighter who just got back on his feet after cowering (limb destruction /
## unconsciousness cleared) is not instantly braced. Base is the arms-only window; when the legs are
## still weakened the re-plant is slower (a leg-collapsed re-plant takes longer than an arms-only one).
## D001-neutral: D001 never enters cower, so the SWORD soak is unaffected.
const COWER_REPLANT_OFF_BALANCE_BASE_S := 0.6

const COWER_REPLANT_LEGS_SCALE := 1.4

const COWER_REPLANT_LEGS_COMPROMISED_THRESHOLD := 0.9

const PARRY_BONUS_AFTER_DEFLECT_S := 2.0

const PARRY_BONUS_MULT_MIN := 1.05  ## Marginal parry (low control): 5% capacity boost.

const PARRY_BONUS_MULT_MAX := 1.15  ## Perfect parry (high control): 15% capacity boost.

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
## Partial binds at >= 0.60 still require meaningful alignment but allow glancing intercepts to trigger riposte/flurry
## chains.
const PARRY_PARTIAL_BIND_ALIGNMENT_THRESHOLD := 0.60

## Functional parry bonus: alignments near the partial guard threshold (cos45) are boosted into a more confident regime.
## A 45° intercept is a legitimate HEMA parry line — it deflects rather than fully blocks, but should not be treated as
## marginal. This small alignment bump prevents the decision system from oscillating between parry/dodge for borderline
## cases.
const PARRY_FUNCTIONAL_ALIGNMENT_BONUS := 0.12

## Glancing floor: alignment at cos(60°). Below this, parry contact geometry is so degraded that even viable capacity
## should not override dodge — the blade cannot meaningfully engage the attack trajectory (near-perpendicular spark).
const PARRY_GLANCING_ALIGNMENT_FLOOR := 0.5

## Reduced alignment threshold for wide-arc weapons (axe, poleaxe) attacking with adjacent guard lines.
## Wide-face weapons can intercept attacks at specific points along their arc even when not perfectly aligned.
const PARRY_WIDE_ARC_DEFLECT_THRESHOLD := 0.25  # cos75 — allows deflect for wide weapons on adjacent lines

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
## Linear-commitment penalty: failed thrust parries carry more momentum because the attacker's body is committed
## forward.
## Distinct recovery: deflecting a thrust requires redirecting linear force, which costs different timing than slashing
## deflection.
const PARRY_THRUST_LINEAR_COMMITMENT_PENALTY := 0.18

## Extra momentum carry when thrust parry fails (attacker drives through).
const PARRY_THRUST_RECOVERY_MULT := 1.25

## Thrust deflections cost 25% more recovery — linear force requires full repositioning.
const PARRY_DEFLECT_RECOVERY_MULT := 1.20

## Deflected attacks cost 20% more recovery — blade knocked offline requires extra repositioning.
## Parry-vs-dodge decision tuning (DefenseChoiceResolver).
const PASSIVE_DEFENSE_BIAS := 0.90  ## Historical combat favors blade defense — parry energy discounted 10% vs dodge.

const PARRY_BELOW_GLANCING_DODGE_BOOST := 1.25

## Below glancing floor: parry is physically ineffective, dodge gets +25%.
const PARRY_GLANCING_DODGE_BOOST := 1.15  ## Glancing tier: parry needs capacity surplus, dodge gets +15%.

## Twist-dodge after partial parry (DefenseResolutionHandler).
const TWIST_DODGE_MIN_TIME_FACTOR := 0.35

## Insufficient-react-time twist still has meaningful dodge capacity, not near-zero.
const TWIST_DODGE_PARRY_QUALITY_SLOPE := 0.30

## Better parry = better dodge position; 30% max reduction at full remaining ratio.
const TWIST_DODGE_PARRY_QUALITY_FLOOR := 0.70

## Dodge capacity floor when parry quality is worst (full remaining ratio).
## Reach disparity parry penalty (DefenseChoiceResolver._reach_disparity_parry_penalty).
## When the attacker's weapon is longer than the defender's, the defender's parry capacity is penalized.
const REACH_DISPARITY_THRESHOLD_M := 0.30  ## Reach delta below this (meters) is free — no penalty.

const REACH_DISPARITY_PENALTY_SLOPE := 0.30  ## Capacity lost per meter of excess reach delta.

const REACH_DISPARITY_PENALTY_FLOOR := 0.25  ## Parry capacity floor — reach disparity can't reduce capacity below 25%.

## Reach-based parry readiness bonus (DefenseChoiceResolver._reach_parry_readiness_bonus).
## HEMA "Langen-ort": longer weapons extend the blade into the attack trajectory earlier.
const REACH_READINESS_SCALE_PER_M := 0.06  ## 6% readiness bonus per meter of net reach advantage.

const REACH_READINESS_CAP := 0.15  ## Cap at +/-15% — beyond this, other factors dominate.

const PARRY_THRUST_BLOCK_ONLY_THRESHOLD := 0.88

## Thrusts can be deflected via blade leverage (strong vs weak) — below 1.0 reflects cross-guard catch.
const PARRY_THRUST_GLANCE_ALIGNMENT_FLOOR := 0.5

## cos60 — thrust glancing requires this alignment; below this it's a miss, not a glancing parry.
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

## Proactive parries (initiated before ~1/3 of wind-up) are Langen-ort style — meet the blade early with superior
## control.
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

const PARRY_CASCADE_FLOOR_RAW_MIN := 2.0

## Minimum raw c_d for cascade floor to apply — below this, capacity is genuinely low
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
## flat-ground blades have maximum binding contact but lower torsional stiffness. Actual medieval steel weapons
## typically
## use a combination: fuller in distal third for weight reduction, flat or slightly convex proximal section for bind
## control.
const BIND_BLADE_WIDTH_FRICTION_MULT: float = 0.12  # per cm of blade width; wider blade = more friction on bind

const BIND_DEFAULT_BLADE_WIDTH_CM: float = 2.0  # baseline contact width for parry/bind (typical sword blade)

const GUARD_TRANSITION_COST_SCALE := 0.4

const GUARD_TRANSITION_MULT_MAX := 1.35

## Maximum absolute time penalty for guard-line transition during recovery (seconds).
## Models HEMA reality: parrying pushes blade away from rest position; repositioning to a different guard line costs
## extra time.
## 0–45° delta: minimal cost (~0.05s); 90° delta: moderate (~0.15s); 180° delta: significant (~0.25s max).
const GUARD_TRANSITION_RECOVERY_MAX_S := 0.25

## HEMA: a staggered (off-balance) defender has reduced fine motor control for blade repositioning.
## After a parry knocks the blade to the attack line, re-centering the guard takes proportionally
## longer. Applied multiplicatively to the guard-transition cost in the parry recovery path.
## At full off-balance depth (depth=1.0) the transition cost is multiplied by (1 + SCALE).
## Kept mild (0.5) so a fully off-balance fighter pays 1.5x transition cost, not 2x.
## Fades with depth via off_balance_depth — a nearly-settled fighter pays almost the full base cost.
const GUARD_TRANSITION_OFF_BALANCE_SCALE := 0.5

## HEMA: a fatigued striking limb slows blade re-centering after a parry. Sustained muscle fatigue in
## the striking arm degrades the fine-motor speed needed to bring the blade back to guard, so the
## guard-transition cost is extended proportionally. Applied multiplicatively alongside the off-balance
## term in the parry recovery path. `fatigue` is the dominant striking-limb fatigue (0.0 fresh, 1.0
## exhausted); neutral at 0.0. Kept mild (0.2) so full fatigue adds at most 20% on top of the base
## transition cost — distinct from the transient off-balance term, which fades on its own window.
const GUARD_TRANSITION_FATIGUE_SCALE := 0.2

## HEMA: a wounded striking arm accelerates the blade more slowly — the cut/stab compromises grip and
## shoulder drive. Multiplied onto wind-up duration as 1 + depth*(1 - grip). Neutral at a healthy arm
## (grip 1.0). Bounded by the arm-wound grip floor (ARM_WOUND_GRIP_FLOOR). Distinct from the arm
## damage/parry-capacity terms (which scale *force*, not *speed*).
const ARM_WINDUP_WOUND_SLOW_RANGE := 0.30

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

const PARRY_VELOCITY_INTENSITY_MIN_THRESHOLD := 0.75

# Only apply velocity penalty at high intensity (real fast strikes)
const PARRY_VELOCITY_DIFFICULTY_REF_M_S := 8.0  # Below this, no penalty (reasonable strike speed)

const PARRY_VELOCITY_DIFFICULTY_MAX_PENALTY := 0.25

## Parry computation math now lives in **`CombatParryMath`** (pure code-motion split).


static func bind_friction_mult_for_weapon(def_weapon: Variant) -> float:
    return CombatParryMath.bind_friction_mult_for_weapon(def_weapon)


static func parry_full_stop_reached(
    c_d: float, parry_p_a: float, is_block_parry: bool, contact_type: String = ""
) -> bool:
    return CombatParryMath.parry_full_stop_reached(c_d, parry_p_a, is_block_parry, contact_type)


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
    return CombatParryMath.parry_edge_deflect_reached(
        c_d, parry_p_a, alignment, is_block_parry, contact_type, attack_line, guard_line, is_wide_arc
    )


static func parry_thrust_recovery_mult(intensity: float) -> float:
    return CombatParryMath.parry_thrust_recovery_mult(intensity)


static func parry_deflect_recovery_mult(intensity: float) -> float:
    return CombatParryMath.parry_deflect_recovery_mult(intensity)


static func off_balance_deflect_duration(intensity: float) -> float:
    return CombatParryMath.off_balance_deflect_duration(intensity)


static func formation_settle_off_balance_duration(move_kind: String) -> float:
    return CombatParryMath.formation_settle_off_balance_duration(move_kind)


static func cower_replant_off_balance_duration(leg_functionality: float) -> float:
    return CombatParryMath.cower_replant_off_balance_duration(leg_functionality)


static func miss_off_balance_duration(intensity: float) -> float:
    return CombatParryMath.miss_off_balance_duration(intensity)


static func dodge_off_balance_duration(intensity: float) -> float:
    return CombatParryMath.dodge_off_balance_duration(intensity)


static func hit_defender_off_balance_duration(intensity: float) -> float:
    return CombatParryMath.hit_defender_off_balance_duration(intensity)


static func hit_part_off_balance_mult(part: String) -> float:
    return CombatParryMath.hit_part_off_balance_mult(part)


static func hit_off_balance_outcome_mult(outcome: String) -> float:
    return CombatParryMath.hit_off_balance_outcome_mult(outcome)


static func hit_impulse_stagger_mult(ke_j: float) -> float:
    return CombatParryMath.hit_impulse_stagger_mult(ke_j)


static func hit_startle_min_s(part: String, outcome: String, ke_j: float) -> float:
    return CombatParryMath.hit_startle_min_s(part, outcome, ke_j)


static func hit_orientation_stagger_mult(angle: String) -> float:
    return CombatParryMath.hit_orientation_stagger_mult(angle)


static func facing_turn_window_s(angle: String) -> float:
    return CombatParryMath.facing_turn_window_s(angle)


static func hit_armor_inertia_mult(armor_ratio: float) -> float:
    return CombatParryMath.hit_armor_inertia_mult(armor_ratio)


static func whiff_armor_inertia_mult(armor_ratio: float) -> float:
    return CombatParryMath.whiff_armor_inertia_mult(armor_ratio)


static func off_balance_recovery_mult(leg: float, agi: float) -> float:
    return CombatParryMath.off_balance_recovery_mult(leg, agi)


static func leg_stance_parry_mult(leg: float) -> float:
    return CombatParryMath.leg_stance_parry_mult(leg)


static func torso_stance_parry_mult(torso: float) -> float:
    return CombatParryMath.torso_stance_parry_mult(torso)


static func hit_off_balance_leg_susceptibility_mult(leg: float) -> float:
    return CombatParryMath.hit_off_balance_leg_susceptibility_mult(leg)


static func guard_transition_off_balance_mult(depth: float) -> float:
    return CombatParryMath.guard_transition_off_balance_mult(depth)


static func guard_transition_fatigue_mult(fatigue: float) -> float:
    return CombatParryMath.guard_transition_fatigue_mult(fatigue)


static func arm_wound_windup_slow_mult(grip: float) -> float:
    return CombatParryMath.arm_wound_windup_slow_mult(grip)


static func close_advance_lead_leg_mult(leg: float) -> float:
    return CombatParryMath.close_advance_lead_leg_mult(leg)


static func parry_bonus_mult(parry_control: float) -> float:
    return CombatParryMath.parry_bonus_mult(parry_control)


static func parry_recoil_mass_scale(m_a: float, m_d: float) -> float:
    return CombatParryMath.parry_recoil_mass_scale(m_a, m_d)


static func parry_two_handed_recoil_mult(is_two_handed: bool) -> float:
    return CombatParryMath.parry_two_handed_recoil_mult(is_two_handed)


static func parry_two_handed_capacity_mult(is_two_handed: bool) -> float:
    return CombatParryMath.parry_two_handed_capacity_mult(is_two_handed)


static func parry_recoil_alignment_mult(alignment: float) -> float:
    return CombatParryMath.parry_recoil_alignment_mult(alignment)


static func parry_recoil_flex_mult(flex_factor: float) -> float:
    return CombatParryMath.parry_recoil_flex_mult(flex_factor)


static func parry_recoil_progress_mult(parry_progress: float) -> float:
    return CombatParryMath.parry_recoil_progress_mult(parry_progress)


static func parry_recoil_body_mass_scale(body_mass_kg: float) -> float:
    return CombatParryMath.parry_recoil_body_mass_scale(body_mass_kg)


static func parry_bind_control_reached(parry_control: float) -> bool:
    return CombatParryMath.parry_bind_control_reached(parry_control)


static func is_wide_arc_weapon(weapon: Variant) -> bool:
    return CombatParryMath.is_wide_arc_weapon(weapon)


static func iii3_baseline_constants_line() -> String:
    return CombatParryMath.iii3_baseline_constants_line()


static func p4d_parry_bind_doc_sync_line() -> String:
    return CombatParryMath.p4d_parry_bind_doc_sync_line()


static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
    return CombatParryMath.commitment_fraction_for_pending_attack(pa)


static func stats_factor_agi_perc(agi: float, perc: float) -> float:
    return CombatParryMath.stats_factor_agi_perc(agi, perc)


static func glancing_factor(ratio: float, exponent: float = PARRY_GLANCING_EXPONENT) -> float:
    return CombatParryMath.glancing_factor(ratio, exponent)


static func compute_parry_redirect_mult(
    pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float
) -> float:
    return CombatParryMath.compute_parry_redirect_mult(pcfg, agi, perc, contact_type, is_block_parry, m_a, m_d)


static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
    return CombatParryMath.parry_deflect_margin_ratio(c_d_final, parry_p_a)


static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
    return CombatParryMath.parry_deflect_severity_from_margin_ratio(margin_ratio)


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
    return CombatParryMath.parry_control_for_bind_deflect(
        c_d_final,
        parry_p_a,
        alignment,
        parry_readiness,
        parry_off_balance,
        late_parry,
        contact_type,
        bind_friction_mult
    )


static func classify_parry_timing(
    parried_at_windup_frac: float, proactive_threshold: float = PARRY_PROACTIVE_WINDOW_FRAC
) -> String:
    return CombatParryMath.classify_parry_timing(parried_at_windup_frac, proactive_threshold)


static func parry_timing_capacity_mult(timing_class: String) -> float:
    return CombatParryMath.parry_timing_capacity_mult(timing_class)


static func parry_timing_control_bonus(timing_class: String) -> float:
    return CombatParryMath.parry_timing_control_bonus(timing_class)
