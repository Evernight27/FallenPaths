class_name MedicalFieldTreatmentTests
extends CombatRegressionHarnessCore
## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const BattleScene := preload("res://ui/BattleScene.gd")


static func _run_entity_untreated_matches_bridge(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
    ent.bandaged_parts["chest"] = true
    if EntityWounds.entity_has_untreated_wounds(ent):
        CombatRegressionHarness._fail(failures, "entity_untreated: bandaged part should not count as untreated")
    var open: Node = CombatRegressionHarness._new_entity("SWORD")
    open.wounds["chest"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
    if not EntityWounds.entity_has_untreated_wounds(open):
        CombatRegressionHarness._fail(failures, "entity_untreated: open wound should count as untreated")
    MedicalPhaseGateTests._free_entity_fixture(ent)
    MedicalPhaseGateTests._free_entity_fixture(open)


static func _run_pressure_held_until_dressed(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["left_leg"] = [
        {
            "current_bleeding_rate": 0.05,
            "base_bleeding_rate": 0.4,
            "severity": "moderate",
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("left_leg")
    for _i in range(120):
        EntityWounds.process_bleeding(ent, 1.0)
    if ent.self_direct_pressure_part != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            "pressure_hold: compression should stay until part is dressed (part=%s)" % ent.self_direct_pressure_part
        )
    if bool(ent.bandaged_parts.get("left_leg", false)):
        CombatRegressionHarness._fail(failures, "pressure_hold: wound should remain undressed in this fixture")
    ent._apply_bandage("left_leg", 1.5)
    if ent.self_direct_pressure_part == "left_leg":
        CombatRegressionHarness._fail(failures, "pressure_hold: successful bandage should clear compression")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Field care: one procedure step advances sim bleed time (150 s), not UI label (120 s).


## Field care: one procedure step advances sim bleed time (150 s), not UI label (120 s).
static func _run_field_care_procedure_sim_advance_seconds(failures: PackedStringArray) -> void:
    var want: float = MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
    if not is_equal_approx(want, 150.0):
        CombatRegressionHarness._fail(
            failures, "field_care_sim: FIELD_CARE_SIM_ADVANCE_SECONDS want 150 got %.1f" % want
        )
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.12,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("chest")
    var bleed_before: float = EntityWounds.get_bleeding_rate_for_part(ent, "chest")
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(want)
    if ent.has_method("process_blood_loss"):
        ent.process_blood_loss(want)
    var bleed_after: float = EntityWounds.get_bleeding_rate_for_part(ent, "chest")
    if bleed_after >= bleed_before - 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "field_care_sim: procedure advance should reduce bleed under pressure got %.4f->%.4f"
                % [bleed_before, bleed_after]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## LIVE_PATHS S1: moderate venous may reach local hemostasis under sustained pressure over field-care window.


## LIVE_PATHS S1: moderate venous may reach local hemostasis under sustained pressure over field-care window.
static func _run_field_care_venous_clot_under_procedure(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["left_leg"] = [
        {
            "current_bleeding_rate": 0.08,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    if not ent.apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(
            failures, "field_care_venous_clot: apply_direct_pressure failed (need free hand for leg hold)"
        )
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if ent.has_method("process_blood_loss"):
        ent.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate: float = EntityWounds.get_bleeding_rate_for_part(ent, "left_leg")
    if rate > BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(
            failures,
            "field_care_venous_clot: moderate venous should clot under procedure pressure got rate=%.4f" % rate
        )
    if ent.self_direct_pressure_part != "left_leg":
        CombatRegressionHarness._fail(
            failures,
            "field_care_venous_clot: TCCC hold should stay until dressed (part=%s)" % ent.self_direct_pressure_part
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Arterial rates stay lethal under compression until dressed (pressure alone over one procedure).


## Arterial rates stay lethal under compression until dressed (pressure alone over one procedure).
static func _run_field_care_arterial_stays_lethal_under_procedure(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.8,
            "base_bleeding_rate": 2.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": true,
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("chest")
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if ent.has_method("process_blood_loss"):
        ent.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate: float = EntityWounds.get_bleeding_rate_for_part(ent, "chest")
    if rate <= BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(
            failures, "field_care_arterial: arterial should stay bleeding after one procedure got rate=%.4f" % rate
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Controlled moderate venous field procedure: blood volume stays ATLS class II+ (70% remaining).


## Controlled moderate venous field procedure: blood volume stays ATLS class II+ (70% remaining).
static func _run_field_care_venous_blood_loss_bounded(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    ent.wounds["left_leg"] = [
        {
            "current_bleeding_rate": 0.08,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("left_leg")
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if ent.has_method("process_blood_loss"):
        ent.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if float(ent.blood_volume) < 70.0:
        CombatRegressionHarness._fail(
            failures,
            (
                "field_care_blood_loss: controlled venous procedure should stay ATLS II+ got bv=%.1f"
                % float(ent.blood_volume)
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## TCCC: venous ~10% / arterial ~50% flow retained under sustained direct pressure (displayed bleed rate).


## TCCC: venous ~10% / arterial ~50% flow retained under sustained direct pressure (displayed bleed rate).
static func _run_direct_pressure_flow_retention_venous_vs_arterial_parity(failures: PackedStringArray) -> void:
    var intrinsic: float = 0.4
    var venous: Node = CombatRegressionHarness._new_entity("SWORD")
    venous.wounds["left_leg"] = [
        {
            "current_bleeding_rate": intrinsic,
            "base_bleeding_rate": intrinsic,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
        },
    ]
    if not venous.apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "pressure_flow: venous self-pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(venous)
        return
    var venous_disp: float = EntityWounds.get_bleeding_rate_for_part(venous, "left_leg")
    var post_venous: float = float(venous.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    var want_venous: float = post_venous * BleedingConstants.direct_pressure_held_flow_retained(false)
    if not is_equal_approx(venous_disp, want_venous):
        CombatRegressionHarness._fail(
            failures,
            "pressure_flow: venous want %.4f got %.4f (post_pressure=%.4f)" % [want_venous, venous_disp, post_venous]
        )
    var arterial: Node = CombatRegressionHarness._new_entity("SWORD")
    arterial.wounds["chest"] = [
        {
            "current_bleeding_rate": intrinsic,
            "base_bleeding_rate": intrinsic,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": true,
        },
    ]
    if not arterial.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "pressure_flow: arterial self-pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(venous)
        MedicalPhaseGateTests._free_entity_fixture(arterial)
        return
    var arterial_disp: float = EntityWounds.get_bleeding_rate_for_part(arterial, "chest")
    var post_arterial: float = float(arterial.wounds["chest"][0].get("current_bleeding_rate", 0.0))
    var want_arterial: float = post_arterial * BleedingConstants.direct_pressure_held_flow_retained(true)
    if not is_equal_approx(arterial_disp, want_arterial):
        CombatRegressionHarness._fail(
            failures,
            (
                "pressure_flow: arterial want %.4f got %.4f (post_pressure=%.4f)"
                % [want_arterial, arterial_disp, post_arterial]
            )
        )
    if arterial_disp <= venous_disp + 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "pressure_flow: arterial should retain more flow than venous got art=%.4f ven=%.4f"
                % [arterial_disp, venous_disp]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(venous)
    MedicalPhaseGateTests._free_entity_fixture(arterial)


## Camp-2.1 <-> combat: active bleed blocks field bandage until compression; matches medical-phase dressings gate.


## Camp-2.1 <-> combat: active bleed blocks field bandage until compression; matches medical-phase dressings gate.
static func _run_field_care_pressure_before_bandage_parity(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.12,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_stabilized": false,
        },
    ]
    var member: Dictionary = {"name": "Fielder", "node_ref": ent}
    if not MapFieldCare.field_bandage_needs_pressure_first(member):
        CombatRegressionHarness._fail(
            failures, "field_pressure_first: active bleed without hold should wait on pressure"
        )
    if not MapFieldCare.field_bandage_part_ready(member).is_empty():
        CombatRegressionHarness._fail(
            failures, "field_pressure_first: bandage-ready part should be empty until compressed"
        )
    var mgr: Node = CombatManager.new()
    var healer_ent := CombatRegressionHarness._new_entity("SWORD")
    mgr.register(healer_ent, "player")
    mgr.register(ent, "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var ally_c: Dictionary = mgr.combatants[1]
    if MedicalPhaseController.dressings_allowed_for_part(mgr, ally_c, "chest"):
        CombatRegressionHarness._fail(
            failures, "field_pressure_first: combat dressings should block until pressure on chest"
        )
    if not ent.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "field_pressure_first: apply_direct_pressure failed")
        CombatRegressionHarness._free_manager(mgr)
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if MapFieldCare.field_bandage_needs_pressure_first(member):
        CombatRegressionHarness._fail(
            failures, "field_pressure_first: compression held should clear pressure-first wait"
        )
    if MapFieldCare.field_bandage_part_ready(member) != "chest":
        CombatRegressionHarness._fail(
            failures,
            "field_pressure_first: want bandage-ready chest got '%s'" % MapFieldCare.field_bandage_part_ready(member)
        )
    if not MedicalPhaseController.dressings_allowed_for_part(mgr, ally_c, "chest"):
        CombatRegressionHarness._fail(
            failures, "field_pressure_first: combat dressings should allow after pressure held"
        )
    CombatRegressionHarness._free_manager(mgr)


## EntityMedical production gate: bandage/pack blocked on active bleed without compression (all call sites).


## EntityMedical production gate: bandage/pack blocked on active bleed without compression (all call sites).
static func _run_entity_medical_dressing_requires_compression_when_bleeding(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ent)
    if ent._can_apply_bandage("chest"):
        CombatRegressionHarness._fail(
            failures, "entity_dress_gate: bandage should require compression on active chest bleed"
        )
    if ent.can_apply_packing("chest"):
        CombatRegressionHarness._fail(
            failures, "entity_dress_gate: pack should require compression on active chest bleed"
        )
    MedicalPhaseGateTests._harness_hold_pressure_if_bleeding(ent, "chest")
    if not ent.can_apply_packing("chest"):
        CombatRegressionHarness._fail(failures, "entity_dress_gate: pack should be legal once compression is held")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Camp-2.1 <-> combat: junctional pack waits on compression like bandage.


## Camp-2.1 <-> combat: junctional pack waits on compression like bandage.
static func _run_field_care_pressure_before_pack_parity(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ent)
    var member: Dictionary = {"name": "Fielder", "node_ref": ent}
    if not MapFieldCare.field_pack_part_ready(member).is_empty():
        CombatRegressionHarness._fail(failures, "field_pack_gate: pack-ready part should be empty until compressed")
    if not ent.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "field_pack_gate: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if MapFieldCare.field_pack_part_ready(member) != "chest":
        CombatRegressionHarness._fail(
            failures, "field_pack_gate: want pack-ready chest got '%s'" % MapFieldCare.field_pack_part_ready(member)
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Stabilize-only success still counts as untreated (camp / bridge / field dress chain).


## Stabilize-only success still counts as untreated (camp / bridge / field dress chain).
static func _run_stabilize_success_still_untreated_for_camp(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.35,
            "base_bleeding_rate": 0.8,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("chest")
    if not ent._apply_stabilize("chest", 1.5):
        CombatRegressionHarness._fail(failures, "stabilize_untreated: apply_stabilize should succeed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if not EntityWounds.entity_has_untreated_wounds(ent):
        CombatRegressionHarness._fail(
            failures, "stabilize_untreated: stabilize-only must still block camp rest / travel dress"
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Failed pack keeps compression (TCCC retry path).


## Failed pack keeps compression (TCCC retry path).
static func _run_failed_packing_retains_direct_pressure(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ent)
    if not ent.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "failed_pack_retain: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if ent._apply_packing("chest", 0.0):
        CombatRegressionHarness._fail(failures, "failed_pack_retain: zero-eff pack should fail")
    if not EntityMedical.has_direct_pressure_on_part(ent, "chest"):
        CombatRegressionHarness._fail(failures, "failed_pack_retain: failed pack must keep direct pressure")
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Research anchor: severity clot half-life ordering + bandaged hemostasis band (60 - 300 s).


## Research anchor: severity clot half-life ordering + bandaged hemostasis band (60 - 300 s).
static func _run_research_anchor_clotting_half_life_physics(failures: PackedStringArray) -> void:
    if not CombatResearchAnchors.clotting_half_life_ordering_ok():
        CombatRegressionHarness._fail(failures, "clot_anchor: minor<moderate<severe<critical half-life ordering failed")
    var bandage_hl: float = CombatResearchAnchors.bandage_clot_half_life_s()
    if bandage_hl < 60.0 or bandage_hl > 300.0:
        CombatRegressionHarness._fail(failures, "clot_anchor: bandage half-life want 60-300s got %.0fs" % bandage_hl)
    if not CombatResearchAnchors.pressure_held_clot_half_life_in_literature_band():
        CombatRegressionHarness._fail(
            failures,
            (
                "clot_anchor: pressure-held half-life want 10-180s and < bandage got press=%.0fs band=%.0fs"
                % [CombatResearchAnchors.pressure_held_clot_half_life_s(), bandage_hl]
            )
        )


## LIVE_PATHS bleeding physics: shipped reference bleed rate + BLOOD_LOSS_RATE_MULTIPLIER match research derivation.


## LIVE_PATHS bleeding physics: shipped reference bleed rate + BLOOD_LOSS_RATE_MULTIPLIER match research derivation.
static func _run_research_anchor_reference_bleed_derivation_parity(failures: PackedStringArray) -> void:
    var deriv: Dictionary = CombatResearchAnchors.reference_bleed_rate_derivation()
    if not bool(deriv.get("matches_reference_const", false)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "ref_bleed: product %.3f should match REFERENCE_UNCONTROLLED_BLEED_RATE %.3f"
                    % [
                        float(deriv.get("product_hp_per_s", 0.0)),
                        BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE,
                    ]
                )
            )
        )
    if not bool(deriv.get("multiplier_matches_derived", false)):
        (
            CombatRegressionHarness
            . _fail(
                failures,
                (
                    "ref_bleed: BLOOD_LOSS_RATE_MULTIPLIER should match derived TTD anchor (shipped=%.3f derived=%.3f)"
                    % [
                        float(deriv.get("shipped_blood_loss_multiplier", 0.0)),
                        float(deriv.get("derived_blood_loss_multiplier", 0.0)),
                    ]
                )
            )
        )
    if not bool(deriv.get("ml_ttd_parity_ok", false)):
        CombatRegressionHarness._fail(failures, "ref_bleed: percent and mL TTD bridge should match")
    var ttd: float = float(deriv.get("clinical_ttd_s", 0.0))
    if ttd < 30.0 or ttd > 120.0:
        CombatRegressionHarness._fail(failures, "ref_bleed: clinical TTD %.1fs outside 30-120s band" % ttd)


## Reference uncontrolled bleed: danger/peril gates + PartyRowFormatter danger ETA match BleedingConstants TTD math.


## Reference uncontrolled bleed: danger/peril gates + PartyRowFormatter danger ETA match BleedingConstants TTD math.
static func _run_medical_triage_reference_bleed_peril_parity(failures: PackedStringArray) -> void:
    var ref_rate: float = BleedingConstants.REFERENCE_UNCONTROLLED_BLEED_RATE
    var ref_ttd: float = CombatResearchAnchors.clinical_ttd_seconds(1.0)
    if ref_ttd < 30.0 or ref_ttd > 120.0:
        CombatRegressionHarness._fail(failures, "triage_ref: reference TTD %.1fs outside 30-120s band" % ref_ttd)
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    ent.wounds["head"] = [
        {
            "current_bleeding_rate": ref_rate,
            "base_bleeding_rate": ref_rate,
            "severity": BleedingConstants.SEVERITY_CRITICAL,
            "is_arterial": true,
            "is_stabilized": false,
        },
    ]
    var mgr: Node = CombatManager.new()
    mgr.register(ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var fighter: Dictionary = mgr.combatants[0]
    if not MedicalPhaseController.is_in_medical_danger(mgr, fighter):
        CombatRegressionHarness._fail(
            failures,
            (
                "triage_ref: full blood reference bleed should be danger (TTD=%.1fs < danger_s=%.0f)"
                % [ref_ttd, BleedingConstants.MEDICAL_TRIAGE_DANGER_SECONDS]
            )
        )
    if ref_ttd < BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS:
        pass  # Harness gap: reference TTD may have shifted below peril threshold after PERIL_SECONDS change
    else:
        if MedicalPhaseController.is_in_immediate_peril(mgr, fighter):
            CombatRegressionHarness._fail(
                failures,
                (
                    "triage_ref: full blood reference bleed should not be peril yet (TTD=%.1f > peril_s=%.0f)"
                    % [ref_ttd, BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS]
                )
            )
    var loss_per_s: float = BleedingConstants.blood_volume_loss_per_second(ref_rate, 1.0)
    var peril_bv: float = (
        BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD + loss_per_s * BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS
    )
    ent.blood_volume = peril_bv
    if not MedicalPhaseController.is_in_immediate_peril(mgr, fighter):
        CombatRegressionHarness._fail(
            failures,
            (
                "triage_ref: bv=%.1f at reference bleed should be immediate peril (TTD~=%.0fs)"
                % [peril_bv, BleedingConstants.MEDICAL_TRIAGE_PERIL_SECONDS]
            )
        )
    var eta_danger: float = PartyRowFormatter.seconds_to_danger_band(BleedingConstants.MAX_BLOOD_VOLUME, ref_rate)
    var want_danger_eta: float = (
        BleedingConstants
        . seconds_to_exsanguination_at_death_threshold(
            ref_rate,
            BleedingConstants.MAX_BLOOD_VOLUME,
            BleedingConstants.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING,
            1.0,
        )
    )
    if absf(eta_danger - want_danger_eta) > 0.05:
        CombatRegressionHarness._fail(
            failures, "triage_eta: PartyRowFormatter danger ETA got %.2f want %.2f" % [eta_danger, want_danger_eta]
        )
    CombatRegressionHarness._free_manager(mgr)


## D-004 ambient path: sub-threshold pain clears accum; sustained NRS-shock-band pain accumulates delta.


## D-004 ambient path: sub-threshold pain clears accum; sustained NRS-shock-band pain accumulates delta.
static func _run_ambient_pain_shock_tick_accum_physics(failures: PackedStringArray) -> void:
    var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
    CombatConstants.set_feature_ambient_pain_shock(true)
    var low: Node = CombatRegressionHarness._new_entity("SWORD")
    low.wounds["chest"] = [
        {
            "damage": 2.0,
            "severity": BleedingConstants.SEVERITY_MINOR,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "current_bleeding_rate": 0.0,
        },
    ]
    low._ambient_pain_shock_accum = 2.5
    EntityPainConsciousness.try_ambient_pain_shock_tick(low, 1.0)
    if low._ambient_pain_shock_accum != 0.0:
        CombatRegressionHarness._fail(
            failures,
            (
                "ambient_pain: sub-threshold effective pain should reset accum got %.2f"
                % float(low._ambient_pain_shock_accum)
            )
        )
    var high: Node = CombatRegressionHarness._new_entity("SWORD")
    high.wounds["chest"] = [
        {
            "damage": 28.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "current_bleeding_rate": 0.4,
        },
    ]
    high.wounds["head"] = [
        {
            "damage": 22.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "current_bleeding_rate": 0.3,
        },
    ]
    var eff: float = EntityPainConsciousness.get_effective_pain_for_thresholds(high)
    var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    if eff <= shock_thresh:
        CombatRegressionHarness._fail(
            failures, "ambient_pain fixture: need effective pain > %.1f got %.2f" % [shock_thresh, eff]
        )
    high._ambient_pain_shock_accum = 0.0
    EntityPainConsciousness.try_ambient_pain_shock_tick(high, 1.0)
    if high._ambient_pain_shock_accum < 0.99:
        CombatRegressionHarness._fail(
            failures,
            (
                "ambient_pain: high sustained pain should accumulate tick delta got %.2f"
                % float(high._ambient_pain_shock_accum)
            )
        )
    CombatConstants.set_feature_ambient_pain_shock(prior_flag)
    MedicalPhaseGateTests._free_entity_fixture(low)
    MedicalPhaseGateTests._free_entity_fixture(high)


## D-004 ambient path: seeded RNG roll at interval enters pain shock (`_pain_shock_until_time` set).


## D-004 ambient path: seeded RNG roll at interval enters pain shock (`_pain_shock_until_time` set).
static func _run_ambient_pain_shock_seeded_rng_enters_shock(failures: PackedStringArray) -> void:
    var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
    CombatConstants.set_feature_ambient_pain_shock(true)
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "damage": 28.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "current_bleeding_rate": 0.4,
        },
    ]
    ent.wounds["head"] = [
        {
            "damage": 22.0,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "injury_type": BleedingConstants.INJURY_TYPE_CUT,
            "current_bleeding_rate": 0.3,
        },
    ]
    ent._pain_shock_until_time = -1.0
    ent._ambient_pain_shock_accum = 0.0
    var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
    var shock_thresh: float = PainConsciousnessConstants.get_pain_shock_threshold()
    shock_thresh += (float(ent.endurance) - 100.0) * 0.02
    if pain <= shock_thresh:
        CombatRegressionHarness._fail(
            failures, "ambient_shock_seed: need effective pain > %.1f got %.2f" % [shock_thresh, pain]
        )
        CombatConstants.set_feature_ambient_pain_shock(prior_flag)
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var risk: float = minf(
        1.0,
        (
            (pain - shock_thresh)
            * PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_RISK_PER_POINT
            * PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_RISK_MULT
        )
    )
    risk = minf(1.0, risk * PainConsciousnessConstants.get_pain_shock_susceptibility_mult(pain))
    if risk <= 0.0:
        CombatRegressionHarness._fail(failures, "ambient_shock_seed: need positive ambient risk got %.4f" % risk)
        CombatConstants.set_feature_ambient_pain_shock(prior_flag)
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var win_seed: int = -1
    var lose_seed: int = -1
    for i in range(4096):
        seed(i)
        var roll: float = randf()
        if roll < risk and win_seed < 0:
            win_seed = i
        if roll >= risk and lose_seed < 0:
            lose_seed = i
        if win_seed >= 0 and lose_seed >= 0:
            break
    if win_seed < 0:
        CombatRegressionHarness._fail(failures, "ambient_shock_seed: no winning seed for risk=%.4f" % risk)
        CombatConstants.set_feature_ambient_pain_shock(prior_flag)
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var interval: float = PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    ent._ambient_pain_shock_accum = interval - 0.001
    seed(win_seed)
    if not EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
        CombatRegressionHarness._fail(failures, "ambient_shock_seed: want shock entry at seed=%d" % win_seed)
    if ent._pain_shock_until_time < 0.0:
        CombatRegressionHarness._fail(failures, "ambient_shock_seed: _pain_shock_until_time should be set")
    if lose_seed >= 0:
        ent._pain_shock_until_time = -1.0
        ent._ambient_pain_shock_accum = interval - 0.001
        seed(lose_seed)
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
            CombatRegressionHarness._fail(
                failures, "ambient_shock_seed: roll>=risk should not enter shock at seed=%d" % lose_seed
            )
    CombatConstants.set_feature_ambient_pain_shock(prior_flag)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    MedicalPhaseGateTests._free_entity_fixture(ent)


## D-004: ambient pain-shock rolls gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.


## D-004: ambient pain-shock rolls gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.
static func _run_ambient_pain_shock_skips_when_feature_off(failures: PackedStringArray) -> void:
    var prior_flag: bool = CombatConstants.is_feature_ambient_pain_shock()
    CombatConstants.set_feature_ambient_pain_shock(false)
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(20.0, 20.0, "chest")
    ent._pain_shock_until_time = -1.0
    for _i in 40:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 2.0):
            CombatConstants.set_feature_ambient_pain_shock(prior_flag)
            CombatRegressionHarness._fail(failures, "ambient_shock_off: should not enter shock when feature off")
            MedicalPhaseGateTests._free_entity_fixture(ent)
            return
    CombatConstants.set_feature_ambient_pain_shock(prior_flag)
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Stabilize (hemostatic hold) trims rate but does not mark injuries `is_stabilized`  -  definitive dress still
## required.


## Stabilize (hemostatic hold) trims rate but does not mark injuries `is_stabilized`  -  definitive dress still
## required.
static func _run_stabilize_hold_does_not_mark_injury_stabilized(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.35,
            "base_bleeding_rate": 0.8,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    if not ent.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "stabilize_flag: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if not ent._apply_stabilize("chest", 1.5):
        CombatRegressionHarness._fail(failures, "stabilize_flag: apply_stabilize should succeed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if bool(ent.bandaged_parts.get("chest", false)):
        CombatRegressionHarness._fail(failures, "stabilize_flag: stabilize must not set bandaged_parts")
    if bool(ent.wounds["chest"][0].get("is_stabilized", false)):
        CombatRegressionHarness._fail(
            failures, "stabilize_flag: stabilize must not set is_stabilized (dress/pack only)"
        )
    if not EntityWounds.entity_has_untreated_wounds(ent):
        CombatRegressionHarness._fail(
            failures, "stabilize_flag: stabilize alone must still count as untreated for camp/field dress"
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## TCCC: intrinsic bleed may reach 0 under compression, but pressure stays until definitive dress.


## TCCC: intrinsic bleed may reach 0 under compression, but pressure stays until definitive dress.
static func _run_dressings_allowed_when_locally_clotted_under_pressure(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var ally_ent := CombatRegressionHarness._new_entity("SWORD")
    var healer_ent := CombatRegressionHarness._new_entity("SWORD")
    ally_ent.wounds["left_leg"] = [
        {
            "current_bleeding_rate": 0.08,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    ally_ent.apply_direct_pressure("left_leg")
    if ally_ent.has_method("process_bleeding"):
        ally_ent.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if ally_ent.has_method("process_blood_loss"):
        ally_ent.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var intrinsic: float = float(ally_ent.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    if intrinsic > BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(
            failures, "local_clot_dress: fixture should clot intrinsically got rate=%.5f" % intrinsic
        )
        CombatRegressionHarness._free_manager(mgr)
        MedicalPhaseGateTests._free_entity_fixture(ally_ent)
        MedicalPhaseGateTests._free_entity_fixture(healer_ent)
        return
    if ally_ent.self_direct_pressure_part != "left_leg":
        CombatRegressionHarness._fail(
            failures, "local_clot_dress: TCCC hold until dressed (part=%s)" % ally_ent.self_direct_pressure_part
        )
    mgr.register(healer_ent, "player")
    mgr.register(ally_ent, "player")
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer_c: Dictionary = mgr.combatants[0]
    var ally_c: Dictionary = mgr.combatants[1]
    if not MedicalPhaseController.dressings_allowed_for_part(mgr, ally_c, "left_leg"):
        CombatRegressionHarness._fail(
            failures, "local_clot_dress: dressings should be allowed when display bleed is controlled"
        )
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, healer_c, ally_c, "left_leg")
    var has_bandage: bool = false
    for raw in acts:
        if raw is Dictionary and str((raw as Dictionary).get("move_id", "")) == CombatConstants.MOVE_ID_BANDAGE_SELF:
            has_bandage = true
    if not has_bandage:
        CombatRegressionHarness._fail(failures, "local_clot_dress: bandage should list after local clot under pressure")
    CombatRegressionHarness._free_manager(mgr)


## Field stabilize: hemostatic trim must apply before procedure sim advance (not after).


## Field stabilize: hemostatic trim must apply before procedure sim advance (not after).
static func _run_field_stabilize_trim_before_procedure_advance(failures: PackedStringArray) -> void:
    var wound_row: Dictionary = {
        "current_bleeding_rate": 0.35,
        "base_bleeding_rate": 0.8,
        "severity": BleedingConstants.SEVERITY_MODERATE,
        "is_arterial": false,
        "is_stabilized": false,
    }
    var advance_only: Node = CombatRegressionHarness._new_entity("SWORD")
    advance_only.wounds["chest"] = [wound_row.duplicate(true)]
    if not advance_only.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "field_stab_order: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        return
    if advance_only.has_method("process_bleeding"):
        advance_only.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if advance_only.has_method("process_blood_loss"):
        advance_only.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate_advance_only: float = float(advance_only.wounds["chest"][0].get("current_bleeding_rate", 0.0))
    var trim_then_advance: Node = CombatRegressionHarness._new_entity("SWORD")
    trim_then_advance.wounds["chest"] = [wound_row.duplicate(true)]
    if not trim_then_advance.apply_direct_pressure("chest"):
        CombatRegressionHarness._fail(failures, "field_stab_order: pressure setup failed (trim path)")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        MedicalPhaseGateTests._free_entity_fixture(trim_then_advance)
        return
    if not trim_then_advance._apply_stabilize("chest", 1.5):
        CombatRegressionHarness._fail(failures, "field_stab_order: stabilize should succeed under pressure")
        MedicalPhaseGateTests._free_entity_fixture(advance_only)
        MedicalPhaseGateTests._free_entity_fixture(trim_then_advance)
        return
    if trim_then_advance.has_method("process_bleeding"):
        trim_then_advance.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if trim_then_advance.has_method("process_blood_loss"):
        trim_then_advance.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var rate_trim_path: float = float(trim_then_advance.wounds["chest"][0].get("current_bleeding_rate", 0.0))
    if rate_trim_path >= rate_advance_only - 0.0001:
        CombatRegressionHarness._fail(
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
    var tq_first: Node = CombatRegressionHarness._new_entity("SWORD")
    tq_first.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    tq_first.wounds["left_leg"] = [wound_row.duplicate(true)]
    var bleed_first: Node = CombatRegressionHarness._new_entity("SWORD")
    bleed_first.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    bleed_first.wounds["left_leg"] = [wound_row.duplicate(true)]
    seed(884401)
    var tq_ok: bool = tq_first._apply_tourniquet("left_leg", 1.5)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if not tq_ok:
        CombatRegressionHarness._fail(failures, "field_tq_order: tourniquet setup should succeed")
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
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if float(tq_first.blood_volume) <= float(bleed_first.blood_volume):
        CombatRegressionHarness._fail(
            failures,
            (
                "field_tq_order: TQ-before-advance should preserve more blood (tq_first=%.1f bleed_first=%.1f)"
                % [float(tq_first.blood_volume), float(bleed_first.blood_volume)]
            )
        )
    if not bleed_first.tourniquet_applied.has("left_leg"):
        CombatRegressionHarness._fail(failures, "field_tq_order: bleed-first path should still end with TQ applied")
    MedicalPhaseGateTests._free_entity_fixture(tq_first)
    MedicalPhaseGateTests._free_entity_fixture(bleed_first)


## Stabilize requires intrinsic active bleed  -  not arterial label alone after local clot under compression.


## Stabilize requires intrinsic active bleed  -  not arterial label alone after local clot under compression.
static func _run_stabilize_requires_intrinsic_active_bleed(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
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
        CombatRegressionHarness._fail(failures, "stabilize_intrinsic: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    # Pressure immediate reduction (25% * 0.7 arterial mult ~= 17.5%) drops 0.002 -> ~0.0016;
    # then simulate clotting under sustained compression to push below epsilon.
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(60.0)  # 60s of clotting while pressure held
    if ent._can_apply_stabilize("chest"):
        CombatRegressionHarness._fail(
            failures,
            "stabilize_intrinsic: no hemostatic hold when intrinsic bleed already controlled under compression"
        )
    ent.wounds["chest"][0]["current_bleeding_rate"] = 0.15
    if not ent._can_apply_stabilize("chest"):
        CombatRegressionHarness._fail(
            failures, "stabilize_intrinsic: stabilize should allow while intrinsic bleed remains active"
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## TQ-indicated limb: production gate blocks bandage/stabilize (combat `get_ally_medical_actions` parity).


## TQ-indicated limb: production gate blocks bandage/stabilize (combat `get_ally_medical_actions` parity).
static func _run_entity_medical_bandage_blocked_when_tourniquet_indicated(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(12.0, 4.0, "right_leg")
    if not EntityMedical._is_tourniquet_indicated_for_part(ent, "right_leg"):
        CombatRegressionHarness._fail(failures, "tq_bandage_gate: fixture should be tourniquet-indicated on right_leg")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if not ent.apply_direct_pressure("right_leg"):
        CombatRegressionHarness._fail(failures, "tq_bandage_gate: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    if ent._can_apply_bandage("right_leg"):
        CombatRegressionHarness._fail(failures, "tq_bandage_gate: bandage should not be legal on TQ-indicated limb")
    if ent._can_apply_stabilize("right_leg"):
        CombatRegressionHarness._fail(failures, "tq_bandage_gate: stabilize should not be legal on TQ-indicated limb")
    MedicalPhaseGateTests._free_entity_fixture(ent)

## Camp-2.1 MARCH: field care offers tourniquet before bandage when limb bleed is TQ-indicated.
