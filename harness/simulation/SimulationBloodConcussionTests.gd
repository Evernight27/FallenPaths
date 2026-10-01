class_name SimulationBloodConcussionTests

extends SimulationCombatBase

## S1 blood-volume + consciousness + concussion realism: ml-pool mass
## scaling, TTD parity, percent sync, notify-died, tissue penetration
## (shallow/deep/cuirass), ATLS consciousness boundaries, blood-rate
## endurance, overall damage ratio, concussion severity/trigger/
## rotational-mtb/SIS, and persistent-fatigue session reset.


static func _run_sim_blood_ml_pool_human_goblin_mass_scale(failures: PackedStringArray) -> void:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var human: CoreEntity = SimulationCombatBase._harness_entity_with_ml_pool(HumanSpecies)
    var goblin: CoreEntity = SimulationCombatBase._harness_entity_with_ml_pool(GoblinSpecies)
    var hum_max: float = human.blood_volume_ml_max
    var gob_max: float = goblin.blood_volume_ml_max
    if not is_equal_approx(hum_max, BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT):
        SimulationCombatTests._fail(
            failures,
            "sim_blood_ml: human max want %.0f got %.0f" % [BloodVolumeMl.REFERENCE_BLOOD_VOLUME_ML_ADULT, hum_max]
        )
    if gob_max >= hum_max - 1.0:
        SimulationCombatTests._fail(
            failures, "sim_blood_ml: goblin max %.0f should be < human %.0f" % [gob_max, hum_max]
        )
    var want_gob: float = BloodVolumeMl.blood_volume_ml_max_for_reference_mass(38.0)
    if not is_equal_approx(gob_max, want_gob):
        SimulationCombatTests._fail(failures, "sim_blood_ml: goblin max want %.0f got %.0f" % [want_gob, gob_max])
    BloodVolumeMl._harness_force_literal_blood_ml = false


## S6: same bleed rate -> same seconds-to-death in % mode vs mL mode (ATLS bridge).


static func _run_sim_blood_ml_ttd_matches_percent_mode(failures: PackedStringArray) -> void:
    var rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ttd_pct: float = BleedingConstants.seconds_to_exsanguination(rate, BleedingConstants.MAX_BLOOD_VOLUME, 1.0)
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent_ml: CoreEntity = SimulationCombatBase._harness_entity_with_ml_pool(HumanSpecies)
    var max_ml: float = ent_ml.blood_volume_ml_max
    var buffer_ml: float = (
        max_ml
        * (
            (BleedingConstants.MAX_BLOOD_VOLUME - BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD)
            / BleedingConstants.MAX_BLOOD_VOLUME
        )
    )
    var loss_ml_s: float = BloodVolumeMl.blood_ml_loss_per_second(rate, max_ml, 1.0)
    var ttd_ml: float = buffer_ml / loss_ml_s if loss_ml_s > 0.01 else 0.0
    BloodVolumeMl._harness_force_literal_blood_ml = false
    if not is_equal_approx(ttd_pct, ttd_ml):
        SimulationCombatTests._fail(
            failures, "sim_blood_ml_ttd: percent %.1fs vs ml %.1fs (rate=%.2f)" % [ttd_pct, ttd_ml, rate]
        )


## S6: one process_blood_loss tick keeps blood_volume % in sync with mL pool.


static func _run_sim_blood_ml_sync_percent_from_ml(failures: PackedStringArray) -> void:
    BloodVolumeMl._harness_force_literal_blood_ml = true
    var ent: CoreEntity = SimulationCombatBase._harness_entity_with_ml_pool(HumanSpecies)
    ent.take_damage_split(8.0, 2.0, "right_arm")
    ent.blood_volume_ml = ent.blood_volume_ml_max * 0.6
    BloodVolumeMl.sync_percent_from_ml(ent)
    if not is_equal_approx(ent.blood_volume, 60.0):
        SimulationCombatTests._fail(
            failures, "sim_blood_ml_sync: 60%% pool want blood_volume=60 got %.2f" % ent.blood_volume
        )
    var rate: float = EntityWounds.get_total_bleeding_rate(ent)
    if rate <= 0.0:
        SimulationCombatTests._fail(failures, "sim_blood_ml_sync: need bleed rate")
        return
    var ml_before: float = ent.blood_volume_ml
    var pct_before: float = ent.blood_volume
    ent._set_combat_blood_loss_mult(1.0)
    EntityWounds.process_blood_loss(ent, 1.0)
    var want_loss_pct: float = rate * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER
    var want_loss_ml: float = BloodVolumeMl.blood_ml_loss_per_second(rate, ent.blood_volume_ml_max, 1.0)
    if not is_equal_approx(pct_before - ent.blood_volume, want_loss_pct):
        SimulationCombatTests._fail(
            failures, "sim_blood_ml_sync: pct loss %.3f want %.3f" % [pct_before - ent.blood_volume, want_loss_pct]
        )
    if not is_equal_approx(ml_before - ent.blood_volume_ml, want_loss_ml):
        SimulationCombatTests._fail(
            failures, "sim_blood_ml_sync: ml loss %.1f want %.1f" % [ml_before - ent.blood_volume_ml, want_loss_ml]
        )


## Death signal fires once per entity (map bleed / repeated process_blood_loss ticks).


static func _run_sim_notify_died_emits_once(failures: PackedStringArray) -> void:
    var ent: CoreEntity = SimulationCombatBase._sim_entity()
    var fired_box: Array = [0]
    ent.died.connect(func() -> void: fired_box[0] = int(fired_box[0]) + 1)
    ent._notify_died()
    ent._notify_died()
    if int(fired_box[0]) != 1:
        SimulationCombatTests._fail(failures, "notify_died: want 1 died signal got %d" % int(fired_box[0]))
    var bleed_ent: CoreEntity = _new_entity("SWORD")
    bleed_ent.take_damage_split(6.0, 2.0, "chest")
    if EntityWounds.get_total_bleeding_rate(bleed_ent) <= 0.0:
        SimulationCombatTests._fail(failures, "notify_died: need bleed rate on wounded entity")
        return
    bleed_ent.blood_volume = 55.0
    bleed_ent._set_combat_blood_loss_mult(1.0)
    bleed_ent._set_combat_blood_recovery_per_s(0.0)
    var bleed_fired: Array = [0]
    bleed_ent.died.connect(func() -> void: bleed_fired[0] = int(bleed_fired[0]) + 1)
    # Ticks to exsanguination from current volume (blood 55 -> death 50) at the clinical TTD band; the loop window must
    # span it regardless of BLOOD_LOSS_RATE_MULTIPLIER calibration.
    var ticks_to_die: int = (
        int(
            ceil(
                BleedingConstants.seconds_to_exsanguination_at_death_threshold(
                    EntityWounds.get_total_bleeding_rate(bleed_ent),
                    bleed_ent.blood_volume,
                    BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD,
                    1.0
                )
            )
        )
        + 5
    )
    for _i in range(ticks_to_die):
        EntityWounds.process_blood_loss(bleed_ent, 1.0)
    if int(bleed_fired[0]) != 1:
        SimulationCombatTests._fail(
            failures, "notify_died: blood_loss ticks want 1 died signal got %d" % int(bleed_fired[0])
        )
    bleed_ent.apply_species()
    var refire_box: Array = [0]
    bleed_ent.died.connect(func() -> void: refire_box[0] = int(refire_box[0]) + 1)
    bleed_ent._notify_died()
    if int(refire_box[0]) != 1:
        SimulationCombatTests._fail(
            failures, "notify_died: apply_species should allow one new died signal got %d" % int(refire_box[0])
        )


## S6 layer tissue: shallow penetration absorbed by soft-tissue budget -> less bone via MFB pen gate.


static func _run_sim_layer_tissue_shallow_pen_reduces_bone(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue = true
    var part: String = "right_arm"
    var sub: String = "forearm"
    var cut: float = 14.0
    var pen_mid: float = 6.0
    var off: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen_mid, -1.0)
    var layer: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, pen_mid, true)
    var on: Dictionary = (
        CombatDamageMechanism
        . allocate_bone_and_tissue(
            cut,
            0.0,
            cut,
            part,
            sub,
            float(layer.get("penetration_to_bone_mm", pen_mid)),
            -1.0,
        )
    )
    CombatLayerTissue._harness_force_layer_tissue = false
    if float(layer.get("penetration_to_bone_mm", -1.0)) >= CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
        (
            SimulationCombatTests
            . _fail(
                failures,
                (
                    "sim_layer_tissue_shallow: pen %.1f absorbed should leave to_bone < %.2f got %.2f"
                    % [
                        pen_mid,
                        CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM,
                        float(layer.get("penetration_to_bone_mm", 0.0)),
                    ]
                )
            )
        )
    if float(off.get("to_bone", 0.0)) <= 0.0:
        SimulationCombatTests._fail(failures, "sim_layer_tissue_shallow: need baseline bone from pen for comparison")
    if float(on.get("to_bone", 0.0)) >= float(off.get("to_bone", 0.0)):
        SimulationCombatTests._fail(
            failures,
            (
                "sim_layer_tissue_shallow: layer on bone %.2f should be < off %.2f"
                % [float(on.get("to_bone", 0.0)), float(off.get("to_bone", 0.0))]
            )
        )


## S6 layer tissue: penetration beyond budget reaches bone MFB pen threshold.


static func _run_sim_layer_tissue_deep_pen_reaches_bone(failures: PackedStringArray) -> void:
    CombatLayerTissue._harness_force_layer_tissue = true
    var part: String = "right_arm"
    var sub: String = "forearm"
    var cut: float = 14.0
    var pen_deep: float = 8.0
    var layer: Dictionary = CombatLayerTissue.penetration_after_soft_tissue(part, pen_deep, true)
    var pen_bone: float = float(layer.get("penetration_to_bone_mm", 0.0))
    if pen_bone < CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_layer_tissue_deep: pen_to_bone %.2f want >= %.2f"
                % [pen_bone, CombatDamageMechanism.MFB_CUT_BONE_MIN_PENETRATION_MM]
            )
        )
    var alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen_bone, -1.0)
    CombatLayerTissue._harness_force_layer_tissue = false
    if float(alloc.get("to_bone", 0.0)) < 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_layer_tissue_deep: want bone chip at pen %.1f (to_bone=%.2f)"
                % [pen_deep, float(alloc.get("to_bone", 0.0))]
            )
        )


## S7: armor layer stack consumes RHA depth  -  shallow pen stopped before tissue.


static func _run_sim_pen_trace_cuirass_stops_shallow(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if cuirass == null:
        SimulationCombatTests._fail(failures, "sim_pen_trace: missing CUIRASS")
        return
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, 3.0)
    if not bool(trace.get("stopped_by_armor", false)):
        SimulationCombatTests._fail(failures, "sim_pen_trace: pen 3 mm should stop on cuirass plate")
    if float(trace.get("penetration_to_tissue_mm", -1.0)) > 0.01:
        SimulationCombatTests._fail(
            failures,
            "sim_pen_trace: shallow pen tissue mm want 0 got %.2f" % float(trace.get("penetration_to_tissue_mm", 0.0))
        )


## S7: pen beyond cloth+plate stack reaches tissue with remainder.


static func _run_sim_pen_trace_cuirass_deep_reaches_tissue(failures: PackedStringArray) -> void:
    var cuirass: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if cuirass == null:
        SimulationCombatTests._fail(failures, "sim_pen_trace_deep: missing CUIRASS")
        return
    var pen_deep: float = 6.0
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(cuirass, pen_deep)
    var to_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
    ## CUIRASS fixture = cloth (0.9 mm RHA) + plate (3.5 mm RHA) = 4.4 mm total resistance.
    ## Source: ArmorConstants.LAYER_CLOTH.sharp_resistance_rha_mm + LAYER_PLATE.sharp_resistance_rha_mm.
    var cloth_res: float = ArmorConstants.LAYER_CLOTH["sharp_resistance_rha_mm"]
    var plate_res: float = ArmorConstants.LAYER_PLATE["sharp_resistance_rha_mm"]
    var want_remainder: float = pen_deep - cloth_res - plate_res
    if not is_equal_approx(to_tissue, want_remainder):
        SimulationCombatTests._fail(
            failures,
            "sim_pen_trace_deep: tissue pen %.2f want ~%.2f (cloth+plate consumed)" % [to_tissue, want_remainder]
        )


## S7: post-armor tissue pen gates sharp-dominant MFB bone (cuirass vs bare pen).


static func _run_sim_pen_entity_damage_armor_reduces_bone(failures: PackedStringArray) -> void:
    var armor: ArmorPiece = HarnessFixtures.get_cached_armor("CUIRASS")
    if armor == null:
        SimulationCombatTests._fail(failures, "sim_pen_damage: missing CUIRASS")
        return
    var pen: float = 5.0
    var cut: float = 14.0
    var part: String = "chest"
    var sub: String = "thoracic"
    var trace: Dictionary = ArmorPenetrationTrace.sharp_penetration_to_tissue_mm(armor, pen)
    var pen_tissue: float = float(trace.get("penetration_to_tissue_mm", 0.0))
    var bare_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(cut, 0.0, cut, part, sub, pen, -1.0)
    var arm_alloc: Dictionary = CombatDamageMechanism.allocate_bone_and_tissue(
        cut, 0.0, cut, part, sub, pen_tissue, -1.0
    )
    if float(bare_alloc.get("to_bone", 0.0)) <= 0.0:
        SimulationCombatTests._fail(failures, "sim_pen_damage: bare MFB want bone at pen %.1f" % pen)
    if float(arm_alloc.get("to_bone", 0.0)) >= float(bare_alloc.get("to_bone", 0.0)) - 0.01:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_pen_damage: armored sharp bone %.2f should be < bare %.2f (tissue pen %.2f)"
                % [float(arm_alloc.get("to_bone", 0.0)), float(bare_alloc.get("to_bone", 0.0)), pen_tissue]
            )
        )


## S7: ATLS hemorrhage class boundaries (remaining blood %).


static func _run_sim_atls_consciousness_class_boundaries(failures: PackedStringArray) -> void:
    if not BleedingConstants.FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS:
        SimulationCombatTests._fail(failures, "sim_atls: FEATURE_ATLS_STEPPED_BLOOD_CONSCIOUSNESS must be on")
        return
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(90.0) != 1:
        SimulationCombatTests._fail(failures, "sim_atls: 90%% remaining want class I")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(75.0) != 2:
        SimulationCombatTests._fail(failures, "sim_atls: 75%% remaining want class II")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(65.0) != 3:
        SimulationCombatTests._fail(failures, "sim_atls: 65%% remaining want class III")
    if BleedingConstants.atls_hemorrhage_class_from_remaining_pct(50.0) != 4:
        SimulationCombatTests._fail(failures, "sim_atls: 50%% remaining want class IV")
    var mod_85: float = BleedingConstants.blood_consciousness_modifier_from_remaining(
        85.0,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )
    var mod_35: float = BleedingConstants.blood_consciousness_modifier_from_remaining(
        35.0,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_START_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD,
        PainConsciousnessConstants.BLOOD_CONSCIOUSNESS_REDUCTION_MAX
    )
    if not is_equal_approx(mod_85, 1.0):
        SimulationCombatTests._fail(failures, "sim_atls: mod at 85%% want 1.0 got %.3f" % mod_85)
    if not is_equal_approx(mod_35, 0.04):
        SimulationCombatTests._fail(failures, "sim_atls: mod at 35%% want 0.04 got %.3f" % mod_35)
    # Realism gate: deep blood loss ALONE (healthy head) must drive unconsciousness (hypovolemic syncope).
    # At the floor (35% remaining = 65% lost) a healthy-headed fighter's consciousness must fall below the
    # incapacitation threshold; at 70% remaining (Class II/III) the same fighter must stay conscious.
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var head_max: int = ent.body_max.get(BodyPartConstants.PART_HEAD, 1)
    ent.body_cutting[BodyPartConstants.PART_HEAD] = float(head_max)
    ent.body_blunt[BodyPartConstants.PART_HEAD] = float(head_max)
    ent.blood_volume = 35.0
    ent._consciousness_dirty = true
    EntityPainConsciousness.update_consciousness(ent)
    if ent.effective_consciousness >= PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_atls: blood-loss-alone at 35%% remaining should be unconscious (consc < %.1f) got %.2f"
                % [PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD, ent.effective_consciousness]
            )
        )
    ent.blood_volume = 70.0
    ent._consciousness_dirty = true
    EntityPainConsciousness.update_consciousness(ent)
    if ent.effective_consciousness < PainConsciousnessConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
        SimulationCombatTests._fail(
            failures,
            "sim_atls: 70%% remaining healthy head should stay conscious got %.2f" % ent.effective_consciousness
        )


## S7: blood-loss consciousness modifier decreases monotonically with volume loss.


static func _run_sim_atls_consciousness_monotonic(failures: PackedStringArray) -> void:
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var prev: float = 1.0
    for pct in [100.0, 85.0, 80.0, 70.0, 65.0, 55.0, 40.0, 35.0]:
        ent.blood_volume = pct
        var mod: float = EntityPainConsciousness.get_blood_consciousness_modifier(ent)
        if mod > prev + 0.001:
            SimulationCombatTests._fail(
                failures, "sim_atls_mono: mod %.3f at %.0f%% > prev %.3f (non-monotonic)" % [mod, pct, prev]
            )
        prev = mod


## S7: rate/endurance-aware syncope shift (Gap 3). The ATLS stepped curve now shifts
## effective remaining % by bleeding rate (down) and endurance (up) before evaluating.
## Reference conditions (rate=0, endurance=100) produce no shift (backward compatible).


static func _run_sim_blood_consc_rate_endurance_aware(failures: PackedStringArray) -> void:
    # --- Pure function: reference conditions = identity ---
    var ref_adj: float = BleedingConstants.adjusted_remaining_for_consciousness(70.0, 0.0, 100.0)
    if not is_equal_approx(ref_adj, 70.0):
        SimulationCombatTests._fail(
            failures, "blood_consc_ref: reference (rate=0, end=100) want 70.0 got %.2f" % ref_adj
        )

    # --- Pure function: high rate shifts effective remaining DOWN ---
    var high_rate: float = BleedingConstants.adjusted_remaining_for_consciousness(70.0, 1.0, 100.0)
    if not is_equal_approx(high_rate, 50.0):
        SimulationCombatTests._fail(failures, "blood_consc_rate: rate=1.0%/s want 50.0 got %.2f" % high_rate)
    if high_rate >= ref_adj:
        SimulationCombatTests._fail(failures, "blood_consc_rate_mono: high rate should lower effective remaining")

    # --- Pure function: partial rate produces partial shift ---
    var low_rate: float = BleedingConstants.adjusted_remaining_for_consciousness(70.0, 0.25, 100.0)
    if not is_equal_approx(low_rate, 65.0):
        SimulationCombatTests._fail(failures, "blood_consc_rate_partial: rate=0.25%/s want 65.0 got %.2f" % low_rate)
    if low_rate >= ref_adj or low_rate <= high_rate:
        SimulationCombatTests._fail(
            failures, "blood_consc_rate_order: partial (65) must sit between ref (70) and full (50)"
        )

    # --- Pure function: high endurance shifts effective remaining UP ---
    var high_end: float = BleedingConstants.adjusted_remaining_for_consciousness(70.0, 0.0, 140.0)
    var expected_end: float = 70.0 + minf(40.0 * 0.18, 12.0)
    if absf(high_end - expected_end) > 0.01:
        SimulationCombatTests._fail(
            failures, "blood_consc_end_high: end=140 want %.1f got %.2f" % [expected_end, high_end]
        )
    if high_end <= ref_adj:
        SimulationCombatTests._fail(failures, "blood_consc_end_mono: high endurance should raise effective remaining")

    # --- Pure function: low endurance shifts effective remaining DOWN ---
    var low_end: float = BleedingConstants.adjusted_remaining_for_consciousness(70.0, 0.0, 40.0)
    var expected_end_low: float = 70.0 + clampf((40.0 - 100.0) * 0.18, -12.0, 12.0)
    if absf(low_end - expected_end_low) > 0.01:
        SimulationCombatTests._fail(
            failures, "blood_consc_end_low: end=40 want %.1f got %.2f" % [expected_end_low, low_end]
        )

    # --- Integration: bleeding rate reduces modifier vs no-bleed at same volume ---
    var ent: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    ent.blood_volume = 65.0
    ent.endurance = 100
    var mod_no_bleed: float = EntityPainConsciousness.get_blood_consciousness_modifier(ent)
    ent.wounds[BodyPartConstants.PART_RIGHT_ARM] = [
        {"injury_type": "cut", "severity": "severe", "current_bleeding_rate": 85.0}
    ]
    var mod_bleeding: float = EntityPainConsciousness.get_blood_consciousness_modifier(ent)
    if mod_bleeding >= mod_no_bleed:
        SimulationCombatTests._fail(
            failures,
            "blood_consc_integ: bleeding mod %.3f should be < no-bleed mod %.3f" % [mod_bleeding, mod_no_bleed]
        )


## S9: overall damage ratio tracks real tissue loss (body_cutting/body_blunt store REMAINING health).
## Guards the concussion-severity path: a healthy entity must read ~0% damaged, a destroyed one ~100%.
## Regression: the old formula (max—remaining—remaining) inverted this, reporting healthy = 100% damaged.


static func _run_sim_overall_damage_ratio_tracks_tissue(failures: PackedStringArray) -> void:
    var healthy: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var healthy_ratio: float = EntityPainConsciousness._get_entity_overall_damage_ratio(healthy)
    if healthy_ratio > 0.05:
        SimulationCombatTests._fail(
            failures, "sim_dmg_ratio: healthy entity want ~0%% damaged got %.2f" % healthy_ratio
        )
    # Destroy every part (cutting + blunt -> 0) -> fully damaged.
    var destroyed: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    for part in destroyed.body_max:
        destroyed.body_cutting[part] = 0.0
        destroyed.body_blunt[part] = 0.0
    var destroyed_ratio: float = EntityPainConsciousness._get_entity_overall_damage_ratio(destroyed)
    if destroyed_ratio < 0.95:
        SimulationCombatTests._fail(
            failures, "sim_dmg_ratio: destroyed entity want ~100%% damaged got %.2f" % destroyed_ratio
        )
    # Half-damage one part -> ratio strictly between healthy and destroyed.
    var half: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var some_part: String = half.body_max.keys()[0]
    var mx: float = half.body_max[some_part]
    half.body_cutting[some_part] = mx * 0.5
    half.body_blunt[some_part] = mx * 0.5
    var half_ratio: float = EntityPainConsciousness._get_entity_overall_damage_ratio(half)
    if half_ratio <= healthy_ratio or half_ratio >= destroyed_ratio:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_dmg_ratio: half-damage %.2f must sit between healthy %.2f and destroyed %.2f"
                % [half_ratio, healthy_ratio, destroyed_ratio]
            )
        )


## S9: concussion severity scales with cumulative damage (weighted_severity blends head-bone + overall damage).
## A heavily-damaged entity concussed by the same head-bone ratio must be at least as severe as a healthy one.


static func _run_sim_concussion_severity_scales_with_damage(failures: PackedStringArray) -> void:
    var healthy: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var damaged: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    for part in damaged.body_max:
        damaged.body_cutting[part] = 0.0
        damaged.body_blunt[part] = 0.0
    var bone_ratio: float = 1.0
    # within CONCUSSION_BONE_THRESHOLD range (MIN 0.75, MAX 1.5): transmitted-KE/fracture-anchor ratio
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(healthy, bone_ratio)
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(damaged, bone_ratio)
    var healthy_until: float = float(healthy.get_meta("_concussion_until_time", 0.0))
    var damaged_until: float = float(damaged.get_meta("_concussion_until_time", 0.0))
    if healthy_until <= 0.0 or damaged_until <= 0.0:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion: expected concussion on both (healthy_until=%.1f damaged_until=%.1f)"
                % [healthy_until, damaged_until]
            )
        )
        return
    if damaged_until < healthy_until - 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion: damaged entity recovery %.1fs should be >= healthy %.1fs (severity scales with damage)"
                % [damaged_until, healthy_until]
            )
        )


## S9b: concussion trigger is REACHABLE — a transmitted-KE ratio just above CONCUSSION_BONE_THRESHOLD_MIN
## (post-tissue-KE / sub-region fracture anchor) concusses, while a ratio just below it does not. Guards
## against the regression where the trigger used the clamped to_bone (ratio always <= 1.0) and the threshold
## was unreachable (dead code). Under the KE-ratio model the threshold sits BELOW 1.0 (concussion onset is
## below fracture energy), so the reachability guard checks a valid 0 < threshold < MAX band.


static func _run_sim_concussion_trigger_reachable_threshold(failures: PackedStringArray) -> void:
    var threshold: float = EntityConcussion.CONCUSSION_BONE_THRESHOLD_MIN
    if threshold <= 0.0 or threshold >= EntityConcussion.CONCUSSION_BONE_THRESHOLD_MAX:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_reach: threshold %.2f must be in (0, MAX %.2f)"
                % [threshold, EntityConcussion.CONCUSSION_BONE_THRESHOLD_MAX]
            )
        )
        return
    var above: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var below: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var above_ratio: float = threshold + 0.1  # just above the threshold -> should concuss
    var below_ratio: float = threshold - 0.1  # just below the threshold -> should NOT concuss
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(above, above_ratio)
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(below, below_ratio)
    var above_until: float = float(above.get_meta("_concussion_until_time", 0.0))
    var below_until: float = float(below.get_meta("_concussion_until_time", 0.0))
    if above_until <= 0.0:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_reach: ratio %.2f (above threshold %.2f) should concuss (until=%.1f)"
                % [above_ratio, threshold, above_until]
            )
        )
    if below_until > 0.0:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_reach: ratio %.2f (below threshold %.2f) should NOT concuss (until=%.1f)"
                % [below_ratio, threshold, below_until]
            )
        )


## S9c: rotational (Rowson/Duma) mTBI channel — pins the fracture-anchored alpha mapping and its entry gate.
## (a) alpha is monotonic in transmitted head KE; (b) fracture-anchored mild/severe thresholds are ordered
## and align with the linear channel's 0.75x/1.5x band (mild = alpha(0.75*anchor)); (c) below the mild alpha
## no concussion registers, above it one does, and a severe (>=1.5x anchor) blow recovers no faster than a
## mid-severity one (severity scaling through the shared SIS/recovery path).


static func _run_sim_concussion_rotational_mtb_i(failures: PackedStringArray) -> void:
    var anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(BodyPartConstants.PART_HEAD, "scalp")
    if anchor <= 0.0:
        SimulationCombatTests._fail(
            failures, "sim_concussion_rot: head fracture anchor must be > 0 (got %.1f)" % anchor
        )
        return
    # (a) monotonic alpha: higher transmitted head KE -> higher angular acceleration.
    var a_low: float = EntityPainConsciousness.head_rotational_accel_rad_s2(2.0)
    var a_mid: float = EntityPainConsciousness.head_rotational_accel_rad_s2(5.0)
    var a_high: float = EntityPainConsciousness.head_rotational_accel_rad_s2(10.0)
    if not (0.0 < a_low and a_low < a_mid and a_mid < a_high):
        SimulationCombatTests._fail(
            failures,
            "sim_concussion_rot: alpha must increase with KE (low=%.1f mid=%.1f high=%.1f)" % [a_low, a_mid, a_high]
        )
        return
    # (b) fracture-anchored thresholds are ordered and mild == alpha at 0.75x anchor (band alignment).
    var thr: Array = EntityPainConsciousness.rotational_alpha_thresholds_for_fracture_anchor(anchor)
    var mild: float = float(thr[0])
    var severe: float = float(thr[1])
    if mild <= 0.0 or mild >= severe:
        SimulationCombatTests._fail(
            failures,
            "sim_concussion_rot: thresholds must be 0 < mild < severe (mild=%.1f severe=%.1f)" % [mild, severe]
        )
        return
    var mild_expected: float = EntityPainConsciousness.head_rotational_accel_rad_s2(0.75 * anchor)
    if not is_equal_approx(mild, mild_expected):
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_rot: mild threshold %.2f must equal alpha(0.75*anchor=%.2f)=%.2f (band alignment)"
                % [mild, 0.75 * anchor, mild_expected]
            )
        )
        return
    # (c) entry gate: below mild alpha -> no concussion; above -> concussion; severe >= mid in recovery.
    var e_low: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var e_mid: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var e_high: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var alpha_low: float = EntityPainConsciousness.head_rotational_accel_rad_s2(0.5 * anchor)  # < mild
    var alpha_mid: float = EntityPainConsciousness.head_rotational_accel_rad_s2(1.0 * anchor)  # mild..severe
    var alpha_high: float = EntityPainConsciousness.head_rotational_accel_rad_s2(2.0 * anchor)  # >= severe
    EntityPainConsciousness.try_enter_concussion_from_rotation(e_low, alpha_low, mild, severe)
    EntityPainConsciousness.try_enter_concussion_from_rotation(e_mid, alpha_mid, mild, severe)
    EntityPainConsciousness.try_enter_concussion_from_rotation(e_high, alpha_high, mild, severe)
    var low_until: float = float(e_low.get_meta("_concussion_until_time", 0.0))
    var mid_until: float = float(e_mid.get_meta("_concussion_until_time", 0.0))
    var high_until: float = float(e_high.get_meta("_concussion_until_time", 0.0))
    if low_until > 0.0:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_rot: alpha=%.1f below mild %.1f should NOT concuss (until=%.1f)"
                % [alpha_low, mild, low_until]
            )
        )
    if mid_until <= 0.0:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_rot: alpha=%.1f between mild %.1f and severe %.1f should concuss (until=%.1f)"
                % [alpha_mid, mild, severe, mid_until]
            )
        )
    if high_until < mid_until - 0.5:
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_rot: severe alpha=%.1f recovery %.1fs should be >= mid alpha=%.1f recovery %.1fs"
                % [alpha_high, high_until, alpha_mid, mid_until]
            )
        )


## Persistent concussion fatigue is a per-session brain impairment: it must reset with the other
## concussion metas on apply_species, or it ratchets a permanent performance penalty across campaigns.


static func _run_persistent_fatigue_resets_between_sessions(failures: PackedStringArray) -> void:
    var e: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    e.set_meta("_concussion_persistent_fatigue", 0.3)
    e.apply_species()
    if e.has_meta("_concussion_persistent_fatigue"):
        SimulationCombatTests._fail(
            failures,
            (
                "conc_fatigue_reset: persistent fatigue must be cleared on apply_species (got %.2f)"
                % float(e.get_meta("_concussion_persistent_fatigue", 0.0))
            )
        )


## S9c-catastrophic: a purely rotational re-impact can trigger a SIS catastrophic outcome. Before the
## fix the rotational channel clamped severity to 2.0 BEFORE the >= 4.0 catastrophic gate, so a
## rotational-only fighter could never take a SIS catastrophic result — an asymmetry with the
## head-bone channel (which passes the unclamped raw severity). High cumulative count + severe alpha
## pushes the raw severity past the gate.


static func _run_sim_concussion_rot_sis_catastrophic(failures: PackedStringArray) -> void:
    var anchor: float = CombatDamageMechanism.blunt_fracture_j_anchor(BodyPartConstants.PART_HEAD, "scalp")
    if anchor <= 0.0:
        SimulationCombatTests._fail(failures, "sim_concussion_rot_sis: head fracture anchor must be > 0")
        return
    var e: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    var thr: Array = EntityPainConsciousness.rotational_alpha_thresholds_for_fracture_anchor(anchor)
    var mild: float = float(thr[0])
    var severe: float = float(thr[1])
    var alpha_high: float = EntityPainConsciousness.head_rotational_accel_rad_s2(2.0 * anchor)
    # First rotational impact: concusses the entity (sets _concussion_until_time).
    EntityPainConsciousness.try_enter_concussion_from_rotation(e, alpha_high, mild, severe)
    if not e.has_meta("_concussion_until_time"):
        SimulationCombatTests._fail(failures, "sim_concussion_rot_sis: first rotational impact should concuss")
        return
    # High cumulative count so the second impact's raw severity reaches the >= 4.0 catastrophic gate:
    # severity(1.0) x (1.0 + 20 x 0.15 = 4.0) = 4.0.
    e.set_meta("_cumulative_concussion_count", 20)
    e.set_meta("_concussion_onset_time", 0.0)
    EntityPainConsciousness.try_enter_concussion_from_rotation(e, alpha_high, mild, severe)
    if not bool(e.get_meta("_sis_catastrophic_flag", false)):
        SimulationCombatTests._fail(
            failures,
            (
                "sim_concussion_rot_sis: high-cumulative rotational re-impact should trigger SIS catastrophic (flag "
                + "not set)"
            )
        )


## S9b-clobber: a re-impact that fires a SIS catastrophic outcome must not clobber the 1-12h recovery
## extension the catastrophic path just applied to _concussion_until_time. Before the fix the re-impact
## timeline math (max of the two branches) wrote a plain recovery duration that could be SHORTER than
## the catastrophic extension, silently discarding it. Assert the final until is at least the
## catastrophic floor (U1 + 3600s, the minimum 1h extension).


static func _run_sim_concussion_reimpact_preserves_sis_extension(failures: PackedStringArray) -> void:
    var e: CoreEntity = SimulationCombatBase._entity_for_species(HumanSpecies)
    # First impact: full severity (ratio 1.5 = top of the 0.75-1.5 band -> severity 1.0). Sets
    # until + cumulative_count=1 + onset.
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(e, 1.5)
    var u1: float = float(e.get_meta("_concussion_until_time", 0.0))
    if u1 <= 0.0:
        SimulationCombatTests._fail(failures, "reimp_sis: first impact should concuss (until=%.1f)" % u1)
        return
    # Pin onset to NOW so the re-impact falls in the critical window (SIS multiplier 4.5x).
    # weighted_severity(0.8) x 4.5 x cumulative_bonus(1 + 1*0.15 = 1.15) = 4.14 >= 4.0 -> catastrophic.
    # cumulative_count stays at 1 (from the first impact) — do NOT reset it to 0.
    e.set_meta("_concussion_onset_time", CombatTiming.now_seconds())
    EntityPainConsciousness.try_enter_concussion_from_head_bone_damage(e, 1.5)
    var u2: float = float(e.get_meta("_concussion_until_time", 0.0))
    if not bool(e.get_meta("_sis_catastrophic_flag", false)):
        SimulationCombatTests._fail(
            failures, "reimp_sis: severe re-impact should trigger SIS catastrophic (flag not set)"
        )
    if u2 < u1 + 3600.0 - 1.0:
        SimulationCombatTests._fail(
            failures,
            "reimp_sis: re-impact clobbered the SIS recovery extension (u1=%.1f u2=%.1f, need u2>=u1+3600)" % [u1, u2]
        )

## S8: shallow post-armor penetration -> lower cut severity than deep track at same damage.
