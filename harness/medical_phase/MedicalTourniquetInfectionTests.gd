class_name MedicalTourniquetInfectionTests

extends CombatRegressionHarnessCore

## Tier 6.3 stabilize-trim, tourniquet apply/ischemia/release/expiry latches, infection
## latches + sepsis death, corpse healing/bleeding/release invariants and resolved-wound
## held-pressure + corpse bookkeeping release.


static func _run_field_stabilize_trim_before_procedure_advance(failures: PackedStringArray) -> void:
    var wound_row: Dictionary = {
        "current_bleeding_rate": 0.35,
        "base_bleeding_rate": 0.8,
        "severity": BleedingConstants.SEVERITY_MODERATE,
        "is_arterial": false,
        "is_stabilized": false,
    }
    var advance_only: Node = _new_entity("SWORD")
    advance_only.wounds["chest"] = [wound_row.duplicate(true)]
    if not advance_only.apply_direct_pressure("chest"):
        _fail(failures, "field_stab_order: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        return
    if advance_only.has_method("process_bleeding"):
        advance_only.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if advance_only.has_method("process_blood_loss"):
        advance_only.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate_advance_only: float = float(advance_only.wounds["chest"][0].get("current_bleeding_rate", 0.0))
    var trim_then_advance: Node = _new_entity("SWORD")
    trim_then_advance.wounds["chest"] = [wound_row.duplicate(true)]
    if not trim_then_advance.apply_direct_pressure("chest"):
        _fail(failures, "field_stab_order: pressure setup failed (trim path)")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        MedicalPhaseGateTests._free_entity_fixture(trim_then_advance)
        return
    if not trim_then_advance._apply_stabilize("chest", 1.5):
        _fail(failures, "field_stab_order: stabilize should succeed under pressure")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        MedicalPhaseGateTests._free_entity_fixture(trim_then_advance)
        return
    if trim_then_advance.has_method("process_bleeding"):
        trim_then_advance.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if trim_then_advance.has_method("process_blood_loss"):
        trim_then_advance.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate_trim_path: float = float(trim_then_advance.wounds["chest"][0].get("current_bleeding_rate", 0.0))
    if rate_trim_path >= rate_advance_only - 0.0001:
        _fail(
            failures,
            (
                "field_stab_order: stabilize trim before advance should lower intrinsic rate got trim=%.5f advance=%.5f"
                % [rate_trim_path, rate_advance_only]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(advance_only)
    MedicalPhaseGateTests._free_entity_fixture(trim_then_advance)


## Field tourniquet: occlude limb hemorrhage before procedure sim advance (not 2 min open bleed first).

## Field tourniquet: occlude limb hemorrhage before procedure sim advance (not 2 min open bleed first).


static func _run_field_tourniquet_applies_before_procedure_advance(failures: PackedStringArray) -> void:
    var wound_row: Dictionary = {
        "current_bleeding_rate": 1.4,
        "base_bleeding_rate": 2.0,
        "severity": BleedingConstants.SEVERITY_SEVERE,
        "is_arterial": true,
        "is_stabilized": false,
    }
    var tq_first: Node = _new_entity("SWORD")
    tq_first.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    tq_first.wounds["left_leg"] = [wound_row.duplicate(true)]
    var bleed_first: Node = _new_entity("SWORD")
    bleed_first.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    bleed_first.wounds["left_leg"] = [wound_row.duplicate(true)]
    seed(884401)
    var tq_ok: bool = tq_first._apply_tourniquet("left_leg", 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not tq_ok:
        _fail(failures, "field_tq_order: tourniquet setup should succeed")
        MedicalPhaseGateTests._free_entity_fixture(tq_first)
        MedicalPhaseGateTests._free_entity_fixture(bleed_first)
        return
    if tq_first.has_method("process_bleeding"):
        tq_first.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if tq_first.has_method("process_blood_loss"):
        tq_first.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if bleed_first.has_method("process_bleeding"):
        bleed_first.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if bleed_first.has_method("process_blood_loss"):
        bleed_first.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    seed(884401)
    bleed_first._apply_tourniquet("left_leg", 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if float(tq_first.blood_volume) <= float(bleed_first.blood_volume):
        _fail(
            failures,
            (
                "field_tq_order: TQ-before-advance should preserve more blood (tq_first=%.1f bleed_first=%.1f)"
                % [float(tq_first.blood_volume), float(bleed_first.blood_volume)]
            )
        )
    if not bleed_first.tourniquet_applied.has("left_leg"):
        _fail(failures, "field_tq_order: bleed-first path should still end with TQ applied")
    MedicalPhaseGateTests._free_entity_fixture(tq_first)
    MedicalPhaseGateTests._free_entity_fixture(bleed_first)


## Tourniquet ischemia: a TQ left on past the max duration is auto-released and causes ischemic soft-tissue
## damage to the limb (necrosis / compartment injury). Models the real-world cost of a TQ left on too long.


static func _run_tourniquet_ischemia_on_expiry(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "left_leg"
    var max_tissue: float = float(ent.body_max.get(part, 0.0))
    if max_tissue <= 0.0:
        _fail(failures, "tq_ischemia: fixture limb should have tissue max")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # A tourniquet can only be applied to a bleeding limb — seed a wound so _can_apply_tourniquet passes.
    # wounds[part] is an ARRAY of injury dicts (EntityHealing._process_healing casts it to Array).
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
        }
    ]
    seed(884402)
    ent._apply_tourniquet(part, 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not ent.tourniquet_applied.has(part):
        _fail(failures, "tq_ischemia: tourniquet should be applied")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var cut_before: float = ent.body_cutting.get(part, 0.0)
    var blunt_before: float = ent.body_blunt.get(part, 0.0)
    # Advance game time past the max TQ duration so the tourniquet expires (ischemia + auto-release).
    ent._process_healing(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 1.0)
    if ent.tourniquet_applied.has(part):
        _fail(failures, "tq_ischemia: expired tourniquet should be auto-released")
    var cut_drop: float = cut_before - ent.body_cutting.get(part, 0.0)
    var blunt_drop: float = blunt_before - ent.body_blunt.get(part, 0.0)
    var want_damage: float = max_tissue * BleedingConstants.TOURNIQUET_ISCHEMIA_TISSUE_FRACTION
    # Healing runs in the same advance, so the net drop is slightly less than the raw ischemic damage.
    if cut_drop < 0.5 * want_damage:
        _fail(failures, "tq_ischemia: cutting drop %.1f should be >= 50%% of expected %.1f" % [cut_drop, want_damage])
    if blunt_drop < 0.5 * want_damage:
        _fail(failures, "tq_ischemia: blunt drop %.1f should be >= 50%% of expected %.1f" % [blunt_drop, want_damage])
    MedicalPhaseGateTests._free_entity_fixture(ent)


## A tourniquet is released when the limb's LAST wound RESOLVES (not only at max-duration expiry). A
## short-lived wound heals well inside the 3600s clamp window; leaving the TQ clamped afterward would
## (a) skip the ischemia latch entirely (the max-duration loop latches had_ischemia onto a wound that
## no longer exists) and (b) carry a stale `applied_at` into the next battle, where a new re-wound on
## the same part instantly counts as an over-time clamp -- an hour-long tourniquet turns into an
## immediate ischemic strike. Healed limb -> release the clamp, exactly like dressings at resolution.


static func _run_resolved_wound_releases_tourniquet(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "left_leg"
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 360.0,
        }
    ]
    ent._apply_tourniquet(part, 1.5)
    if not ent.tourniquet_applied.has(part):
        _fail(failures, "tq_release: tourniquet should be applied")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # A 360s wound resolves at ~1078s (tau=120, progress 1-exp(-age/120)); a single 2000s advance sits
    # well past resolution and well before the 3600s max-duration expiry -- only the resolution cleanup
    # can release this clamp.
    ent._process_healing(2000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if ent.tourniquet_applied.has(part):
        _fail(
            failures,
            (
                "tq_release: a tourniquet must be released when its limb's last wound "
                + "resolves (stale clamp on a healed limb)"
            )
        )
    if ent.wounds.has(part):
        _fail(failures, "tq_release: the wound should have resolved in the advance")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Every clamp release ends the clamp SESSION, and the failure counter dies with it. A clamp session
## is one application attempt chain on a limb: the +15% retry bonus per prior failure models the medic
## adjusting placement WITHIN that session. It must not ride into a future application -- a new wound
## days later, or a freshly severed stump -- where old placement fumbles have no meaning. The three
## release paths (expiry, wound-resolution cleanup, and the stump mint that severs the limb) all share
## the release via EntityMedical._remove_tourniquet, which clears tourniquet_failures.


static func _run_tourniquet_release_clears_failure_session(failures: PackedStringArray) -> void:
    # (1) Expiry release: an over-limit clamp expires; the session's 2 fumbles must not persist.
    var ent: Node = _new_entity("SWORD")
    var part: String = "left_leg"
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 21.0 * HealingConstants.SECONDS_PER_DAY,
        }
    ]
    ent.tourniquet_applied[part] = {"applied_at": 0.0, "effectiveness": 1.0}
    ent.tourniquet_failures[part] = 2
    ent._process_healing(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 100.0)
    if ent.tourniquet_applied.has(part):
        _fail(failures, "tq_session: expiry should remove the clamp")
    if int(ent.tourniquet_failures.get(part, 0)) != 0:
        _fail(failures, "tq_session: expiry must end the clamp session (stale failure count on a released clamp)")
    MedicalPhaseGateTests._free_entity_fixture(ent)

    # (2) Wound-resolution release: the healed limb's clamp is released with the dressing cleanup.
    var ent_r: Node = _new_entity("SWORD")
    ent_r.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 360.0,
        }
    ]
    ent_r.tourniquet_applied[part] = {"applied_at": 0.0, "effectiveness": 1.0}
    ent_r.tourniquet_failures[part] = 2
    ent_r._process_healing(2000.0)
    if int(ent_r.tourniquet_failures.get(part, 0)) != 0:
        _fail(failures, "tq_session: wound-resolution release must end the clamp session (stale failure count)")
    MedicalPhaseGateTests._free_entity_fixture(ent_r)

    # (3) Stump mint release: severing the limb ends the pre-amputation clamp session -- a fresh stump
    # clamp must not inherit the old limb's placement fumbles.
    var ent_m: Node = _new_entity("SWORD")
    ent_m.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 360.0,
        }
    ]
    ent_m.tourniquet_failures[part] = 2
    ent_m.body_cutting[part] = 0.0
    ent_m.body_blunt[part] = 0.0
    ent_m.bone_health[part] = 0.0
    EntityWounds.ensure_stump_wound(ent_m, part)
    if int(ent_m.tourniquet_failures.get(part, 0)) != 0:
        _fail(
            failures,
            (
                "tq_session: the stump mint must end the pre-amputation clamp session "
                + "(stale failure count on the fresh limb)"
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(ent_m)


## When a TQ is removed by wound resolution (NOT by expiry), no ischemia damage occurs and the
## descriptor's had_ischemia must be false. This pins the false-positive where the old code
## checked tourniquet_applied.has(part) at descriptor-build time (before _remove_tourniquet ran).


static func _run_tourniquet_preexpiry_no_ischemia(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "left_leg"
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 360.0,
        }
    ]
    ent._apply_tourniquet(part, 1.5)
    if not ent.tourniquet_applied.has(part):
        _fail(failures, "tq_preexp: tourniquet should be applied")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # 2000s: wound resolves (progress=1-exp(-2000/120)~1.0) but TQ (max 3600s) has NOT expired.
    ent._process_healing(2000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    # TQ should have been removed by the resolution cleanup.
    if ent.tourniquet_applied.has(part):
        _fail(failures, "tq_preexp: TQ should be released when wound resolves before expiry")
    # The stashed descriptor must NOT carry had_ischemia (TQ never expired -> no necrosis).
    var found: bool = false
    for desc in ent.resolved_wounds_this_advance:
        if str(desc.get("part", "")) == part:
            found = true
            if bool(desc.get("had_ischemia", false)):
                _fail(
                    failures,
                    (
                        "tq_preexp: descriptor should NOT have had_ischemia when TQ was released at resolution (no "
                        + "expiry "
                        + "occurred)"
                    )
                )
    if not found:
        _fail(failures, "tq_preexp: expected a resolved-wound descriptor for %s" % part)
    ent.clear_resolved_wounds()
    MedicalPhaseGateTests._free_entity_fixture(ent)


## When a TQ expires (max duration elapsed), apply_tourniquet_ischemia_damage must latch
## had_ischemia=true on the wound so the scar-mint descriptor captures it even though the
## tourniquet is no longer in tourniquet_applied.


static func _run_tourniquet_ischemia_latches_on_wound(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    var part: String = "right_arm"
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "created_at_game_time": 0.0,
            # Long healing duration ensures the wound does NOT resolve in this advance,
            # so the TQ-expiry path (not the resolution path) removes the TQ.
            "healing_duration_seconds": 86400.0,
        }
    ]
    ent._apply_tourniquet(part, 1.5)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not ent.tourniquet_applied.has(part):
        _fail(failures, "tq_latch: tourniquet should be applied")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # Advance past TQ max duration (3600s) but well before wound resolves.
    ent._process_healing(BleedingConstants.TOURNIQUET_MAX_DURATION_SECONDS + 10.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    # TQ should have been auto-released by the expiry loop.
    if ent.tourniquet_applied.has(part):
        _fail(failures, "tq_latch: expired tourniquet should be auto-released")
    # The wound should still exist (86400s healing >> 3610s elapsed).
    if not ent.wounds.has(part) or ent.wounds[part].is_empty():
        _fail(failures, "tq_latch: wound should still be present after TQ expiry")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var w: Dictionary = ent.wounds[part][0]
    if not bool(w.get("had_ischemia", false)):
        _fail(failures, "tq_latch: wound should carry had_ischemia=true after TQ expiry (latch for scar mint)")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Infection history survives a cure: a wound that infects (ever_infected latched at the 0->1 flip)
## and is then dressed clean must still report was_infected=true in the resolved-wound descriptor.
## This pins the false-negative where the descriptor read only the live infection_stage/is_infected
## (both cleared by a successful dressing), losing the infection history and skipping the
## infected-soft-tissue scar mint. ever_infected is the authoritative history latch.


static func _run_was_infected_latches_survive_cure(failures: PackedStringArray) -> void:
    var part: String = "left_arm"
    var ent: Node = _new_entity("SWORD")
    ent.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": false,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            # Fresh at the moment the infection dose is evaluated: after the 4-day advance
            # _game_time_seconds == 4d, so created == 4d keeps age 0 (freshness 1.0) and the wound
            # still >= 0 so it can later resolve. A 0.0 created_at would age the wound 4d (freshness
            # ~0.6) and the dose would not reach infection in 4 days.
            "created_at_game_time": 4.0 * HealingConstants.SECONDS_PER_DAY,
            # 100 days: not resolved in the 4-day infection advance (progress ~0.11).
            "healing_duration_seconds": 8640000.0,
        }
    ]
    seed(44210)
    ent._process_healing(4.0 * HealingConstants.SECONDS_PER_DAY)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var w: Dictionary = ent.wounds[part][0]
    if not bool(w.get("ever_infected", false)):
        _fail(
            failures,
            (
                "was_inf: a wound that infected should have latched ever_infected (stage=%d)"
                % int(w.get("infection_stage", 0))
            )
        )
    # Simulate a successful dressing clear (EntityMedical._apply_bandage resets stage/is_infected).
    w["infection_stage"] = 0
    w["is_infected"] = false
    w["infection_progress"] = 0.0
    # Advance to resolution; the descriptor must carry the infection history via the latch.
    ent._process_healing(200.0 * HealingConstants.SECONDS_PER_DAY)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var found: bool = false
    for desc in ent.resolved_wounds_this_advance:
        if str(desc.get("part", "")) == part:
            found = true
            if not bool(desc.get("was_infected", false)):
                _fail(
                    failures,
                    "was_inf: descriptor must carry was_infected=true after a cure (latch survives the dressing)"
                )
    if not found:
        _fail(failures, "was_inf: expected a resolved-wound descriptor for %s" % part)
    ent.clear_resolved_wounds()
    MedicalPhaseGateTests._free_entity_fixture(ent)


## A sepsis death latched in this advance must stop the tetanus pass too: the corpse must not arm
## spore loads, flip is_tetanus, or take a second death roll mid-call. The mid-advance re-check
## below the infection block guards the tissue/bone/blood pipeline, but the sepsis->tetanus
## hand-off needs its own guard. A living member with the same giant advance keeps tetanus active.


static func _run_sepsis_death_skips_tetanus_pass(failures: PackedStringArray) -> void:
    var ent: Node = _new_entity("SWORD")
    ent.is_septic = true
    ent.is_tetanus = true
    seed(77231)
    EntityHealing._process_healing(ent, HealingConstants.SECONDS_PER_DAY * 1000.0)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if not ent.is_dead():
        _fail(failures, "sepsis_skip: a 1000-day advance must kill a septic member")
    if ent._tetanus_dead:
        _fail(failures, "sepsis_skip: tetanus death roll must NOT run on a sepsis-killed corpse")
    if not ent.is_tetanus:
        _fail(failures, "sepsis_skip: is_tetanus must persist (the tetanus pass was skipped, not resolved)")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## A corpse does not convalesce: a member whose death is registered does not heal, resolve wounds, or
## stash resolution descriptors on a later day-advance — dead tissue heals nothing. The living control
## with identical wounds resolves and stashes, proving the difference is the death gate, not the clock.


static func _run_corpse_does_not_heal_or_resolve(failures: PackedStringArray) -> void:
    var dead: Node = _new_entity("SWORD")
    dead._game_time_seconds = 100000.0
    dead.wounds["left_arm"] = [
        {
            "created_at_game_time": 96000.0,
            "healing_duration_seconds": 3600.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    dead._sepsis_dead = true
    EntityHealing._process_healing(dead, HealingConstants.SECONDS_PER_DAY)
    if dead.resolved_wounds_this_advance.size() != 0:
        _fail(
            failures,
            (
                "corpse_heal: a dead member must not stash resolution descriptors (got %d)"
                % dead.resolved_wounds_this_advance.size()
            )
        )
    if not dead.wounds.has("left_arm"):
        _fail(failures, "corpse_heal: a near-resolved wound on a corpse must not resolve away")
    var alive: Node = _new_entity("SWORD")
    alive._game_time_seconds = 100000.0
    alive.wounds["left_arm"] = [
        {
            "created_at_game_time": 96000.0,
            "healing_duration_seconds": 3600.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    EntityHealing._process_healing(alive, HealingConstants.SECONDS_PER_DAY)
    if alive.resolved_wounds_this_advance.size() != 1:
        _fail(
            failures,
            (
                "corpse_heal: the living control should resolve and stash exactly one wound (got %d)"
                % alive.resolved_wounds_this_advance.size()
            )
        )
    if alive.wounds.has("left_arm"):
        _fail(failures, "corpse_heal: the living control's near-resolved wound should have resolved away")
    MedicalPhaseGateTests._free_entity_fixture(dead)
    MedicalPhaseGateTests._free_entity_fixture(alive)


## The third corpse sibling: a death-registered member does not run the bleeding sim either — its
## wound rates must not clot-decay (the post-mortem wound snapshot freezes) and held direct pressure
## must not auto-clear (who was still trying to save them survives as forensic state). The living
## control's rate decays under clotting, proving the difference is the death gate, not the seed.


static func _run_corpse_does_not_bleed_or_release(failures: PackedStringArray) -> void:
    var part: String = "left_arm"
    var dead: Node = _new_entity("SWORD")
    dead.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": true,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 3600.0,
        }
    ]
    dead.direct_pressure_part = part
    dead._sepsis_dead = true
    EntityWounds.process_bleeding(dead, HealingConstants.SECONDS_PER_DAY)
    var dead_rate: float = float(dead.wounds[part][0].current_bleeding_rate)
    if absf(dead_rate - 0.5) > 1e-9:
        _fail(failures, "corpse_bleed: a corpse's open-bleed rate must not clot-decay (got %.3f)" % dead_rate)
    if dead.direct_pressure_part.is_empty():
        _fail(failures, "corpse_bleed: a corpse's held direct pressure must not auto-clear")
    var alive: Node = _new_entity("SWORD")
    alive.wounds[part] = [
        {
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "current_bleeding_rate": 0.5,
            "base_bleeding_rate": 0.5,
            "is_arterial": false,
            "is_stabilized": true,
            "created_at_game_time": 0.0,
            "healing_duration_seconds": 3600.0,
        }
    ]
    alive.direct_pressure_part = part
    EntityWounds.process_bleeding(alive, HealingConstants.SECONDS_PER_DAY)
    var alive_rate: float = float(alive.wounds[part][0].current_bleeding_rate)
    if alive_rate >= 0.25:
        _fail(
            failures,
            "corpse_bleed: the living control's bleed rate should decay under clotting (got %.3f)" % alive_rate
        )
    MedicalPhaseGateTests._free_entity_fixture(dead)
    MedicalPhaseGateTests._free_entity_fixture(alive)


## Rest-day recovery honors decompensation: a non-bleeding member below DECOMPENSATION_BLOOD_THRESHOLD
## self-replenishes only trace volume (DECOMPENSATED_RECOVERY_SUPPRESSION), mirroring the suppression
## the battle-recovery term and the resuscitation bolus already carry — one rest day must not erase a
## near-fatal hemorrhage back to full with no intervention. A compensated member recovers normally,
## proving the suppression is the boundary, not the clock.


static func _run_decompensated_rest_recovery_suppressed(failures: PackedStringArray) -> void:
    var deep: Node = _new_entity("SWORD")
    deep.blood_volume = 52.0
    EntityHealing._process_healing(deep, HealingConstants.SECONDS_PER_DAY)
    if float(deep.blood_volume) >= 60.0:
        _fail(
            failures,
            (
                "decomp_rest: a decompensated member must not self-fill a day's deficit (got %.1f)"
                % float(deep.blood_volume)
            )
        )
    var edge: Node = _new_entity("SWORD")
    edge.blood_volume = 55.0
    EntityHealing._process_healing(edge, HealingConstants.SECONDS_PER_DAY)
    if float(edge.blood_volume) >= 65.0:
        _fail(
            failures, "decomp_rest: just-below-threshold must still be suppressed (got %.1f)" % float(edge.blood_volume)
        )
    var healthy: Node = _new_entity("SWORD")
    healthy.blood_volume = 75.0
    EntityHealing._process_healing(healthy, HealingConstants.SECONDS_PER_DAY)
    if float(healthy.blood_volume) < 90.0:
        _fail(
            failures,
            (
                "decomp_rest: a compensated member should recover most of the deficit (got %.1f)"
                % float(healthy.blood_volume)
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(deep)
    MedicalPhaseGateTests._free_entity_fixture(edge)
    MedicalPhaseGateTests._free_entity_fixture(healthy)


## A resolved wound drops held pressure with the dressings: the pressure latches (ally-held, the ally's
## on-ally record, self-held) die when the part's last wound resolves — nothing is left to press. A
## stale latch would silently mark the NEXT fresh wound on that part as pressure-held (flow-retention
## bleed factor + under-pressure clotting) with nobody holding anything.


static func _run_resolved_wound_releases_held_pressure(failures: PackedStringArray) -> void:
    var ally: Node = _new_entity("SWORD")
    var pressed: Node = _new_entity("SWORD")
    pressed._game_time_seconds = 100000.0
    pressed.wounds["left_arm"] = [
        {
            "created_at_game_time": 96000.0,
            "healing_duration_seconds": 3600.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    pressed.wounds["right_arm"] = [
        {
            "created_at_game_time": 96000.0,
            "healing_duration_seconds": 3600.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    pressed.direct_pressure_part = "left_arm"
    pressed.direct_pressure_held_by = ally
    ally.direct_pressure_on_ally = {"node": pressed, "part": "left_arm"}
    pressed.self_direct_pressure_part = "right_arm"
    EntityHealing._process_healing(pressed, HealingConstants.SECONDS_PER_DAY)
    if not pressed.direct_pressure_part.is_empty():
        _fail(
            failures,
            (
                "press_release: ally-held pressure must clear when the wound resolves (got %s)"
                % str(pressed.direct_pressure_part)
            )
        )
    if pressed.direct_pressure_held_by != null:
        _fail(failures, "press_release: the held-by link must clear when the wound resolves")
    if not ally.direct_pressure_on_ally.is_empty():
        _fail(failures, "press_release: the ally's on-ally record must clear when the wound resolves")
    if not pressed.self_direct_pressure_part.is_empty():
        _fail(
            failures,
            (
                "press_release: self-held pressure must clear when the wound resolves (got %s)"
                % str(pressed.self_direct_pressure_part)
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(ally)
    MedicalPhaseGateTests._free_entity_fixture(pressed)


## A corpse releases its pressure bookkeeping on the first day-advance: nothing else clears a dead
## casualty's latches (the hemostasis auto-release is gated off corpses, and clear_direct_pressure_scene
## only runs when a holder takes a NEW move, not at battle end). A death must sever both roles -- the
## corpse as casualty (its held/self latches + the medic's on-ally record) AND the corpse as holder
## (a living ally with a dead holder is nobody's casualty anymore). The pass-20 death gate in
## _process_healing is the guaranteed post-mortem choke before the camp burn/mint.


static func _run_corpse_release_clears_pressure_bookkeeping(failures: PackedStringArray) -> void:
    var medic: Node = _new_entity("SWORD")
    var corpse: Node = _new_entity("SWORD")
    corpse.wounds["left_arm"] = [
        {
            "created_at_game_time": 100000.0,
            "healing_duration_seconds": 3600.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    corpse.blood_volume = 40.0
    corpse.direct_pressure_part = "left_arm"
    corpse.direct_pressure_held_by = medic
    medic.direct_pressure_on_ally = {"node": corpse, "part": "left_arm"}
    corpse.self_direct_pressure_part = "right_arm"
    var live_pressed: Node = _new_entity("SWORD")
    live_pressed.wounds["left_leg"] = [
        {
            "created_at_game_time": 100000.0,
            "healing_duration_seconds": 120000.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    live_pressed.direct_pressure_part = "left_leg"
    live_pressed.direct_pressure_held_by = corpse
    corpse.direct_pressure_on_ally = {"node": live_pressed, "part": "left_leg"}
    EntityHealing._process_healing(corpse, HealingConstants.SECONDS_PER_DAY)
    if not corpse.direct_pressure_part.is_empty():
        _fail(
            failures,
            (
                "corpse_press: corpse's ally-held pressure must clear on the death gate (got %s)"
                % str(corpse.direct_pressure_part)
            )
        )
    if not corpse.self_direct_pressure_part.is_empty():
        _fail(
            failures,
            (
                "corpse_press: corpse's self-held pressure must clear on the death gate (got %s)"
                % str(corpse.self_direct_pressure_part)
            )
        )
    if corpse.direct_pressure_held_by != null:
        _fail(failures, "corpse_press: corpse's held-by link must clear on the death gate")
    if not medic.direct_pressure_on_ally.is_empty():
        _fail(failures, "corpse_press: the medic's on-ally record must clear when the casualty dies")
    if not corpse.direct_pressure_on_ally.is_empty():
        _fail(failures, "corpse_press: a corpse must not keep its on-ally hold (dead holder)")
    if not live_pressed.direct_pressure_part.is_empty():
        _fail(
            failures,
            (
                "corpse_press: living ally's pressure must clear when its holder dies (got %s)"
                % str(live_pressed.direct_pressure_part)
            )
        )
    if live_pressed.direct_pressure_held_by != null:
        _fail(failures, "corpse_press: living ally's held-by must clear when its holder dies")
    # A LIVING casualty keeps its holds through a day-advance (only the death gate clears them).
    var live_holder: Node = _new_entity("SWORD")
    var live_held: Node = _new_entity("SWORD")
    live_held.wounds["right_leg"] = [
        {
            "created_at_game_time": 100000.0,
            "healing_duration_seconds": 120000.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT
        },
    ]
    live_held.direct_pressure_part = "right_leg"
    live_held.direct_pressure_held_by = live_holder
    live_holder.direct_pressure_on_ally = {"node": live_held, "part": "right_leg"}
    EntityHealing._process_healing(live_held, HealingConstants.SECONDS_PER_DAY)
    if live_held.direct_pressure_part != "right_leg" or live_held.direct_pressure_held_by == null:
        _fail(failures, "corpse_press: a living casualty's pressure must survive a day-advance")
    if live_holder.direct_pressure_on_ally.is_empty():
        _fail(failures, "corpse_press: a living holder's on-ally record must survive a day-advance")
    MedicalPhaseGateTests._free_entity_fixture(medic)
    MedicalPhaseGateTests._free_entity_fixture(corpse)
    MedicalPhaseGateTests._free_entity_fixture(live_pressed)
    MedicalPhaseGateTests._free_entity_fixture(live_holder)
    MedicalPhaseGateTests._free_entity_fixture(live_held)

## A death roll that latches MID-ADVANCE (sepsis/tetanus) must stop the REST of the same advance:
## the entry gate only protects later advances, so without this the tissue/bone regrow and the
## blood-recovery blocks run on the fresh corpse — regrowing limb pools and popping blood_volume
## back above the death clamp emit_death_once just set (the corpse keeps _sepsis_dead, so the pop
## is invisible to is_dead() but poisons vitals logging / save data). The re-check also severs the
## pressure coupling immediately, exactly like the entry death gate.
