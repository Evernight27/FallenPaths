class_name InfectionStagingTests
extends CombatRegressionHarnessCore
## CAMP-INF-1: staged infection (clean -> localized -> septic) + entity-level sepsis.
## Tests the day-advance progression, susceptibility multipliers, entity-level death wiring,
## source-controlled resolve, and the A3 sepsis combat tells. Campaign-only (never mid-battle).


static func _free_entity_fixture(n: Node) -> void:
    _free_harness_node(n)


## Seed a single wound on a part, ready for a healing advance.
static func _seed_wound(ent: Node, part: String, severity: String = BleedingConstants.SEVERITY_SEVERE) -> Dictionary:
    var wound: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": severity,
        "sub_region": "",
        "cumulative_damage": 2.0,
        "current_bleeding_rate": 0.0,
        "base_bleeding_rate": 0.0,
        "is_arterial": false,
        "is_stabilized": true,
        "penetration_to_tissue_mm": -1.0,
        "created_at_game_time": 0.0,
        "healing_duration_seconds": 4.0 * HealingConstants.SECONDS_PER_DAY,
    }
    ent.wounds[part] = [wound]
    return wound


## A severe untreated wound infects (stage 0 -> 1) within a few day advances.
static func _run_infection_stage0_to_1_progression(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    # Critical (base 0.50/day) crosses the 1.0 progress threshold in ~2 days; a severe wound (0.30/day)
    # would not reach it in 3 days, so this test pins the severity for a deterministic margin.
    _seed_wound(ent, "right_arm", BleedingConstants.SEVERITY_CRITICAL)
    ent._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    var w: Dictionary = ent.wounds.get("right_arm", [{}])[0]
    var stage: int = int(w.get("infection_stage", 0))
    if stage < 1 or not w.get("is_infected", false):
        _fail(
            failures,
            (
                "infection_stage: severe untreated wound should be >= stage 1 after 3 days (stage=%d infected=%s)"
                % [stage, str(w.get("is_infected", false))]
            )
        )
    # Track-(a) resolution duration must have been extended one-way on the flip.
    if float(w.get("healing_duration_seconds", 0.0)) <= 4.0 * HealingConstants.SECONDS_PER_DAY:
        _fail(failures, "infection_stage: track-(a) duration should be extended on the stage-0->1 flip")
    _free_entity_fixture(ent)


## A localized infection left untreated becomes septic and flips the entity is_septic flag.
static func _run_infection_stage1_to_2_sepsis(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = _seed_wound(ent, "right_arm")
    w["infection_stage"] = 1
    w["is_infected"] = true
    w["infection_progress"] = 1.0
    ent._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    var stage: int = int(ent.wounds.get("right_arm", [{}])[0].get("infection_stage", 0))
    if stage < 2:
        _fail(
            failures, "infection_sepsis: localized wound should reach stage 2 after 3 untreated days (stage=%d)" % stage
        )
    if not ent.is_septic:
        _fail(failures, "infection_sepsis: entity.is_septic should be set when any wound reaches stage 2")
    _free_entity_fixture(ent)


## A localized infection whose part has definitive hemostasis (bandaged) does not go systemic.
static func _run_treated_stage1_stalls_sepsis(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = _seed_wound(ent, "right_arm")
    w["infection_stage"] = 1
    w["is_infected"] = true
    w["infection_progress"] = 1.0
    ent.bandaged_parts["right_arm"] = true  # definitive hemostasis -> source controlled
    ent._process_healing(10 * HealingConstants.SECONDS_PER_DAY)
    var stage: int = int(ent.wounds.get("right_arm", [{}])[0].get("infection_stage", 0))
    if stage >= 2:
        _fail(failures, "infection_stall: treated localized wound should not progress to septic (stage=%d)" % stage)
    if ent.is_septic:
        _fail(failures, "infection_stall: treated localized wound should not set entity is_septic")
    _free_entity_fixture(ent)


## Sepsis needs an open tract: a closed contusion (bruise) or a clean (non-compound) fracture has no
## entry portal, so the per-day infection dose is zero — it never localizes even at critical severity
## (0.50/day would cross 1.0 in ~2 days if un-gated). This mirrors the open-wound boundary the scar
## mint uses (CAMP-SCAR-1 §2.3): a closed injury neither gets infected nor remodels into scar tissue.
## The gate is entry-only: a bruise already infected (legacy save, stage 1) still progresses to septic,
## and an open cut control still localizes under the same advance (pin is not vacuous).
static func _run_closed_injuries_never_localize(failures: PackedStringArray) -> void:
    var bruise: Node = _new_entity("SWORD")
    var wb: Dictionary = _seed_wound(bruise, "right_arm", BleedingConstants.SEVERITY_CRITICAL)
    wb["injury_type"] = BleedingConstants.INJURY_TYPE_BRUISE
    bruise._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    var w_b: Dictionary = bruise.wounds.get("right_arm", [{}])[0]
    if int(w_b.get("infection_stage", 0)) >= 1 or w_b.get("is_infected", false):
        _fail(
            failures,
            (
                "infection_entry: a critical bruise must never localize (stage=%d infected=%s)"
                % [int(w_b.get("infection_stage", 0)), str(w_b.get("is_infected", false))]
            )
        )
    var frac: Node = _new_entity("SWORD")
    var wf: Dictionary = _seed_wound(frac, "left_leg", BleedingConstants.SEVERITY_CRITICAL)
    wf["injury_type"] = BleedingConstants.INJURY_TYPE_FRACTURE
    frac._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    var w_f: Dictionary = frac.wounds.get("left_leg", [{}])[0]
    if int(w_f.get("infection_stage", 0)) >= 1 or w_f.get("is_infected", false):
        _fail(
            failures,
            (
                "infection_entry: a clean fracture must never localize (stage=%d infected=%s)"
                % [int(w_f.get("infection_stage", 0)), str(w_f.get("is_infected", false))]
            )
        )
    var cut: Node = _new_entity("SWORD")
    _seed_wound(cut, "right_arm", BleedingConstants.SEVERITY_CRITICAL)
    cut._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    if int(cut.wounds.get("right_arm", [{}])[0].get("infection_stage", 0)) < 1:
        _fail(failures, "infection_entry: open cut control should localize under the same 3-day advance")
    var pre: Node = _new_entity("SWORD")
    var wp: Dictionary = _seed_wound(pre, "right_arm")
    wp["injury_type"] = BleedingConstants.INJURY_TYPE_BRUISE
    wp["infection_stage"] = 1
    wp["is_infected"] = true
    wp["infection_progress"] = 1.0
    pre._process_healing(3 * HealingConstants.SECONDS_PER_DAY)
    if int(pre.wounds.get("right_arm", [{}])[0].get("infection_stage", 0)) < 2:
        _fail(failures, "infection_entry: an already-infected closed wound must still progress to septic")
    _free_entity_fixture(bruise)
    _free_entity_fixture(frac)
    _free_entity_fixture(cut)
    _free_entity_fixture(pre)


## Legacy single-stage mode must use the SAME per-day dose as staged (plan §1 source of truth):
## base severity risk × contamination × susceptibility, capped. White-boxes the legacy seam directly
## (it only runs when the staging gate is off). A contaminated stump takes the ×1.75 contamination
## boost in legacy mode too; a plain cut accrues the plain base. Both must equal the shared dose seam.
static func _run_legacy_infection_uses_full_dose(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var stump: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_CRITICAL,
        "is_stump": true,
        "is_compound_fracture": false,
        "is_arterial": false,
    }
    var s_dose: float = BleedingConstants.wound_infection_daily_dose(ent, stump, false)
    if not (s_dose > BleedingConstants.wound_infection_daily_risk(stump, false)):
        _fail(
            failures,
            (
                "legacy_dose: a contaminated stump dose must exceed the bare base risk (%.3f vs %.3f)"
                % [s_dose, BleedingConstants.wound_infection_daily_risk(stump, false)]
            )
        )
    EntityHealing._advance_infection_legacy(ent, stump, false, 1.0)
    if absf(float(stump.get("infection_progress", 0.0)) - s_dose) > 1e-6:
        _fail(
            failures,
            (
                "legacy_dose: legacy mode must apply the full shared dose (%.3f vs %.3f)"
                % [float(stump.get("infection_progress", 0.0)), s_dose]
            )
        )
    if bool(stump.get("is_infected", false)):
        _fail(failures, "legacy_dose: dose %.3f < 1.0 must not flip is_infected in one day" % s_dose)
    var plain: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_CRITICAL,
        "is_stump": false,
        "is_compound_fracture": false,
        "is_arterial": false,
    }
    var p_dose: float = BleedingConstants.wound_infection_daily_dose(ent, plain, false)
    EntityHealing._advance_infection_legacy(ent, plain, false, 2.0)
    if absf(float(plain.get("infection_progress", 0.0)) - 2.0 * p_dose) > 1e-6:
        _fail(
            failures,
            (
                "legacy_dose: plain cut must accrue 2 days of the base dose (%.3f vs %.3f)"
                % [float(plain.get("infection_progress", 0.0)), 2.0 * p_dose]
            )
        )
    _free_entity_fixture(ent)


## Starvation raises the per-day infection dose (susceptibility).
static func _run_susceptibility_starvation_raises_dose(failures: PackedStringArray) -> void:
    var fed: Node = _new_entity("SWORD")
    var starved: Node = _new_entity("SWORD")
    fed.set_nutrition_level(1.0)
    starved.set_nutrition_level(0.0)
    var part: String = "right_arm"
    var injury: Dictionary = {
        "severity": BleedingConstants.SEVERITY_MODERATE, "injury_type": BleedingConstants.INJURY_TYPE_CUT
    }
    var d_fed: float = BleedingConstants.wound_infection_daily_dose(fed, injury, false)
    var d_starved: float = BleedingConstants.wound_infection_daily_dose(starved, injury, false)
    if not (d_starved > d_fed):
        _fail(
            failures,
            "infection_susceptibility: starving dose (%.3f) should exceed well-fed dose (%.3f)" % [d_starved, d_fed]
        )
    if d_starved > BleedingConstants.INFECTION_DAILY_DOSE_CAP + 1e-9:
        _fail(
            failures,
            "infection_susceptibility: dose should be capped at INFECTION_DAILY_DOSE_CAP (got %.3f)" % d_starved
        )
    _free_entity_fixture(fed)
    _free_entity_fixture(starved)


## The per-day infection dose is capped after all susceptibility multipliers.
static func _run_infection_daily_dose_cap(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.set_nutrition_level(0.0)
    ent.campaign_fatigue = 1.0
    var injury: Dictionary = {
        "severity": BleedingConstants.SEVERITY_CRITICAL,
        "is_compound_fracture": true,
        "is_arterial": true,
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "penetration_to_tissue_mm": 10.0
    }
    var dose: float = BleedingConstants.wound_infection_daily_dose(ent, injury, false)
    if dose > BleedingConstants.INFECTION_DAILY_DOSE_CAP + 1e-9:
        _fail(
            failures,
            (
                "infection_dose_cap: worst-case dose (%.3f) should be capped at %.3f"
                % [dose, BleedingConstants.INFECTION_DAILY_DOSE_CAP]
            )
        )
    _free_entity_fixture(ent)


## The sepsis death flag folds into is_dead() (campaign polls is_dead to reconcile the roster).
static func _run_sepsis_is_dead_fold(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    if ent.is_dead():
        _fail(failures, "sepsis_is_dead: healthy entity should not be dead")
    ent._sepsis_dead = true
    if not ent.is_dead():
        _fail(failures, "sepsis_is_dead: _sepsis_dead should make is_dead() true")
    var reason: String = ent._get_death_reason()
    if not reason.begins_with("sepsis"):
        _fail(failures, "sepsis_is_dead: _get_death_reason should report sepsis (got %s)" % reason)
    _free_entity_fixture(ent)


## A septic member's campaign stamina cap is reduced by SEPSIS_STAMINA_MULT.
static func _run_sepsis_stamina_mult(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var healthy: float = ent._get_campaign_stamina_mult()
    ent.is_septic = true
    var septic: float = ent._get_campaign_stamina_mult()
    if not (septic < healthy):
        _fail(failures, "sepsis_stamina: septic stamina mult (%.3f) should be below healthy (%.3f)" % [septic, healthy])
    var expected: float = healthy * BleedingConstants.SEPSIS_STAMINA_MULT
    if absf(septic - expected) > 0.02:
        _fail(
            failures,
            "sepsis_stamina: septic mult (%.3f) should be ~healthy * SEPSIS_STAMINA_MULT (%.3f)" % [septic, expected]
        )
    _free_entity_fixture(ent)


## A septic focus that is source-controlled accrues resolve progress and can recover.
static func _run_source_controlled_sepsis_resolves(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = _seed_wound(ent, "right_arm")
    w["infection_stage"] = 2
    w["is_infected"] = true
    w["sepsis_progress"] = 1.0
    ent.is_septic = true
    ent.bandaged_parts["right_arm"] = true  # source controlled
    # Run several days; the resolve accrual is deterministic once source-controlled. A sepsis death
    # roll may also fire on some days, which is a valid outcome -- assert the invariant instead.
    for day in range(20):
        seed(90000 + day)
        ent._process_healing(HealingConstants.SECONDS_PER_DAY)
        if not ent.is_septic:
            break
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if ent.is_septic and ent._sepsis_dead == false and ent.sepsis_resolve_progress < 1.0:
        _fail(
            failures,
            (
                (
                    "sepsis_resolve: source-controlled sepsis should either resolve (is_septic false) or reach resolve "
                    + "1.0 (got progress=%.2f)"
                )
                % ent.sepsis_resolve_progress
            )
        )
    _free_entity_fixture(ent)


## Sepsis death risk is lower when source-controlled than when the focus is untreated.
static func _run_source_controlled_death_risk_lower(failures: PackedStringArray) -> void:
    if not (BleedingConstants.SEPSIS_DEATH_RISK_SOURCE_CONTROLLED < BleedingConstants.SEPSIS_DEATH_RISK_PER_DAY):
        _fail(failures, "sepsis_risk: source-controlled death risk should be below untreated")


## A septic (stage 2) focus is not cleared by a simple dressing -- source control (amputation) is required.
static func _run_septic_not_cleared_by_dressing(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = _seed_wound(ent, "right_arm", BleedingConstants.SEVERITY_CRITICAL)
    w["infection_stage"] = 2
    w["is_infected"] = true
    w["sepsis_progress"] = 1.0
    seed(884410)
    ent._apply_bandage("right_arm", 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var stage_after: int = int(ent.wounds.get("right_arm", [{}])[0].get("infection_stage", 0))
    if stage_after < 2:
        _fail(
            failures,
            (
                "septic_dressing: a stage-2 septic focus should not be cleared by a plain bandage (stage after=%d)"
                % stage_after
            )
        )
    _free_entity_fixture(ent)


## The A3 combat tells: sepsis degrades the performance modifier (perception) for a septic member.
static func _run_sepsis_performance_tell(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var healthy: float = EntityPainConsciousness.get_performance_modifier(ent)
    ent.is_septic = true
    var septic: float = EntityPainConsciousness.get_performance_modifier(ent)
    if not (septic < healthy):
        _fail(
            failures,
            "sepsis_perf: septic performance modifier (%.3f) should be below healthy (%.3f)" % [septic, healthy]
        )
    _free_entity_fixture(ent)


## Stage-1 localized infection adds a per-part pain penalty (INFECTION_LOCALIZED_PAIN_MULT).
static func _run_localized_infection_pain_mult(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var localized: Node = _new_entity("SWORD")
    for e in [clean, localized]:
        var max_t: float = float(e.body_max.get("right_arm", 0.0))
        e.body_cutting["right_arm"] = max_t * 0.5
        var w: Dictionary = _seed_wound(e, "right_arm")
        # Give the wound some age so healing progress is partial (pain > 0).
        e._game_time_seconds = 1.0 * HealingConstants.SECONDS_PER_DAY
    # Localized: mark stage 1 + infected on the localized entity's wound.
    var lw: Dictionary = localized.wounds["right_arm"][0]
    lw["infection_stage"] = 1
    lw["is_infected"] = true
    var p_clean: float = EntityPainConsciousness.get_pain_for_part(clean, "right_arm")
    var p_local: float = EntityPainConsciousness.get_pain_for_part(localized, "right_arm")
    if p_clean <= 0.0:
        _fail(failures, "localized_pain: clean-part pain should be > 0 for a fresh wound (got %.3f)" % p_clean)
    if not (p_local > p_clean):
        _fail(
            failures,
            (
                "localized_pain: localized-infection part pain (%.3f) should exceed clean part pain (%.3f)"
                % [p_local, p_clean]
            )
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(localized)


## Golden-period realism: the infection dose is front-loaded in a wound's life. The freshness
## factor is 1.0 for a fresh wound, monotonically non-increasing with age, and floors (never
## below) WOUND_INFECTION_FRESHNESS_FLOOR once the wound has aged past the fresh window.
static func _run_infection_freshness_factor(failures: PackedStringArray) -> void:
    var fresh: float = BleedingConstants.infection_freshness_factor(0.0)
    if absf(fresh - 1.0) > 1e-9:
        _fail(failures, "freshness: a fresh wound (age 0) must have factor 1.0 (got %.3f)" % fresh)
    var window: float = BleedingConstants.INFECTION_FRESH_WINDOW_DAYS
    var floor: float = BleedingConstants.WOUND_INFECTION_FRESHNESS_FLOOR
    var at_half: float = BleedingConstants.infection_freshness_factor(window * 0.5)
    var at_end: float = BleedingConstants.infection_freshness_factor(window)
    var beyond: float = BleedingConstants.infection_freshness_factor(window * 3.0)
    # Monotonically non-increasing with age.
    if not (fresh >= at_half and at_half >= at_end):
        _fail(
            failures,
            "freshness: factor must be non-increasing in age (fresh=%.3f half=%.3f end=%.3f)" % [fresh, at_half, at_end]
        )
    # Never drops below the floor, and a fully-aged wound sits exactly at the floor.
    if at_end < floor - 1e-9 or beyond < floor - 1e-9:
        _fail(
            failures,
            (
                "freshness: factor must floor at WOUND_INFECTION_FRESHNESS_FLOOR (end=%.3f beyond=%.3f floor=%.3f)"
                % [at_end, beyond, floor]
            )
        )
    if absf(beyond - floor) > 1e-6:
        _fail(
            failures,
            "freshness: beyond the window the factor must equal the floor (got %.3f vs %.3f)" % [beyond, floor]
        )
    # A mid-life wound must actually be reduced below the fresh value (the point of the decay).
    if not (at_half < fresh - 1e-9):
        _fail(
            failures,
            (
                "freshness: an aging wound must have a reduced (not full) dose factor (half=%.3f vs fresh=%.3f)"
                % [at_half, fresh]
            )
        )


## End-to-end: the stage-0 daily dose is lower for an aged wound than an otherwise-identical fresh
## wound (the freshness decay is applied inside _advance_infection_stage, so verify it through the
## real day-advance: an aged wound accumulates less infection_progress per day than a fresh one).
static func _run_infection_dose_decays_with_age(failures: PackedStringArray) -> void:
    # Two identical severe untreated wounds, both made at game-time 0. The "aged" entity's clock is
    # 2 days ahead, so after a 1-day advance its wound is 3 days old vs the fresh one's 1 day. (Both
    # stay under the 0.95 resolve threshold, so neither is removed before we can read its dose.)
    var fresh_ent: Node = _new_entity("SWORD")
    var aged_ent: Node = _new_entity("SWORD")
    _seed_wound(fresh_ent, "left_leg")
    _seed_wound(aged_ent, "left_leg")
    aged_ent._game_time_seconds = 2.0 * HealingConstants.SECONDS_PER_DAY
    # One day advance each (fresh wound now 1 day old; aged wound now 3 days old).
    fresh_ent._process_healing(HealingConstants.SECONDS_PER_DAY)
    aged_ent._process_healing(HealingConstants.SECONDS_PER_DAY)
    var p_fresh: float = float(fresh_ent.wounds["left_leg"][0].get("infection_progress", 0.0))
    var p_aged: float = float(aged_ent.wounds["left_leg"][0].get("infection_progress", 0.0))
    if not (p_aged < p_fresh):
        _fail(
            failures,
            (
                "freshness_e2e: aged wound must accrue less infection_progress than a fresh one (aged=%.4f fresh=%.4f)"
                % [p_aged, p_fresh]
            )
        )
    _free_entity_fixture(fresh_ent)
    _free_entity_fixture(aged_ent)


## Realism: inflamed/infected tissue is hyperemic and bleeds more readily. An infected wound
## (stage >= 1) should produce a higher part bleed rate than an otherwise-identical clean wound.
static func _run_infection_bleed_mult(failures: PackedStringArray) -> void:
    var clean: Node = _new_entity("SWORD")
    var infected: Node = _new_entity("SWORD")
    _seed_wound(clean, "right_arm")
    _seed_wound(infected, "right_arm")
    var iw: Dictionary = infected.wounds["right_arm"][0]
    iw["infection_stage"] = 1
    iw["is_infected"] = true
    iw["current_bleeding_rate"] = 0.3
    iw["base_bleeding_rate"] = 0.3
    var cw: Dictionary = clean.wounds["right_arm"][0]
    cw["current_bleeding_rate"] = 0.3
    cw["base_bleeding_rate"] = 0.3
    var rate_clean: float = EntityWounds.get_bleeding_rate_for_part(clean, "right_arm")
    var rate_inf: float = EntityWounds.get_bleeding_rate_for_part(infected, "right_arm")
    if not (rate_inf > rate_clean):
        _fail(
            failures,
            "infection_bleed: infected part rate (%.4f) should exceed clean part rate (%.4f)" % [rate_inf, rate_clean]
        )
    var expected: float = rate_clean * BleedingConstants.WOUND_INFECTION_BLEED_MULT
    if absf(rate_inf - expected) > 0.001:
        _fail(
            failures,
            (
                "infection_bleed: infected rate (%.4f) should be ~clean * WOUND_INFECTION_BLEED_MULT (%.4f)"
                % [rate_inf, expected]
            )
        )
    _free_entity_fixture(clean)
    _free_entity_fixture(infected)


## Dismemberment realism: a traumatic amputation stump is a raw, devitalized, open wound — always
## auto-contaminated (seeds tetanus + takes the infection-dose boost) even though its depth is unknown.
## A shallow clean cut stays uncontaminated.
static func _run_stump_is_contaminated(failures: PackedStringArray) -> void:
    var stump: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT, "is_stump": true, "penetration_to_tissue_mm": -1.0
    }
    var shallow_cut: Dictionary = {"injury_type": BleedingConstants.INJURY_TYPE_CUT, "penetration_to_tissue_mm": 2.0}
    if not BleedingConstants.is_wound_contaminated(stump):
        _fail(failures, "stump_contam: a raw stump should be auto-contaminated (tetanus/infection)")
    if BleedingConstants.is_wound_contaminated(shallow_cut):
        _fail(failures, "stump_contam: a shallow clean cut should not be contaminated")


## Dismemberment realism: a stump is a prime gas-gangrene substrate (devitalized + open); a shallow
## clean cut is not a candidate. Historical leading cause of amputation mortality (plan §10.1).
static func _run_stump_is_gangrene_candidate(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var stump: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_CRITICAL,
        "is_stump": true,
        "penetration_to_tissue_mm": -1.0
    }
    var shallow_cut: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_MODERATE,
        "penetration_to_tissue_mm": 2.0
    }
    if not BleedingConstants.is_gangrene_candidate(ent, "right_arm", stump):
        _fail(failures, "stump_gangrene: a raw stump should be a gas-gangrene candidate")
    if BleedingConstants.is_gangrene_candidate(ent, "right_arm", shallow_cut):
        _fail(failures, "stump_gangrene: a shallow clean cut should not be a gangrene candidate")
    _free_entity_fixture(ent)


## Debridement counter-play (plan §10.2): a deep cut is contaminated by default and takes the
## WOUND_INFECTION_CONTAMINATED_MULT dose boost; setting `debrided` clears the contamination, drops
## the per-day infection dose, and stops the tetanus candidacy. A debrided stump stays contaminated
## (raw amputation surface). Deterministic — `is_wound_contaminated` + the dose are RNG-free.
static func _run_debride_reduces_contamination(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": BleedingConstants.SEVERITY_SEVERE,
        "penetration_to_tissue_mm": 8.0,
        "is_arterial": false,
        "is_stabilized": false,
    }
    if not BleedingConstants.is_wound_contaminated(w):
        _fail(failures, "debride: a deep untreated cut should be contaminated by default")
    var dose_contam: float = BleedingConstants.wound_infection_daily_dose(ent, w, false)
    w["debrided"] = true
    if BleedingConstants.is_wound_contaminated(w):
        _fail(failures, "debride: a debrided cut should no longer be contaminated")
    var dose_debrided: float = BleedingConstants.wound_infection_daily_dose(ent, w, false)
    if not (dose_debrided < dose_contam):
        _fail(
            failures,
            "debride: debrided dose (%.4f) must be below contaminated dose (%.4f)" % [dose_debrided, dose_contam]
        )
    var stump: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "is_stump": true,
        "debrided": true,
        "penetration_to_tissue_mm": -1.0
    }
    if not BleedingConstants.is_wound_contaminated(stump):
        _fail(failures, "debride: a debrided stump should stay contaminated (raw amputation surface)")
    _free_entity_fixture(ent)


## Live wiring: a successful clean bandage debrides a contaminated deep cut (the counter-play the
## §10.2 constant promises). Bandage success is a roll, so sweep seeds and assert (a) at least one
## succeeded and (b) every success left the wound debrided (is_wound_contaminated -> false). Chest
## (non-limb) + zero bleed rate sidesteps the TQ-indication and compression preconditions.
static func _run_debride_live_wiring(failures: PackedStringArray) -> void:
    var any_success: bool = false
    for i in range(40):
        var ent: Node = _new_entity("SWORD")
        ent.wounds["chest"] = [
            {
                "injury_type": BleedingConstants.INJURY_TYPE_CUT,
                "severity": BleedingConstants.SEVERITY_SEVERE,
                "penetration_to_tissue_mm": 8.0,
                "current_bleeding_rate": 0.0,
                "base_bleeding_rate": 0.0,
                "is_arterial": false,
                "is_stabilized": false,
            }
        ]
        if not BleedingConstants.is_wound_contaminated(ent.wounds["chest"][0]):
            _fail(failures, "debride_live: setup — deep chest cut should be contaminated by default")
            _free_entity_fixture(ent)
            continue
        seed(800000 + i)
        var ok: bool = ent._apply_bandage("chest")
        var still_contam: bool = BleedingConstants.is_wound_contaminated(ent.wounds["chest"][0])
        if ok:
            any_success = true
            if still_contam:
                _fail(failures, "debride_live: a successful bandage should debride a contaminated wound (seed %d)" % i)
        elif not still_contam:
            _fail(failures, "debride_live: a failed bandage should not debride the wound (seed %d)" % i)
        _free_entity_fixture(ent)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not any_success:
        _fail(failures, "debride_live: no bandage succeeded across 40 seeds — test is vacuous")


## ATLS Class III->IV realism: a decompensated casualty (below the decompensation threshold) has a
## dilated, leaky vascular compartment and responds poorly to a crystalloid bolus — the same bolus
## restores a *smaller fraction* of the blood deficit than in a compensated patient (deep shock
## needs repeated boluses / blood products, not one push). Deterministic (no RNG): the
## decompensated patient's restore fraction is base * FLUID_RESUSCITATION_DECOMPENSATED_MULT,
## the compensated patient's is base.
static func _run_fluid_resuscitation_decompensated(failures: PackedStringArray) -> void:
    var base: float = BleedingConstants.FLUID_RESUSCITATION_DEFICIT_RESTORE_FRACTION
    if not (base > 0.0 and base < 1.0):
        _fail(failures, "fluid_resusc_decomp: base restore fraction should be in (0,1) (got %.2f)" % base)
    # Compensated patient: above the decompensation threshold (56) -> full base fraction of the deficit.
    var comp: Node = _new_entity("SWORD")
    comp.blood_volume = 80.0  # deficit = 20
    comp._apply_fluid_resuscitation(1.0)
    var comp_frac: float = (comp.blood_volume - 80.0) / 20.0
    # Decompensated patient: below the decompensation threshold (56) but above the death threshold (50).
    var decomp: Node = _new_entity("SWORD")
    decomp.blood_volume = 52.0  # deficit = 48
    decomp._apply_fluid_resuscitation(1.0)
    var decomp_frac: float = (decomp.blood_volume - 52.0) / 48.0
    if not (decomp_frac < comp_frac):
        _fail(
            failures,
            (
                "fluid_resusc_decomp: decompensated restore fraction (%.3f) must be < compensated (%.3f)"
                % [decomp_frac, comp_frac]
            )
        )
    if absf(comp_frac - base) > 0.001:
        _fail(
            failures,
            "fluid_resusc_decomp: compensated restore fraction (%.3f) should equal base (%.3f)" % [comp_frac, base]
        )
    var want_decomp: float = base * BleedingConstants.FLUID_RESUSCITATION_DECOMPENSATED_MULT
    if absf(decomp_frac - want_decomp) > 0.001:
        _fail(
            failures,
            (
                "fluid_resusc_decomp: decompensated restore fraction (%.3f) should equal base*mult (%.3f)"
                % [decomp_frac, want_decomp]
            )
        )
    _free_entity_fixture(comp)
    _free_entity_fixture(decomp)


## Surgical amputation as sepsis source control (plan §10.5): a stage-2 focus cannot be cleared
## by dressings; amputation severs the limb and replaces the wound with the stump. Deterministic
## (no success roll). Placing the wound directly at stage 2 avoids the RNG staging flip — the test
## is about amputation's effect on an established septic focus, not the flip itself.
static func _run_amputation_as_sepsis_source_control(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var w: Dictionary = _seed_wound(ent, "right_arm", BleedingConstants.SEVERITY_CRITICAL)
    w["infection_stage"] = 2
    w["is_infected"] = true
    w["infection_progress"] = 1.0
    w["sepsis_progress"] = 0.5
    ent.is_septic = true
    if BodyPartQuery.is_part_severed(ent, "right_arm"):
        _fail(failures, "amputation: precondition — right_arm should not be severed before amputation")
    if not ent.is_septic:
        _fail(failures, "amputation: precondition — entity should be septic (is_septic)")
    var ok: bool = EntityMedical.amputate_part(ent, "right_arm")
    if not ok:
        _fail(failures, "amputation: amputate_part should succeed on an unsevered septic limb")
    if not BodyPartQuery.is_part_severed(ent, "right_arm"):
        _fail(failures, "amputation: right_arm should be severed after amputation (cut/bone pools zeroed)")
    var stump: Dictionary = ent.wounds.get("right_arm", [{}])[0]
    if int(stump.get("infection_stage", 0)) == 2:
        _fail(
            failures,
            (
                "amputation: the stage-2 (septic) wound should be replaced by the stump (stage=%s)"
                % str(stump.get("infection_stage"))
            )
        )
    if not bool(stump.get("is_stump", false)):
        _fail(failures, "amputation: the part should hold an amputation stump wound after amputation")
    if not EntityWounds.has_stump_wound(ent, "right_arm"):
        _fail(failures, "amputation: has_stump_wound should be true after amputation")
    if not ent.is_septic:
        _fail(failures, "amputation: is_septic should persist after amputation (systemic infection clears over time)")
    if not EntityHealing._all_septic_foci_source_controlled(ent):
        _fail(failures, "amputation: sepsis should be source-controlled once the septic focus is removed")
    if EntityMedical.amputate_part(ent, "right_arm"):
        _fail(failures, "amputation: re-amputating an already-severed part should return false")
    _free_entity_fixture(ent)


## Surgical amputation releases the limb's PRIOR medical state. The pre-amp clamp/dressings described
## the OLD wound channel that ensure_stump_wound replaced wholesale; leaving them means (a) the next
## healing tick "expires" the stale clamp against the STUMP and latches had_ischemia onto a limb the
## surgeon deliberately removed (a phantom Volkmann grip on an amputated stump at its later resolution)
## and (b) the old dressing/packing reads as definitive hemostasis for a brand-new bleeding stump,
## starving it of care. The surgeon releases the clamp once the stump is dressed -- release matches.
static func _run_amputation_releases_prior_medical_state(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "right_arm"
    var w: Dictionary = _seed_wound(ent, part, BleedingConstants.SEVERITY_CRITICAL)
    w["infection_stage"] = 2
    w["is_infected"] = true
    ent.is_septic = true
    # Pre-amp clamp sitting far past its max-duration window (stale from long ago), plus old dressings.
    ent.tourniquet_applied[part] = {
        "applied_at": -(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 60.0), "effectiveness": 1.0
    }
    ent.bandaged_parts[part] = true
    ent.packed_parts[part] = true
    if not EntityMedical.amputate_part(ent, part):
        _fail(failures, "amp_release: amputate_part should succeed on an unsevered septic limb")
        _free_entity_fixture(ent)
        return
    # (1) The operation releases the clamp + dressings for the severed limb.
    if ent.tourniquet_applied.has(part):
        _fail(failures, "amp_release: surgical amputation must release the pre-amp tourniquet (stale clamp on no limb)")
    if ent.bandaged_parts.get(part, false):
        _fail(
            failures,
            "amp_release: surgical amputation must release the pre-amp bandage (old dressing on a fresh stump)"
        )
    if ent.packed_parts.has(part):
        _fail(
            failures, "amp_release: surgical amputation must release the pre-amp packing (old packing on a fresh stump)"
        )
    var stump: Dictionary = ent.wounds.get(part, [{}])[0]
    if not bool(stump.get("is_stump", false)):
        _fail(failures, "amp_release: the part should hold an amputation stump after surgery")
    # (2) One tick with no clamp must NOT latch ischemia onto the freshly minted stump -- the released
    # clamp cannot "expire" against a limb that no longer exists.
    ent._process_healing(10.0)
    stump = ent.wounds.get(part, [{}])[0]
    if bool(stump.get("had_ischemia", false)):
        _fail(
            failures,
            "amp_release: a released clamp must NOT latch ischemia onto the fresh stump (phantom ischemic limb)"
        )
    _free_entity_fixture(ent)
