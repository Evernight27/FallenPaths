class_name MedicalHealingTests

extends CombatRegressionHarnessCore

## Tier 6.3 healing pipeline: death within advance stops healing, wound infection
## progression slowdown + cure, bleeding slows tissue healing, arterial untreated stalls
## healing, stabilize requires intrinsic active bleed, bandage blocked when tourniquet indicated.


static func _run_death_within_advance_stops_healing_pipeline(failures: PackedStringArray) -> void:
    var septic: Node = _new_entity("SWORD")
    var max_t: float = float(septic.body_max.get("left_arm", 0.0))
    septic.body_cutting["left_arm"] = max_t * 0.5
    septic.blood_volume = 55.0
    septic.direct_pressure_part = "right_leg"
    septic.wounds["left_arm"] = [
        {
            "created_at_game_time": 1000.0,
            "healing_duration_seconds": 1000000.0,
            "severity": BleedingConstants.SEVERITY_CRITICAL,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "infection_stage": 2,
            "infection_progress": 1.0,
            "is_infected": true,
        },
    ]
    septic.is_septic = true
    var cut_before: float = septic.body_cutting.get("left_arm", 0.0)
    seed(447712)
    EntityHealing._process_healing(septic, HealingConstants.SECONDS_PER_DAY * 1000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not septic.is_dead():
        _fail(failures, "death_advance: a 1000-day sepsis advance must kill a septic member")
    if septic.blood_volume > BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD:
        _fail(
            failures,
            (
                "death_advance: corpse blood must stay at the death clamp after the kill advance (got %.1f)"
                % septic.blood_volume
            )
        )
    if septic.body_cutting.get("left_arm", 0.0) > cut_before + 0.001:
        _fail(failures, "death_advance: corpse tissue must not regrow after a mid-advance death")
    if not septic.direct_pressure_part.is_empty():
        _fail(failures, "death_advance: mid-advance death must sever the pressure coupling")
    # A LIVING member on the same giant advance recovers normally (blood back up, tissue regrown) —
    # proving the re-check is strictly death-gated and does not freeze the convalescence pipeline.
    var alive: Node = _new_entity("SWORD")
    var alive_max: float = float(alive.body_max.get("left_arm", 0.0))
    alive.body_cutting["left_arm"] = alive_max * 0.5
    alive.blood_volume = 60.0
    EntityHealing._process_healing(alive, HealingConstants.SECONDS_PER_DAY * 1000.0)
    if alive.blood_volume <= 90.0:
        _fail(
            failures,
            "death_advance: living member must recover blood on the giant advance (got %.1f)" % alive.blood_volume
        )
    if alive.body_cutting.get("left_arm", 0.0) <= alive_max * 0.5:
        _fail(failures, "death_advance: living member must regrow tissue on the giant advance")
    MedicalPhaseGateTests._free_entity_fixture(septic)
    MedicalPhaseGateTests._free_entity_fixture(alive)


## Wound infection: untreated wounds become infected over days (impairing healing); a clean definitive
## dressing clears the infection. Progression is a deterministic per-day risk dose, campaign-only
## (never advances during a battle). Minimal wound dicts lack created_at/healing_duration so they persist.


static func _run_wound_infection_progression_slowdown_and_cure(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var wound: Dictionary = {
        "severity": BleedingConstants.SEVERITY_SEVERE,
        "current_bleeding_rate": 0.5,
        "base_bleeding_rate": 0.5,
        "is_arterial": false,
        "is_stabilized": false,
    }
    # --- Progression: a severe untreated wound (daily risk 0.30) infects over ~4 days. ---
    var ent: Node = _new_entity("SWORD")
    ent.wounds[part] = [wound.duplicate(true)]
    ent._process_healing(4 * HealingConstants.SECONDS_PER_DAY)
    var infected: bool = false
    for injury in ent.wounds.get(part, []):
        if injury.get("is_infected", false):
            infected = true
    if not infected:
        _fail(failures, "wound_infection: severe untreated wound should be infected after 4 days")
    MedicalPhaseGateTests._free_entity_fixture(ent)

    # --- Healing slowdown: an infected wound heals less tissue than a clean one over the same day. ---
    var clean: Node = _new_entity("SWORD")
    var sick: Node = _new_entity("SWORD")
    for e in [clean, sick]:
        var max_t: float = float(e.body_max.get(part, 0.0))
        e.body_cutting[part] = max_t * 0.5
        e.body_blunt[part] = max_t * 0.5
        e.wounds[part] = [wound.duplicate(true)]
    for injury in sick.wounds[part]:
        injury["is_infected"] = true
        injury["infection_progress"] = 1.0
    clean._process_healing(HealingConstants.SECONDS_PER_DAY)
    sick._process_healing(HealingConstants.SECONDS_PER_DAY)
    var clean_cut: float = clean.body_cutting.get(part, 0.0)
    var sick_cut: float = sick.body_cutting.get(part, 0.0)
    if sick_cut >= clean_cut:
        _fail(
            failures, "wound_infection: infected wound should heal less (sick=%.1f clean=%.1f)" % [sick_cut, clean_cut]
        )
    MedicalPhaseGateTests._free_entity_fixture(clean)
    MedicalPhaseGateTests._free_entity_fixture(sick)

    # --- Cure: a successful definitive dressing resets the stage-1 infection dose (CAMP-INF-1);
    #     a failed one does not. The clear roll is probabilistic, so after a successful bandage
    #     the dose is always < 1.0 (0.0 if the clear landed, 0.5 if it missed); a failed bandage
    #     never touches the dose. This is deterministic regardless of the seeded clear outcome. ---
    var cured: Node = _new_entity("SWORD")
    var infected_wound: Dictionary = wound.duplicate(true)
    infected_wound["is_infected"] = true
    infected_wound["infection_progress"] = 1.0
    cured.wounds[part] = [infected_wound]
    seed(884403)
    var bandage_ok: bool = cured._apply_bandage(part, 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var cured_wound: Dictionary = cured.wounds.get(part, [{}])[0]
    var prog_after: float = float(cured_wound.get("infection_progress", 1.0))
    if bandage_ok and prog_after >= 1.0:
        _fail(failures, "wound_infection: successful dressing should have reset infection dose (got %.2f)" % prog_after)
    if not bandage_ok and prog_after < 1.0:
        _fail(failures, "wound_infection: failed dressing should not touch infection dose (got %.2f)" % prog_after)
    MedicalPhaseGateTests._free_entity_fixture(cured)


## Active bleeding diverts repair resources: a part with an active (non-arterial) bleed heals tissue more
## slowly than the same part with a stopped bleed. Campaign-only (never advances during a battle).


static func _run_bleeding_slows_tissue_healing(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var clean: Node = _new_entity("SWORD")
    var bleeding: Node = _new_entity("SWORD")
    for e in [clean, bleeding]:
        var max_t: float = float(e.body_max.get(part, 0.0))
        e.body_cutting[part] = max_t * 0.5
        e.body_blunt[part] = max_t * 0.5
    clean.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "current_bleeding_rate": 0.0,
            "is_arterial": false,
            "is_stabilized": true
        },
    ]
    bleeding.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "current_bleeding_rate": 1.0,
            "is_arterial": false,
            "is_stabilized": false
        },
    ]
    clean._process_healing(HealingConstants.SECONDS_PER_DAY)
    bleeding._process_healing(HealingConstants.SECONDS_PER_DAY)
    var clean_cut: float = clean.body_cutting.get(part, 0.0)
    var bleed_cut: float = bleeding.body_cutting.get(part, 0.0)
    if bleed_cut >= clean_cut:
        _fail(
            failures,
            "bleed_heal: actively-bleeding part should heal less (bleed=%.1f clean=%.1f)" % [bleed_cut, clean_cut]
        )
    MedicalPhaseGateTests._free_entity_fixture(clean)
    MedicalPhaseGateTests._free_entity_fixture(bleeding)


## Untreated arterial stall: an open arterial wound cannot close while systolic pressure drives flow, so its
## part's repair stalls (no tissue gain); the same wound with definitive hemostasis (bandage) heals.


static func _run_arterial_untreated_stalls_healing(failures: PackedStringArray) -> void:
    var part: String = "right_arm"
    var open: Node = _new_entity("SWORD")
    var treated: Node = _new_entity("SWORD")
    for e in [open, treated]:
        var max_t: float = float(e.body_max.get(part, 0.0))
        e.body_cutting[part] = max_t * 0.5
        e.body_blunt[part] = max_t * 0.5
        e.wounds[part] = [
            {
                "severity": BleedingConstants.SEVERITY_SEVERE,
                "current_bleeding_rate": 1.0,
                "is_arterial": true,
                "is_stabilized": false
            },
        ]
    treated.bandaged_parts[part] = true
    var open_before: float = open.body_cutting.get(part, 0.0)
    open._process_healing(HealingConstants.SECONDS_PER_DAY)
    treated._process_healing(HealingConstants.SECONDS_PER_DAY)
    var open_after: float = open.body_cutting.get(part, 0.0)
    var treated_after: float = treated.body_cutting.get(part, 0.0)
    if open_after > open_before + 0.01:
        _fail(
            failures,
            (
                "arterial_stall: untreated arterial wound should stall healing (before=%.1f after=%.1f)"
                % [open_before, open_after]
            )
        )
    if treated_after <= open_after:
        _fail(
            failures,
            "arterial_stall: bandaged arterial wound should heal (treated=%.1f open=%.1f)" % [treated_after, open_after]
        )
    MedicalPhaseGateTests._free_entity_fixture(open)
    MedicalPhaseGateTests._free_entity_fixture(treated)


## Stabilize requires intrinsic active bleed  -  not arterial label alone after local clot under compression.

## Stabilize requires intrinsic active bleed  -  not arterial label alone after local clot under compression.


static func _run_stabilize_requires_intrinsic_active_bleed(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    # Start with low bleed so pressure reduces it below epsilon (simulating clot under sustained compression).
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.002,
            "base_bleeding_rate": 0.8,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": true,
            "is_stabilized": false,
        },
    ]
    if not ent.apply_direct_pressure("chest"):
        _fail(failures, "stabilize_intrinsic: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # Pressure immediate reduction (25% * 0.7 arterial mult ~= 17.5%) drops 0.002 -> ~0.0016;
    # then simulate clotting under sustained compression to push below epsilon.
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(60.0)  # 60s of clotting while pressure held
    if ent._can_apply_stabilize("chest"):
        _fail(
            failures,
            "stabilize_intrinsic: no hemostatic hold when intrinsic bleed already controlled under compression"
        )
    ent.wounds["chest"][0]["current_bleeding_rate"] = 0.15
    if not ent._can_apply_stabilize("chest"):
        _fail(failures, "stabilize_intrinsic: stabilize should allow while intrinsic bleed remains active")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## TQ-indicated limb: production gate blocks bandage/stabilize (combat `get_ally_medical_actions` parity).

## TQ-indicated limb: production gate blocks bandage/stabilize (combat `get_ally_medical_actions` parity).


static func _run_entity_medical_bandage_blocked_when_tourniquet_indicated(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.take_damage_split(12.0, 4.0, "right_leg")
    if not EntityMedical._is_tourniquet_indicated_for_part(ent, "right_leg"):
        _fail(failures, "tq_bandage_gate: fixture should be tourniquet-indicated on right_leg")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if not ent.apply_direct_pressure("right_leg"):
        _fail(failures, "tq_bandage_gate: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if ent._can_apply_bandage("right_leg"):
        _fail(failures, "tq_bandage_gate: bandage should not be legal on TQ-indicated limb")
    if ent._can_apply_stabilize("right_leg"):
        _fail(failures, "tq_bandage_gate: stabilize should not be legal on TQ-indicated limb")
    MedicalPhaseGateTests._free_entity_fixture(ent)

## Camp-2.1 MARCH: field care offers tourniquet before bandage when limb bleed is TQ-indicated.
