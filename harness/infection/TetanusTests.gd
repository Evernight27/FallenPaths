class_name TetanusTests
extends CombatRegressionHarnessCore
## Phase A+ (plan §10.2): tetanus — a delayed, spore-borne hazard distinct from local wound
## infection. A contaminated deep cut/stab seeds a single entity-level spore load; the wound can
## fully heal before the member manifests (3-21 day incubation, then a 7-day symptomatic window with
## a per-day death roll). Campaign-only (day-advance), never mid-battle.


static func _free_entity_fixture(n: Node) -> void:
    _free_harness_node(n)


## Seed a cut wound. pen >= CONTAMINATION_PENETRATION_MM (5.0) makes it is_wound_contaminated.
static func _seed_cut(
    ent: Node, part: String, pen: float, severity: String = BleedingConstants.SEVERITY_SEVERE
) -> Dictionary:
    var wound: Dictionary = {
        "injury_type": BleedingConstants.INJURY_TYPE_CUT,
        "severity": severity,
        "sub_region": "",
        "cumulative_damage": 2.0,
        "current_bleeding_rate": 0.0,
        "base_bleeding_rate": 0.0,
        "is_arterial": false,
        "is_stabilized": true,
        "penetration_to_tissue_mm": pen,
        "created_at_game_time": 0.0,
        "healing_duration_seconds": 4.0 * HealingConstants.SECONDS_PER_DAY,
    }
    ent.wounds[part] = [wound]
    return wound


## A clean, shallow cut/stab (not contaminated) must NOT seed a spore load.
static func _run_tetanus_clean_wound_not_armed(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_cut(ent, "right_arm", -1.0)  # pen < 5.0 -> not contaminated
    ent._process_healing(HealingConstants.SECONDS_PER_DAY)
    if not (ent.tetanus_incubation_days < 0.0):
        _fail(
            failures,
            "tetanus_clean: clean shallow wound should not arm tetanus (incubation=%.2f)" % ent.tetanus_incubation_days
        )
    _free_entity_fixture(ent)


## A contaminated deep cut (pen >= 5.0) seeds a spore load (incubation drawn in [3,21] days).
static func _run_tetanus_contaminated_wound_arms(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_cut(ent, "right_arm", 8.0)  # deep -> is_wound_contaminated
    seed(31337)
    ent._process_healing(HealingConstants.SECONDS_PER_DAY)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not (
        ent.tetanus_incubation_days > 0.0
        and ent.tetanus_incubation_days <= BleedingConstants.TETANUS_INCUBATION_MAX_DAYS
    ):
        _fail(
            failures,
            (
                "tetanus_arm: contaminated wound should arm a spore load in [%.0f,%.0f] days (got %.2f)"
                % [
                    BleedingConstants.TETANUS_INCUBATION_MIN_DAYS,
                    BleedingConstants.TETANUS_INCUBATION_MAX_DAYS,
                    ent.tetanus_incubation_days
                ]
            )
        )
    _free_entity_fixture(ent)


## Incubation is entity-level: it survives the seeding wound resolving (the wound can heal first).
static func _run_tetanus_incubation_survives_wound_resolution(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    _seed_cut(ent, "right_arm", 8.0)
    seed(55511)
    ent._process_healing(HealingConstants.SECONDS_PER_DAY)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var armed: float = ent.tetanus_incubation_days
    if armed <= 0.0:
        _fail(failures, "tetanus_survive: setup failed, spore load did not arm (incubation=%.2f)" % armed)
        return
    # Remove the seeding wound (it resolved) and advance; the entity-level countdown must continue.
    ent.wounds.erase("right_arm")
    ent.tetanus_incubation_days = 5.0
    ent._process_healing(HealingConstants.SECONDS_PER_DAY)  # per_day = 1.0
    if not (ent.tetanus_incubation_days < 5.0 and ent.tetanus_incubation_days > 0.0):
        _fail(
            failures,
            (
                "tetanus_survive: incubation should count down without the wound (5.0 -> %.2f)"
                % ent.tetanus_incubation_days
            )
        )
    _free_entity_fixture(ent)


## Crossing the incubation threshold rolls onset (TETANUS_ONSET_RISK). Over many seeds, at least
## one run must latch the systemic is_tetanus state (1 - 0.7^40 ~= 1.0).
static func _run_tetanus_onset_sets_flag(failures: PackedStringArray) -> void:
    var ever_on: bool = false
    for i in range(40):
        var ent: Node = _new_entity("SWORD")
        _seed_cut(ent, "right_arm", 8.0)
        ent.tetanus_incubation_days = 0.01  # force the onset roll on the next day-advance
        seed(900000 + i)
        ent._process_healing(HealingConstants.SECONDS_PER_DAY)  # per_day = 1.0
        if ent.is_tetanus:
            ever_on = true
            _free_entity_fixture(ent)
            break
        _free_entity_fixture(ent)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not ever_on:
        _fail(
            failures,
            (
                (
                    "tetanus_onset: across 40 seeds, onset (TETANUS_ONSET_RISK=%.2f) should have latched is_tetanus at "
                    + "least once"
                )
                % BleedingConstants.TETANUS_ONSET_RISK
            )
        )


## The tetanus death flag folds into is_dead() and reports the "tetanus" reason.
static func _run_tetanus_is_dead_fold(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    if ent.is_dead():
        _fail(failures, "tetanus_is_dead: healthy entity should not be dead")
    ent._tetanus_dead = true
    if not ent.is_dead():
        _fail(failures, "tetanus_is_dead: _tetanus_dead should make is_dead() true")
    var reason: String = ent._get_death_reason()
    if not reason.begins_with("tetanus"):
        _fail(failures, "tetanus_is_dead: _get_death_reason should report tetanus (got %s)" % reason)
    _free_entity_fixture(ent)


## A tetanus-affected member's performance modifier (perception) drops below the healthy value.
static func _run_tetanus_performance_tell(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var healthy: float = EntityPainConsciousness.get_performance_modifier(ent)
    ent.is_tetanus = true
    var tetanus: float = EntityPainConsciousness.get_performance_modifier(ent)
    if not (tetanus < healthy):
        _fail(
            failures,
            "tetanus_perf: tetanus performance modifier (%.3f) should be below healthy (%.3f)" % [tetanus, healthy]
        )
    _free_entity_fixture(ent)


## Plan §10.2 counter-play latch: a contaminated wound that is cleanly dressed / debrided
## (definitive hemostasis) at the moment the spore load is seeded records tetanus_cleaned_at_arm = true;
## an undressed contaminated wound records false. Both must still arm the spore load.
static func _run_tetanus_cleaned_at_arm_latch(failures: PackedStringArray) -> void:
    var untreated: Node = _new_entity("SWORD")
    _seed_cut(untreated, "right_arm", 8.0)
    untreated._process_healing(HealingConstants.SECONDS_PER_DAY)
    var dressed: Node = _new_entity("SWORD")
    _seed_cut(dressed, "right_arm", 8.0)
    dressed.bandaged_parts["right_arm"] = true
    dressed._process_healing(HealingConstants.SECONDS_PER_DAY)
    if untreated.tetanus_incubation_days <= 0.0:
        _fail(
            failures,
            (
                "tetanus_latch: untreated contaminated wound should arm a spore load (incubation=%.2f)"
                % untreated.tetanus_incubation_days
            )
        )
    if bool(untreated.tetanus_cleaned_at_arm):
        _fail(failures, "tetanus_latch: an undressed contaminated wound must not latch tetanus_cleaned_at_arm")
    if dressed.tetanus_incubation_days <= 0.0:
        _fail(
            failures,
            (
                "tetanus_latch: dressed contaminated wound should arm a spore load (incubation=%.2f)"
                % dressed.tetanus_incubation_days
            )
        )
    if not bool(dressed.tetanus_cleaned_at_arm):
        _fail(failures, "tetanus_latch: a cleanly-dressed contaminated wound should latch tetanus_cleaned_at_arm")
    _free_entity_fixture(untreated)
    _free_entity_fixture(dressed)


## Plan §10.2 counter-play effect: a wound cleansed at arm time (tetanus_cleaned_at_arm) germinates
## less often — the onset roll uses TETANUS_ONSET_RISK * TETANUS_ONSET_RISK_TREATED_MULT (0.15 < 0.30).
## Across the SAME seed sequence the cleaned group's onset is a strict subset of the untreated
## group's (identical prior draws, only the threshold differs), so cleaned_count < raw_count.
static func _run_tetanus_cleaned_at_arm_reduces_onset(failures: PackedStringArray) -> void:
    const N: int = 200
    var raw_count: int = 0
    var cleaned_count: int = 0
    for i in range(N):
        var raw: Node = _new_entity("SWORD")
        _seed_cut(raw, "right_arm", 8.0)
        raw.tetanus_incubation_days = 0.01
        raw.tetanus_cleaned_at_arm = false
        seed(700000 + i)
        raw._process_healing(HealingConstants.SECONDS_PER_DAY)
        if raw.is_tetanus:
            raw_count += 1
        _free_entity_fixture(raw)
        var cl: Node = _new_entity("SWORD")
        _seed_cut(cl, "right_arm", 8.0)
        cl.tetanus_incubation_days = 0.01
        cl.tetanus_cleaned_at_arm = true
        seed(700000 + i)
        cl._process_healing(HealingConstants.SECONDS_PER_DAY)
        if cl.is_tetanus:
            cleaned_count += 1
        _free_entity_fixture(cl)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not (cleaned_count < raw_count):
        _fail(
            failures,
            (
                "tetanus_cleaned_onset: cleaned-at-arm onset (%d) must be strictly below untreated (%d) across %d seeds"
                % [cleaned_count, raw_count, N]
            )
        )
