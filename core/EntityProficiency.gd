class_name EntityProficiency

extends RefCounted

# --- Gain rate multipliers (diminishing returns by proficiency level) ---
# Power-law-of-practice shape (Topic 7/8; Newell & Rosenbloom 1981, Ericsson 1993): rapid early
# improvement with diminishing returns, fast-early 1.0 -> 0.7 -> 0.4 -> 0.2 -> 0.1 across bands.
# This tiering IS the growth curve; the per-action GAIN_* amounts below are game-pacing knobs
# (points per event), not research-derivable.
const PROFICIENCY_NOVICE_MAX: int = 5

const PROFICIENCY_PROFICIENT_MAX: int = 10

const PROFICIENCY_VETERAN_MAX: int = 20

const PROFICIENCY_ELITE_MAX: int = 30

# --- Decay rates (per inactive day, before per-stat multiplier) ---
# Retention anchor (Topic 7d + sports-science detraining literature): decay models the
# *specialized edge above the species baseline* rusting without practice. Foundational skill
# (bonus <= 10) never decays; only the trained edge does. The more a stat is pushed above
# baseline, the more it is over-specialized, and over-specialized adaptation (cardiovascular
# output, elite neural patterning) is what reverses fastest when unused - so the per-day rate
# steepens with tier. Per-day magnitude is a game-pacing abstraction on the campaign-day clock
# (not a 24-hour physiological rate); the research-ordered physical->cognitive shape lives in
# DECAY_MULT_* below, and the steeper floor avoids "permanent amnesia" for a skilled fighter.
const DECAY_RATE_NOVICE_PLUS: float = -0.03  # +11 to +15

const DECAY_RATE_PROFICIENT_PLUS: float = -0.05  # +16 to +20

const DECAY_RATE_VETERAN_PLUS: float = -0.08  # +21 to +25

const DECAY_RATE_ELITE_PLUS: float = -0.12  # +26 to +30

## +31+ master tier: continues the per-tier increment ramp (+0.02, +0.03, +0.04, +0.05) so the most
## specialized skills rust fastest when left unpracticed ("steeper effective decay floor", Topic 7d).
const DECAY_RATE_MASTER_PLUS: float = -0.17  # +31+

## Weapon/form familiarity rust (XCamp-4): motor/cardiovascular detraining applies to weapon
## handling too — a fighter who stops swinging a weapon loses the *trained edge* (values above the
## 10.0 foundational floor, same rule as stat bonuses) so their aim/melee_skill/occurrence drop in
## step with their rusted stats instead of keeping perfect aim forever. Uses the same absent-day
## inactivity factor and `last_decay_day` high-water mark as stat decay; a modest flat rate (no
## per-stat multiplier) because weapon familiarity is pure use-based motor learning with no other
## reinforcement.
const DECAY_RATE_WEAPON_FORM: float = -0.06  # per absent day-equiv, values > 10.0 only

## Realism: a fighter below the ATLS Class IV triage-peril line is incapacitated, not rusting from
## disuse — they can't practice because they can't stand, not because they forgot. Inactivity decay
## is halved for stat bonuses AND weapon/form familiarity. Mirrors the write-side
## GAIN_WOUNDED_WRITE_FLOOR (both 0.5): the body is degraded, not the mind.
const DECAY_WOUNDED_INCAPACITATION_MULT: float = 0.5

# --- Decay threshold boundaries (bonus magnitude tiers) ---
const DECAY_THRESHOLD_NOVICE_MAX: float = 15.0

const DECAY_THRESHOLD_PROFICIENT_MAX: float = 20.0

const DECAY_THRESHOLD_VETERAN_MAX: float = 25.0

const DECAY_THRESHOLD_ELITE_MAX: float = 30.0

# Forgetting-curve / detraining shape across inactive days (Topic 7d): total skill loss
# saturates instead of growing linearly forever. The per-day decay contribution falls geometrically
# with day number (half-life ~ ln(2)/lambda ~ 11-12 days), so most rust lands early in a layoff -
# matching how cardiovascular/motor detraining drops fast then plateaus. lam=0.0 restores pure
# linear (legacy) behaviour.
const DECAY_DAY_DIMINISH_LAMBDA: float = 0.06

# --- Per-stat decay multipliers (research-calibrated) ---
# Physical systems rust faster than cognitive ones: cardiovascular/endurance and motor
# coordination lose the most during inactivity (detraining literature: VO2max ~10-25% in
# 2-5 weeks of cessation), while learned knowledge/technique retention is slowest. Hence
# END 1.5 > AGI 1.3 > PER 0.8 > STR 0.5 > INT 0.4.
const DECAY_MULT_END: float = 1.5

const DECAY_MULT_AGI: float = 1.3

const DECAY_MULT_PER: float = 0.8

const DECAY_MULT_STR: float = 0.5

const DECAY_MULT_INT: float = 0.4

const WEAPON_CURVES: Dictionary = {
    "SWORD": {"strength": 0.8, "agility": 0.9},
    "AXE": {"strength": 1.2, "agility": 0.95},
    "MACE": {"strength": 1.25, "agility": 0.85},
    "DAGGER": {"strength": 0.7, "agility": 1.2},
    "SPEAR": {"strength": 1.3, "agility": 1.0},
}

const GAIN_OFF_FOCUS_HIT_PER_BASE: float = 0.12

## PER taught by a clean parry: successfully meeting a strike is a *read* of the incoming attack
## (threat detection / anticipation), distinct from the END already awarded for absorbing the force
## and from the AGI a dodge awards for raw footwork. Perception is the combat stat with the thinnest
## gain path (off-focus hits only) yet a meaningful read role (hit chance 0.8–1.2), so a clean parry
## is its second channel — kept just under the off-focus base so reading stays the rarer, sharper lesson.
const GAIN_PARRY_READ_PER_BASE: float = 0.10

## PER taught by a successful dodge: evading an incoming strike requires perceiving the attack line.
## Subordinate to the parry-read (a parry is a direct blade-to-blade engagement; a dodge is more
## reactive footwork), but still a perception act — you read the threat to move out of the way.
const GAIN_DODGE_READ_PER_BASE: float = 0.05

const GAIN_PREFERRED_PART_INT_BASE: float = 0.10

## PER taught by a committed counter-read resolving. Reading the opponent's form/line and being
## *right* is the sharpest perception lesson; being *wrong* still teaches (you learned what that line
## was NOT), so it earns a smaller share. Cognitive - not scaled by the wounded-fighter physical factor.
const GAIN_COUNTER_READ_CORRECT_PER_BASE: float = 0.14

const GAIN_COUNTER_READ_WRONG_PER_BASE: float = 0.05

const GAIN_WEAPON_PROF_HIT_BASE: float = 0.25

const GAIN_FORM_PROF_HIT_BASE: float = 0.20

## Weapon/form familiarity from a *completed strike attempt* (a rep), regardless of outcome. A clean
## hit already awards the larger GAIN_*_PROF_HIT_BASE share; a missed/evaded/parried wind-up still
## practices the weapon and form, so it builds some aim too. Use-based learning: repetition trains the
## motor program, not just successful contact — otherwise a fighter who keeps missing never builds the
## melee_skill that would let them start hitting. Kept well under the hit share so clean hits still
## remain the stronger teacher.
const GAIN_WEAPON_PROF_ATTEMPT_BASE: float = 0.10

const GAIN_FORM_PROF_ATTEMPT_BASE: float = 0.08

## Weapon/form familiarity the *parrier* earns from a successful parry: meeting an incoming blade is a
## precise defensive weapon-control act (blade-to-blade catch), so the parrying fighter also practices
## their own weapon and form — not just the attacker who swung. Kept below the attacker's full-swing
## attempt shares (GAIN_WEAPON_PROF_ATTEMPT_BASE / GAIN_FORM_PROF_ATTEMPT_BASE) because a parry is a
## short, economical catch rather than a committed wind-up. Fires on parry_deflect and parry_partial
## (both met the line), gated on the write-side tracked flag like every other award.
const GAIN_PARRY_WEAPON_PROF_BASE: float = 0.06

const GAIN_PARRY_FORM_PROF_BASE: float = 0.04

const WEAPON_PROF_VETERAN_MAX: float = 20.0

const FORM_PROF_VETERAN_MAX: float = 20.0

## XCamp-6: base amount queued per camp drill for form/weapon proficiency. Applied at merge
## through the same diminishing-returns curve as combat gains.
const DRILL_FORM_GAIN_BASE: float = 1.0

const DRILL_WEAPON_GAIN_BASE: float = 1.0

const PROF_OCCURRENCE_MULT_MAX: float = 1.35

const PROF_AIM_MULT_MAX: float = 1.15

const PROF_INTENDED_PART_BOOST_MIN: float = 2.0

const PROF_INTENDED_PART_BOOST_MAX: float = 3.0

# --- Combat skill curve (untrained -> veteran) ---
## Derived melee_skill baseline for a standard trained soldier (enemy / untracked fighters).
const MELEE_SKILL_BASELINE: float = 100.0

## Skills below MELEE_SKILL_BASELINE clamp hit chance toward MELEE_SKILL_HIT_FACTOR_MIN (0.5).
const MELEE_SKILL_UNSKILLED: float = 50.0

## Skills above baseline reach MELEE_SKILL_HIT_FACTOR_MAX (1.3) at veteran familiarity.
const MELEE_SKILL_VETERAN_MAX: float = 130.0

## Effective-stat untrained holdback: below this per-stat bonus, tracked fighters fight "green".
const UNSKILLED_BONUS_THRESHOLD: float = 5.0

## Flat per-stat effective-value deduction at zero experience (fades to 0 at threshold).
const UNSKILLED_STAT_PENALTY_MAX: float = 5.0

# --- Base gain amounts per combat event (raw proficiency points) ---
## STR taught by landing a clean hit — the baseline of the offensive STR channel (the damage-scaled
## term below adds to it; a clean hit is the single strongest strength lesson in a melee exchange).
const GAIN_MELEE_HIT_BASE: float = 0.3

## Maximum extra STR a single hit's damage can add (the cap on the dmg / GAIN_HIT_STR_DAMAGE_DIVIDER
## term): a heavy blow is worth more strength than a tap, with diminishing value beyond this.
const GAIN_MELEE_HIT_MAX_DMG_CONTRIB: float = 2.0

## STR taught by landing a wound (before the GAIN_SEVERE_WOUND_SEVERITY_MULT severity shape): opening
## a cut is a sharper lesson than a clean but superficial hit.
const GAIN_SEVERE_WOUND_BASE: float = 0.5

## STR "wind-up rep" for committing a strike that did not land cleanly (miss / dodged / parried) —
## the smaller "I swung" share vs the 0.3 clean-hit base. Also the base the parry STR awards scale from.
const GAIN_STRIKE_ATTEMPTED_BASE: float = 0.15

## AGI taught by successfully evading a strike — raw footwork / spatial-avoidance (the largest single
## agility base, since a clean dodge is the purest AGI act in the system).
const GAIN_DODGE_EVADED_BASE: float = 0.4

## Extra AGI when dodging while the last fighter standing in your slot group (outnumbered): a harder,
## higher-stakes reflex under fire, so it earns a bump on top of the dodge base.
const GAIN_DODGE_OUTNUMBERED_BONUS: float = 0.2

## Reflex training from a clean parry: meeting an incoming blade requires fast reaction and
## precise timing, so the defender earns a small AGI gain on top of the STR/END from the act.
## Smaller than the dodge base because a parry is a controlled, localised movement.
const GAIN_PARRY_REFLEX_AGI_BASE: float = 0.08

## AGI trained by completing a wind-up / executing the strike itself — the timing-and-sequencing
## motor program of the swing, independent of whether it lands. Fires on every committed strike
## (miss / dodge / hit / parry), so timing is trained on every rep, not only on contact. Smaller
## than the clean-dodge base (0.4) because it is the internal execution of the swing, not the
## spatial-avoidance act of a clean evasion.
const GAIN_WINDUP_COMPLETED_AGI_BASE: float = 0.1

## Aerobic endurance the attacker trains from a *committed* strike's exertion — the cardiovascular /
## muscular-stamina cost of the wind-up, strike, and recovery cycle. This is the attacker's END
## channel: previously they trained END only by taking damage, so a disciplined fighter who swings a lot
## but blocks well never built endurance. Use-based conditioning from repeated submaximal exertion
## (sports-science detraining/conditioning principle), independent of whether the blow lands. Kept small
## and below the damage-absorbed base because the defender taking a hit does the heavier endurance work.
## Scaled by the wounded factor like every other physical gain; gated on the write-side tracked flag.
const GAIN_STRIKE_AEROBIC_END_BASE: float = 0.06

## INT base for performing a medical action (scaled by the item-type mult in MEDICAL_ITEM_MULT):
## a hands-on treatment trains the medic's technique, independent of outcome.
const GAIN_MEDICAL_ACTION_BASE: float = 0.5

## END baseline the patient trains from absorbing damage from a hit.
const GAIN_DAMAGE_ABSORBED_BASE: float = 0.2

## Max extra END a single hit's damage adds to the absorbed-END gain (cap on the
## dmg / GAIN_END_DMG_TAKEN_DIVIDER term): taking a heavy blow is a bigger endurance test.
const GAIN_DAMAGE_ABSORBED_MAX_CONTRIB: float = 1.5

## Divisor mapping damage dealt to extra attacker STR: 10 dmg -> +1.0 (capped by
## GAIN_MELEE_HIT_MAX_DMG_CONTRIB).
const GAIN_HIT_STR_DAMAGE_DIVIDER: float = 10.0

## Divisor mapping damage absorbed to extra defender END: 15 dmg -> +1.0 (capped by
## GAIN_DAMAGE_ABSORBED_MAX_CONTRIB). Larger than the STR divider so END accrues more slowly
## than STR per point of damage.
const GAIN_END_DMG_TAKEN_DIVIDER: float = 15.0

## END baseline the patient trains from enduring blood peril during treatment
## (scaled up by GAIN_BLOOD_PERIL_END_SCALE as bleeding deepens).
const GAIN_BLOOD_PERIL_BASE: float = 0.8

# --- Parry outcome multipliers (fraction of base gains) ---
const GAIN_PARRY_DEFLECT_STR_MULT: float = 0.5

const GAIN_PARRY_DEFLECT_END_MULT: float = 0.5

const GAIN_PARRY_PARTIAL_STR_MULT: float = 0.3

## A partial parry still transmits some force into the defender's arm (less than a full deflect), so the
## defender earns a partial END gain for absorbing — consistent with the hit path (absorbing damage trains END).
const GAIN_PARRY_PARTIAL_END_MULT: float = 0.3

## A partial parry still met the line — reflex/timing was exercised, just less cleanly than a full deflect.
## Fraction of GAIN_PARRY_REFLEX_AGI_BASE; consistent with the partial END/STR multipliers.
const GAIN_PARRY_PARTIAL_AGI_MULT: float = 0.3

## A partial parry still read the attack line (the blade met it, just short of a clean catch), so the
## parrier earns a reduced perception read. Same 0.3 partial fraction as the STR/END/AGI parry multipliers.
const GAIN_PARRY_PARTIAL_PER_MULT: float = 0.3

# --- Opponent-difficulty scaling (desirable difficulty: beating a stronger foe teaches more) ---
## Reference opponent strength; beating a foe at this strength yields the baseline (1.0x) STR gain.
const GAIN_DIFFICULTY_STR_BASE: float = 100.0

## STR-gain change per point of opponent strength above/below the reference (0.005 -> +50 STR = +25%, -50 STR = -25%).
const GAIN_DIFFICULTY_STR_SCALE: float = 0.005

## Floor: beating a very weak foe still teaches a little (no negative learning).
const GAIN_DIFFICULTY_STR_MIN: float = 0.85

## Ceiling: beating an elite foe teaches up to 35% more (diminishing returns beyond this).
const GAIN_DIFFICULTY_STR_MAX: float = 1.35

# --- Medical patient END gain fraction (fraction of blood peril base) ---
## Fraction of GAIN_BLOOD_PERIL_BASE the patient trains END from enduring a medical treatment:
## enduring a procedure is real discomfort, but lighter load than a full uncontrolled hemorrhage.
const GAIN_MEDICAL_PATIENT_END_MULT: float = 0.5

## Fraction of GAIN_BLOOD_PERIL_BASE the patient trains END from direct-pressure hemostasis:
## pressing a wound shut for the duration of the act — sustained isometric effort, held still,
## so a smaller share than a full treatment.
const GAIN_DIRECT_PRESSURE_PATIENT_END_MULT: float = 0.25

## Realism: a patient enduring a medical treatment trains endurance in proportion to how badly they are
## bleeding — a fighter holding a tourniquet on a deep hemorrhage endures more than one bandaging a light
## scratch. This scales the patient-END gain from 1.0x at full blood volume to (1.0 + this) at empty.
const GAIN_BLOOD_PERIL_END_SCALE: float = 1.0

## Realism: a compromised (bleeding) fighter executes physical techniques less cleanly, so their
## offensive/defensive *physical* stat training (striking / dodging / absorbing / parrying) is reduced in
## proportion to blood lost. Purely cognitive training (the perception read of a parry) is unaffected.
## 1.0 at full blood, down to this floor at empty.
const GAIN_WOUNDED_WRITE_FLOOR: float = 0.5

# --- Direct pressure INT gain fraction (fraction of medical action base) ---
## Fraction of GAIN_MEDICAL_ACTION_BASE the medic trains INT from direct-pressure hemostasis:
## applying and holding pressure is a deliberate, judgment-laden technique (pressure point, force,
## duration), so it is the highest-value INT-earning medical act — but it is one technique within the
## broader medical skill, not the whole action, hence under the full base.
const GAIN_DIRECT_PRESSURE_INT_MULT: float = 0.8

# --- Severity multipliers ---
## AI wound-damage accounting: how much "damage" a wound of a given severity contributes when the AI
## sums the wounds it has dealt (CombatAIActionWeights). A monotonic severity score - only the
## relative ordering matters there, so it stays linear and is deliberately NOT the gain curve.
const SEVERITY_MULT: Dictionary = {
    "minor": 0.5,
    "moderate": 1.0,
    "severe": 1.5,
    "critical": 2.0,
}

## Gain-side severity curve (STR taught by landing a wound of a given severity). Decoupled from the
## AI score above: the marginal lesson of going severe->critical is smaller than linear, and the
## minor->moderate jump is proportionally larger. Uses the compressive clinical shape already
## established for SEVERITY_PAIN_MULTIPLIERS (Stevens' power law + NRS data), consistent with the
## power-law diminishing returns that govern the rest of the gain system.
const GAIN_SEVERE_WOUND_SEVERITY_MULT: Dictionary = {
    "minor": 0.4,
    "moderate": 1.0,
    "severe": 1.4,
    "critical": 1.7,
}

# --- Item type multipliers for medical INT gain ---
const MEDICAL_ITEM_MULT: Dictionary = {
    "bandage": 0.8,
    "pack": 1.2,
    "tourniquet": 1.5,
}

const SWING_VELOCITY_ECONOMY_FLOOR: float = 0.88

## 8b strike-mass coupling floor: impulsively-coupled effective mass improves with training tenure
## (Kacprzak 2025 Appl Sci; Walilko 2005), separate from strength/effort.
const STRIKE_MASS_COUPLING_FLOOR: float = 0.90

## 8c stamina waste max: motor learning cuts net metabolic power ~20% (Huang 2012; Finley 2013), so a
## green fighter spends more energy (and accrues more exhaustion) per nominal-intensity swing.
const SWING_STAMINA_WASTE_MAX: float = 1.22

## XCamp-4: use-based stat proficiency system.
## Static methods for stat gain rates, decay calculation, and training application.
## All public mutation methods check CompanyState.read_stub_proficiency_enabled() at entry.
##
## Gain tiers (diminishing returns): 0-5 = 1.0x, 6-10 = 0.7x, 11-20 = 0.4x, 21-30 = 0.2x, 31+ = 0.1x.
## Decay tiers (per-stat calibrated): 11-15 = -0.03/day, 16-20 = -0.05/day, 21-25 = -0.08/day,
## 26-30 = -0.12/day, 31+ = -0.17/day. Mirrors the gain tiers: the more specialized the skill, the
## faster it erodes without practice (a 31+ elite rusts up quicker than a 25-point veteran).
## Gain and decay use separate thresholds  -  gain follows a "proficiency level" model (novice|'elite),
## decay follows a "bonus magnitude" model calibrated for how quickly different magnitudes erode.
## Decay only applies to bonuses > 10.0  -  characters below +11 don't lose ground on basic training.
# Runtime preload ' circular dependency (CompanyState preloads CompanyCamp/Roster which preload EntityProficiency).
static var _company_state: Variant = null


static func _get_company_state() -> GDScript:
    if EntityProficiency._company_state == null:
        EntityProficiency._company_state = load("res://world/CompanyState.gd")
    return EntityProficiency._company_state


# --- Stance/form gain modifiers  -  derived from CombatWeaponForm._FORM_DEFS ---
## Maps form pressure class to stat training bonus profile.
## Aggressive forms |' strength bonus (overwhelming force).
## Defensive forms |' endurance bonus (durability under pressure).
## Controlling forms |' intelligence bonus (reading the fight).
## Neutral Ox |' agility + perception (thrust precision).
## Neutral Plow |' mixed endurance/agility (methodical spacing).
## Tempest is aggressive but gets unique STR/AGI treatment  -  checked before pressure match.


static func stance_mods_for_form(form: String) -> Dictionary:
    if form.is_empty():
        return {}
    var normalized: String = CombatWeaponForm.normalize_form(form)
    if normalized == CombatWeaponForm.FORM_TEMPEST:
        return {"strength": 1.18, "endurance": 1.0, "agility": 1.10}
    if normalized == CombatWeaponForm.FORM_OX:
        return {"strength": 1.10, "endurance": 1.0, "agility": 1.10, "perception": 1.10}
    if normalized == CombatWeaponForm.FORM_PLOW:
        return {"strength": 1.0, "endurance": 1.20, "agility": 1.05}
    if CombatWeaponForm.pressure_class_is(form, "aggressive"):
        return {"strength": 1.25, "endurance": 1.0}
    if CombatWeaponForm.pressure_class_is(form, "defensive"):
        return {"strength": 1.0, "endurance": 1.25}
    if CombatWeaponForm.pressure_class_is(form, "controlling"):
        return {"strength": 1.05, "endurance": 1.05, "intelligence": 1.15}
    return {"strength": 1.0, "endurance": 1.0}


## Realism: endurance training from enduring blood peril scales with how badly the patient is bleeding.
## A fighter holding a tourniquet on a deep hemorrhage endures far more than one bandaging a light scratch.
## Returns a multiplier in [1.0, 1.0 + GAIN_BLOOD_PERIL_END_SCALE] based on blood_volume (0..100).


static func blood_peril_end_factor(blood_volume: float) -> float:
    var peril: float = clampf((100.0 - blood_volume) / 100.0, 0.0, 1.0)
    return 1.0 + peril * GAIN_BLOOD_PERIL_END_SCALE


## Realism: a bleeding fighter executes physical techniques less cleanly, so the *physical* stat
## training earned this round is reduced in proportion to blood lost. Returns a multiplier in
## [GAIN_WOUNDED_WRITE_FLOOR, 1.0] based on blood_volume (0..100). At full blood it returns 1.0
## (no effect), so healthy fighters train exactly as before.


static func wounded_write_factor(blood_volume: float) -> float:
    var peril: float = clampf((100.0 - blood_volume) / 100.0, 0.0, 1.0)
    return 1.0 - peril * (1.0 - GAIN_WOUNDED_WRITE_FLOOR)


## Realism: execution quality gates physical training. A fighter in pain or with impaired
## consciousness executes techniques less cleanly, so the *physical* stat training earned on their
## action is reduced by the pain x consciousness performance component — the same combined
## modifier the combat system uses to degrade the fighter's actions (PainConsciousnessConstants.
## get_combined_performance_modifier, already clamped to MIN_PERFORMANCE_MODIFIER). Blood loss is
## deliberately excluded here: wounded_write_factor covers it, and the call site multiplies the
## two factors so the body and the mind degrade the same rep without double-counting. Purely
## cognitive training (perception reads) is unaffected. 1.0 for a healthy entity (no pain, full
## consciousness), so uncompromised fighters train exactly as before.


static func execution_quality_factor(entity: Node) -> float:
    if entity == null or not (entity is CoreEntity):
        return 1.0
    var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(entity)
    var cons: float = EntityPainConsciousness.get_effective_consciousness(entity)
    return PainConsciousnessConstants.get_combined_performance_modifier(pain, cons)


# --- Weapon type learning curve modifiers (keys match Weapon.weapon_type) ---

## Called during combat  -  adds to proficiency bonus with diminishing returns and weapon-form modifiers.


static func award_stat_gain(
    entity: CoreEntity, stat: String, raw_amount: float, weapon_id: String = "", form_str: String = ""
) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not "_proficiency_bonus" in entity:
        return
    if not _is_valid_stat(stat):
        return

    # Use Variant access to avoid GDScript 4 typed-dictionary member issues.
    var ce := entity as CoreEntity
    var prof_dict: Dictionary = ce._proficiency_bonus
    var current_bonus: float = 0.0
    if stat in prof_dict:
        current_bonus = maxf(0.0, float(prof_dict[stat]))
    else:
        current_bonus = 0.0
    var gain_mult: float = _get_gain_multiplier_for_float(current_bonus)
    var modified_amount: float = raw_amount * gain_mult

    # Apply stance/form modifier (derived from form pressure class)
    if not form_str.is_empty():
        var stance_mods := stance_mods_for_form(form_str)
        if stance_mods.has(stat):
            modified_amount *= float(stance_mods[stat])

    var wid: String = normalize_weapon_id(weapon_id)
    if not wid.is_empty() and WEAPON_CURVES.has(wid):
        var weapon_mods: Dictionary = WEAPON_CURVES[wid]
        if weapon_mods.has(stat):
            modified_amount *= float(weapon_mods[stat])

    var new_bonus: float = current_bonus + modified_amount
    prof_dict[stat] = new_bonus
    ce._proficiency_bonus = prof_dict


## Like award_stat_gain but without stance_mods lookup — for cognitive stats where form-dependent modifiers don't apply.


static func award_stat_gain_raw(entity: CoreEntity, stat: String, raw_amount: float) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not "_proficiency_bonus" in entity:
        return
    if not _is_valid_stat(stat):
        return
    var prof_dict: Dictionary = entity._proficiency_bonus
    var current_bonus: float = 0.0
    if stat in prof_dict:
        current_bonus = maxf(0.0, float(prof_dict[stat]))
    else:
        current_bonus = 0.0
    var gain_mult: float = _get_gain_multiplier_for_float(current_bonus)
    prof_dict[stat] = current_bonus + raw_amount * gain_mult
    entity._proficiency_bonus = prof_dict


static func normalize_weapon_id(weapon_id: String) -> String:
    return str(weapon_id).to_upper().strip_edges()


static func normalize_form_id(form: String) -> String:
    return CombatWeaponForm.normalize_form(form)


static func weapon_proficiency_value(entity: CoreEntity, weapon_id: String) -> float:
    if entity == null or not "_weapon_proficiency" in entity:
        return 0.0
    var wp_dict: Dictionary = entity._weapon_proficiency
    var wp_key: String = normalize_weapon_id(weapon_id)
    if wp_key in wp_dict:
        return float(wp_dict[wp_key])
    return 0.0


static func form_proficiency_value(entity: CoreEntity, form: String) -> float:
    if entity == null or not "_form_proficiency" in entity:
        return 0.0
    var fp_dict: Dictionary = entity._form_proficiency
    var fp_key: String = normalize_form_id(form)
    if fp_key in fp_dict:
        return float(fp_dict[fp_key])
    return 0.0


static func weapon_proficiency_tier(entity: CoreEntity, weapon_id: String) -> float:
    return clampf(weapon_proficiency_value(entity, weapon_id) / WEAPON_PROF_VETERAN_MAX, 0.0, 1.0)


static func form_proficiency_tier(entity: CoreEntity, form: String) -> float:
    return clampf(form_proficiency_value(entity, form) / FORM_PROF_VETERAN_MAX, 0.0, 1.0)


static func combined_aim_prof_tier(entity: CoreEntity, weapon_id: String, form: String) -> float:
    return clampf((weapon_proficiency_tier(entity, weapon_id) + form_proficiency_tier(entity, form)) * 0.5, 0.0, 1.0)


## Derived combat skill from accumulated weapon/form experience. Untracked fighters (enemies, test
## entities) stay at MELEE_SKILL_BASELINE (professional-soldier norm); proficiency-tracked fighters
## span MELEE_SKILL_UNSKILLED (0 experience) up to MELEE_SKILL_VETERAN_MAX at tier-1 familiarity.


static func melee_skill_for(entity: Node, weapon_id: String, form: String) -> float:
    var ce := entity as CoreEntity
    if ce == null or not "_combat_skill_trained" in entity or not bool(entity.get("_combat_skill_trained")):
        return MELEE_SKILL_BASELINE
    var tier: float = combined_aim_prof_tier(ce, weapon_id, form)
    return lerpf(MELEE_SKILL_UNSKILLED, MELEE_SKILL_VETERAN_MAX, tier)


## Effective-stat untrained holdback: tracks the gap between current per-stat proficiency bonus and
## UNSKILLED_BONUS_THRESHOLD (fades to 0 at threshold). Only proficiency-tracked fighters are held
## back — raw strength/agility stay intact, but technique-dependent output is reduced while green.


static func untrained_stat_penalty(entity: Node, stat_name: String) -> float:
    if not _get_company_state().read_stub_proficiency_enabled():
        return 0.0
    if entity == null or not "_combat_skill_trained" in entity or not bool(entity.get("_combat_skill_trained")):
        return 0.0
    if not "_proficiency_bonus" in entity:
        return 0.0
    var bonus: float = float(entity._proficiency_bonus.get(stat_name, 0.0))
    if bonus >= UNSKILLED_BONUS_THRESHOLD:
        return 0.0
    var lack: float = 1.0 - bonus / UNSKILLED_BONUS_THRESHOLD
    return maxf(0.0, lack * UNSKILLED_STAT_PENALTY_MAX)


## XCamp-4 write-side gate: only proficiency-tracked (party) fighters accrue stat/weapon/form gains.
## Untracked fighters (enemies, test doubles) stay flat at baseline — the read side already resolves
## them to MELEE_SKILL_BASELINE / no untrained penalty / swing tier 1.0, and letting them accumulate
## raw bonuses mid-fight would make untracked opponents progressively tougher within a battle.
## Mirrors the read-side `_combat_skill_trained` gate in `melee_skill_for` / `untrained_stat_penalty`.
## Applied at the combat award call sites (not inside the raw award functions, which the harness
## unit-tests directly on untracked entities to verify the gain math itself).


static func is_stat_gain_tracked(entity: Node) -> bool:
    if entity == null or not "_combat_skill_trained" in entity:
        return false
    return bool(entity.get("_combat_skill_trained"))


# --- Swing mechanics proficiency coupling (RESEARCH TOPIC 8) ---
## Training changes HOW a fighter produces a blow, not just whether it lands. Coupled to the same
## per-weapon/per-form combined tier as aim, so transfer is near-specific (sword skill carries partially
## to similar implements, poorly to unfamiliar ones) while raw stats carry over. Untracked fighters
## (enemies, test entities) and flag-off runs return tier 1.0 -> economy 1.0 -> no gameplay delta.
## 8a velocity economy floor: elite/junior contact-velocity ratio 5.557/4.874 m/s ~= 0.877 (PMC9798280).


## Single knob for the swing-mechanics economy: 1.0 = untracked / sim-off, else combined weapon+form tier.
static func is_swing_proficiency_tracked(entity: CoreEntity) -> bool:
    if not _get_company_state().read_stub_proficiency_enabled():
        return false
    if entity == null or not "_combat_skill_trained" in entity or not bool(entity.get("_combat_skill_trained")):
        return false
    return true


static func swing_proficiency_tier(entity: CoreEntity, weapon_id: String, form: String) -> float:
    if not is_swing_proficiency_tracked(entity):
        return 1.0
    return combined_aim_prof_tier(entity, weapon_id, form)


## Blade transfer economy: how much nominal swing velocity becomes contact velocity (multiplies v_base).


static func swing_velocity_economy(tier: float) -> float:
    return lerpf(SWING_VELOCITY_ECONOMY_FLOOR, 1.0, clampf(tier, 0.0, 1.0))


## Impulsive strike-mass coupling: effective mass multiplier at contact (>= 0.90 for tracked fighters).


static func strike_mass_coupling(tier: float) -> float:
    return lerpf(STRIKE_MASS_COUPLING_FLOOR, 1.0, clampf(tier, 0.0, 1.0))


## Metabolic economy: >1.0 multiplier on stamina attack cost (waste); 1.0 at veteran tier.


static func swing_stamina_economy(tier: float) -> float:
    return lerpf(SWING_STAMINA_WASTE_MAX, 1.0, clampf(tier, 0.0, 1.0))


## Fatigue resilience hold in [-0.5, +0.5]: veteran holds mechanical intensity later into effort, green
## loses more blade speed at the same stamina/exhaustion (scaled by FATIGUE_SKILL_HOLD_FLOOR_SPAN).


static func swing_skill_hold(tier: float) -> float:
    return lerpf(-0.5, 0.5, clampf(tier, 0.0, 1.0))


static func proficiency_occurrence_mult(entity: CoreEntity, weapon_id: String, form: String, move_id: String) -> float:
    if entity == null:
        return 1.0
    var wt: float = weapon_proficiency_tier(entity, weapon_id)
    var ft: float = form_proficiency_tier(entity, form)
    var sig: float = CombatWeaponForm.action_weight_mult(normalize_form_id(form), move_id, weapon_id)
    var boost: float = 1.0 + wt * 0.12 + ft * 0.08
    if sig > 1.05:
        boost += (sig - 1.0) * ft * 0.35
    return clampf(boost, 1.0, PROF_OCCURRENCE_MULT_MAX)


static func proficiency_aim_part_mult(entity: CoreEntity, weapon_id: String, form: String) -> float:
    if entity == null:
        return 1.0
    var tier: float = combined_aim_prof_tier(entity, weapon_id, form)
    return lerpf(1.0, PROF_AIM_MULT_MAX, tier)


static func intended_part_boost_mult(entity: CoreEntity, weapon_id: String, form: String) -> float:
    if entity == null:
        return PROF_INTENDED_PART_BOOST_MIN
    return lerpf(
        PROF_INTENDED_PART_BOOST_MIN, PROF_INTENDED_PART_BOOST_MAX, combined_aim_prof_tier(entity, weapon_id, form)
    )


## Gains are capped at the veteran max: past it, the tier (clamped to 1.0) changes nothing, so
## further points would be pure bookkeeping. The cap mirrors the decay floor that keeps stat
## bonuses honest at the top of the scale.


static func award_weapon_proficiency(entity: CoreEntity, weapon_id: String, raw_amount: float) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not "_weapon_proficiency" in entity:
        return
    var wid: String = normalize_weapon_id(weapon_id)
    if wid.is_empty():
        return
    var current: float = weapon_proficiency_value(entity, wid)
    if current >= WEAPON_PROF_VETERAN_MAX:
        return
    var gain_mult: float = _get_gain_multiplier_for_float(current)
    entity._weapon_proficiency[wid] = minf(current + raw_amount * gain_mult, WEAPON_PROF_VETERAN_MAX)


static func award_form_proficiency(entity: CoreEntity, form: String, raw_amount: float) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not "_form_proficiency" in entity:
        return
    var fid: String = normalize_form_id(form)
    if fid.is_empty():
        return
    var current: float = form_proficiency_value(entity, fid)
    if current >= FORM_PROF_VETERAN_MAX:
        return
    var gain_mult: float = _get_gain_multiplier_for_float(current)
    entity._form_proficiency[fid] = minf(current + raw_amount * gain_mult, FORM_PROF_VETERAN_MAX)


## Strike-time targeting proficiency: PER on off-focus, INT on preferred part, resources/weapons/form track.
## `write_factor` (blood-loss × execution-quality composite) gates the weapon/form motor-familiarity gains:
## a compromised fighter executes the swing less cleanly, so the rep practices weapon/form less.
## `cognitive_write_factor` (execution quality only, no blood) gates the INT/PER cognitive reads:
## a dazed or pained fighter reads the battlefield less sharply, so perception/intelligence gains are
## reduced. Blood loss is deliberately excluded from the cognitive factor — a bleeding but alert fighter
## still reads attacks at full sharpness.
## `difficulty_factor` (opponent-difficulty, desirable difficulty) scales the weapon/form motor gains
## like the hit STR gain: landing a clean hit on a *stronger* opponent is a sharper weapon-handling
## lesson. It also scales the off-focus PER read, which is an opponent-attention perception act
## (seeing where the defender is NOT guarding is harder against a sharper opponent). The
## preferred-part INT award is deliberately NOT difficulty-scaled: it rewards the attacker's own
## targeting execution (hitting the part the move prefers), which does not depend on the
## opponent's strength. 1.0 when the target's strength is unknown (no target / missing stats).


static func notify_targeting_gains_from_hit(
    entity: CoreEntity,
    weapon_id: String,
    form_str: String,
    move_def: Dictionary,
    hit_part: String,
    intended_part: String,
    defender_focus_part: String,
    write_factor: float = 1.0,
    cognitive_write_factor: float = 1.0,
    difficulty_factor: float = 1.0
) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null:
        return
    award_weapon_proficiency(entity, weapon_id, GAIN_WEAPON_PROF_HIT_BASE * write_factor * difficulty_factor)
    if not form_str.is_empty():
        award_form_proficiency(entity, form_str, GAIN_FORM_PROF_HIT_BASE * write_factor * difficulty_factor)
    var preferred: Array = []
    if "preferred_parts" in move_def and move_def["preferred_parts"] is Array:
        preferred = move_def["preferred_parts"] as Array
    if not intended_part.is_empty() and hit_part == intended_part:
        if not preferred.is_empty() and preferred.has(hit_part):
            award_stat_gain_raw(entity, "intelligence", GAIN_PREFERRED_PART_INT_BASE * cognitive_write_factor)
    if (
        not defender_focus_part.is_empty()
        and not intended_part.is_empty()
        and intended_part != defender_focus_part
        and hit_part == intended_part
    ):
        award_stat_gain_raw(
            entity, "perception", GAIN_OFF_FOCUS_HIT_PER_BASE * cognitive_write_factor * difficulty_factor
        )


## Called between contracts  -  applies decay for inactive mercenaries using calendar days.
## Decay is cumulative across one absence: `decay_inactivity_factor` sums the per-day geometric
## contributions over the whole gap, so each call must charge only the *new* days since the
## previous application (tracked on the entity via `last_decay_day`), not the entire span from
## `last_fought_day` again. Without that, every camp rest re-applies the full span to an
## already-decayed bonus and multiplies the loss (Topic 7d saturation shape broken).


static func apply_decay(entity: CoreEntity, current_day_index: int) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not "_proficiency_bonus" in entity:
        return

    var last_fought: int = 0
    if "last_fought_day" in entity:
        last_fought = int(entity.last_fought_day)
    elif "_last_fought_day" in entity:
        last_fought = int(entity.get("_last_fought_day"))
    if last_fought == 0:
        return  # Never fought  -  no combat bonuses to decay yet
    if current_day_index <= last_fought:
        return

    # High-water mark: the campaign day up to which decay has already been charged for this
    # absence. 0 is "unset" -> start from the fight day. A mark older than the fight (the fight
    # reset the anchor after the last decay) re-anchors to the fight.
    var decayed_through: int = int(entity.last_decay_day) if "last_decay_day" in entity else 0
    if decayed_through == 0:
        decayed_through = last_fought
    if decayed_through < last_fought:
        decayed_through = last_fought
    if current_day_index <= decayed_through:
        return

    # Marginal day-equivalents since the last application: the geometric forgetting-curve shape
    # (half-life ~ ln(2)/lambda ~ 11-12 days) summed over the not-yet-charged tail of the absence,
    # so rust lands fast early in a layoff and saturates rather than draining linearly (Topic 7d).
    var inactivity: float = (
        decay_inactivity_factor(current_day_index - last_fought)
        - decay_inactivity_factor(decayed_through - last_fought)
    )

    # Wounded mercenary protection: a fighter in the near-death zone (below the ATLS Class IV
    # triage-peril line, MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING = 55% remaining) is not "rusting"
    # from disuse; they're incapacitated. Decay x0.5 for BOTH stat bonuses and weapon/form
    # familiarity, so a gravely wounded merc is not double-penalized by losing technique on top
    # of losing their body. The threshold is read from the clinical triage constant so the decay
    # boundary and the field-care triage bands stay anchored to the same ATLS Class IV line.
    var bv: float = 100.0
    if "blood_volume" in entity:
        bv = float(entity.blood_volume)
    elif entity.has_method("_get_blood_volume"):
        bv = float(entity._get_blood_volume())
    var wounded_decay_mult: float = (
        DECAY_WOUNDED_INCAPACITATION_MULT if bv < BleedingConstants.MEDICAL_TRIAGE_PERIL_BLOOD_REMAINING else 1.0
    )

    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        var prof_dict: Dictionary = entity._proficiency_bonus
        var bonus: float = 0.0
        if stat in prof_dict:
            bonus = float(prof_dict[stat])
        if bonus <= float(PROFICIENCY_PROFICIENT_MAX):
            continue  # Only decay above the foundational (proficient) baseline

        var decay_mult: float = get_decay_multiplier(stat)
        var rate: float = _get_decay_rate_for_bonus(bonus)
        var daily_decay: float = rate * decay_mult * wounded_decay_mult

        var new_bonus: float = maxf(0.0, bonus + daily_decay * inactivity)
        prof_dict[stat] = new_bonus
        entity._proficiency_bonus = prof_dict

    # XCamp-4: weapon/form familiarity rusts over the same absence (shares `inactivity` + the
    # high-water mark below). Only the trained edge above the 10.0 foundational floor decays,
    # mirroring the stat rule; the flat rate (no per-stat mult) reflects pure use-based motor
    # learning. Gated on tracked: untracked fighters never accrue weapon/form (write-side gate),
    # so this is a no-op for them and they stay at baseline aim. The wounded protection above also
    # applies: an incapacitated fighter does not rust their blade-handling at full rate.
    if is_stat_gain_tracked(entity):
        var wf_rate: float = DECAY_RATE_WEAPON_FORM * wounded_decay_mult
        var wp_dict: Dictionary = entity._weapon_proficiency if "_weapon_proficiency" in entity else {}
        if not wp_dict.is_empty():
            for wid in wp_dict.keys():
                var wv: float = float(wp_dict[wid])
                if wv > float(PROFICIENCY_PROFICIENT_MAX):
                    wp_dict[wid] = maxf(0.0, wv + wf_rate * inactivity)
            entity._weapon_proficiency = wp_dict
        var fp_dict: Dictionary = entity._form_proficiency if "_form_proficiency" in entity else {}
        if not fp_dict.is_empty():
            for fid in fp_dict.keys():
                var fv: float = float(fp_dict[fid])
                if fv > float(PROFICIENCY_PROFICIENT_MAX):
                    fp_dict[fid] = maxf(0.0, fv + wf_rate * inactivity)
            entity._form_proficiency = fp_dict

    # Advance the high-water mark even when no stat lost points (all <= 10): those days are
    # consumed and must not be re-charged later if a bonus crosses above 10 mid-layoff.
    if "last_decay_day" in entity:
        entity.last_decay_day = current_day_index


## Called during camp drill  -  merges pending training into proficiency bonus.


static func merge_training_pending(entity: CoreEntity) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not entity.has_method("_get_training_pending"):
        return

    for stat in EntityStatsUtil.PROFICIENCY_STATS:
        var tp_dict: Dictionary = entity._get_training_pending()
        var pending: float = 0.0
        if stat in tp_dict:
            pending = float(tp_dict[stat])
        if pending > 0.0:
            var prof_dict: Dictionary = entity._proficiency_bonus
            var current: float = 0.0
            if stat in prof_dict:
                current = float(prof_dict[stat])
            # Same diminishing-returns curve as combat gains: a +1 drill at the elite
            # tier is worth less than one at the novice tier.
            var gain_mult: float = _get_gain_multiplier_for_float(current)
            prof_dict[stat] = current + pending * gain_mult
            entity._proficiency_bonus = prof_dict
            entity._set_training_pending_value(stat, 0.0)


## XCamp-6: camp drill merge for form proficiency. Mirrors merge_training_pending: applies queued
## drills through the diminishing-returns curve, caps at FORM_PROF_VETERAN_MAX, clears the queue.


static func merge_form_training_pending(entity: CoreEntity) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not entity.has_method("_get_form_training_pending"):
        return
    var tp_dict: Dictionary = entity._get_form_training_pending()
    for form in tp_dict:
        var pending: float = float(tp_dict[form])
        if pending <= 0.0:
            continue
        var fp_dict: Dictionary = entity._form_proficiency
        var current: float = float(fp_dict.get(form, 0.0))
        var gain_mult: float = _get_gain_multiplier_for_float(current)
        fp_dict[form] = minf(current + pending * DRILL_FORM_GAIN_BASE * gain_mult, FORM_PROF_VETERAN_MAX)
        entity._form_proficiency = fp_dict
        entity._set_form_training_pending_value(form, 0.0)


## XCamp-6: camp drill merge for weapon proficiency. Mirrors merge_form_training_pending.


static func merge_weapon_training_pending(entity: CoreEntity) -> void:
    if not _get_company_state().read_stub_proficiency_enabled():
        return
    if entity == null or not entity.has_method("_get_weapon_training_pending"):
        return
    var tp_dict: Dictionary = entity._get_weapon_training_pending()
    for weapon_id in tp_dict:
        var pending: float = float(tp_dict[weapon_id])
        if pending <= 0.0:
            continue
        var wp_dict: Dictionary = entity._weapon_proficiency
        var current: float = float(wp_dict.get(weapon_id, 0.0))
        var gain_mult: float = _get_gain_multiplier_for_float(current)
        wp_dict[weapon_id] = minf(current + pending * DRILL_WEAPON_GAIN_BASE * gain_mult, WEAPON_PROF_VETERAN_MAX)
        entity._weapon_proficiency = wp_dict
        entity._set_weapon_training_pending_value(weapon_id, 0.0)


## Returns the gain rate multiplier for current proficiency level (float version  -  no truncation).


static func _get_gain_multiplier_for_float(proficiency_bonus: float) -> float:
    if proficiency_bonus <= float(PROFICIENCY_NOVICE_MAX):
        return 1.0
    if proficiency_bonus <= float(PROFICIENCY_PROFICIENT_MAX):
        return 0.7
    if proficiency_bonus <= float(PROFICIENCY_VETERAN_MAX):
        return 0.4
    if proficiency_bonus <= float(PROFICIENCY_ELITE_MAX):
        return 0.2
    return 0.1


## Returns the per-stat decay multiplier based on real-world research.


static func get_decay_multiplier(stat: String) -> float:
    match stat:
        "endurance":
            return DECAY_MULT_END
        "agility":
            return DECAY_MULT_AGI
        "perception":
            return DECAY_MULT_PER
        "strength":
            return DECAY_MULT_STR
        "intelligence":
            return DECAY_MULT_INT
    return 1.0


## Returns the medical item type multiplier for INT gain.


static func get_medical_item_mult(item_type: String) -> float:
    if item_type in MEDICAL_ITEM_MULT:
        return float(MEDICAL_ITEM_MULT[item_type])
    return 1.0


## Returns the gain-side severity multiplier for wound-based STR gain.
## Uses GAIN_SEVERE_WOUND_SEVERITY_MULT (compressive clinical shape), decoupled from the AI
## wound-damage score (SEVERITY_MULT) so each can be tuned to its own realism.


static func get_severity_mult(severity: String) -> float:
    if severity in GAIN_SEVERE_WOUND_SEVERITY_MULT:
        return float(GAIN_SEVERE_WOUND_SEVERITY_MULT[severity])
    return 1.0


## Opponent-difficulty multiplier for attacker STR gain (desirable-difficulty principle): beating a stronger
## foe (higher target strength) yields more learning, a weaker foe yields less. The reference is the attacker's
## own effective strength when provided (self-relative: a near-level bout is the 1.0 baseline), else
## GAIN_DIFFICULTY_STR_BASE. Scales linearly by GAIN_DIFFICULTY_STR_SCALE, clamped to
## [GAIN_DIFFICULTY_STR_MIN, GAIN_DIFFICULTY_STR_MAX].


static func opponent_difficulty_mult(target_strength: float, own_strength: float = 0.0) -> float:
    var ref_strength: float = own_strength if own_strength > 0.0 else GAIN_DIFFICULTY_STR_BASE
    return clampf(
        1.0 + (target_strength - ref_strength) * GAIN_DIFFICULTY_STR_SCALE,
        GAIN_DIFFICULTY_STR_MIN,
        GAIN_DIFFICULTY_STR_MAX
    )


# --- Internal helpers ---


static func _is_valid_stat(stat: String) -> bool:
    return stat in EntityStatsUtil.PROFICIENCY_STATS


static func _get_decay_rate_for_bonus(bonus: float) -> float:
    if bonus <= DECAY_THRESHOLD_NOVICE_MAX:
        return DECAY_RATE_NOVICE_PLUS
    if bonus <= DECAY_THRESHOLD_PROFICIENT_MAX:
        return DECAY_RATE_PROFICIENT_PLUS
    if bonus <= DECAY_THRESHOLD_VETERAN_MAX:
        return DECAY_RATE_VETERAN_PLUS
    if bonus <= DECAY_THRESHOLD_ELITE_MAX:
        return DECAY_RATE_ELITE_PLUS
    return DECAY_RATE_MASTER_PLUS


## Forgetting-curve / detraining shape across inactive days (Topic 7d).
## Returns the effective "day-equivalents" of decay over N inactive days: 1.0 on day 1, falling
## geometrically each day, summed to a saturation bound. Models skill rusting fastest early in a
## layoff and plateauing later - real cardiovascular/motor detraining loses most ground in the
## first ~2 weeks, not at a constant rate forever. Purely a shape factor on top of the per-day
## rate; lam=0.0 restores the legacy pure-linear behaviour (factor == N).


static func decay_inactivity_factor(inactive_days: int) -> float:
    if inactive_days <= 0:
        return 0.0
    var lam: float = DECAY_DAY_DIMINISH_LAMBDA
    if lam <= 0.0:
        return float(inactive_days)
    var denom: float = 1.0 - exp(-lam)
    return (1.0 - exp(-lam * float(inactive_days))) / denom
