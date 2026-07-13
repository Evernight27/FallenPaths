class_name MedicalCoordinationBattleTests
extends CombatRegressionHarnessCore
## Tier 6.3 medical phase + treatment tests split from CombatRegressionHarness (compile size).

const BattleScene := preload("res://ui/BattleScene.gd")


static func _run_field_care_tourniquet_before_bandage_parity(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(12.0, 4.0, "left_leg")
    if not ent.apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "field_tq_first: pressure setup failed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var member: Dictionary = {"name": "FieldTQ", "node_ref": ent}
    var world: Node2D = Node2D.new()
    if MapFieldCare.can_offer_field_bandage(world, member):
        CombatRegressionHarness._fail(failures, "field_tq_first: bandage should not be offered on TQ-indicated limb")
    if not MapFieldCare.can_offer_field_tourniquet(world, member):
        CombatRegressionHarness._fail(
            failures, "field_tq_first: tourniquet should be offered after compression on severe limb"
        )
    var next_hint: String = MapFieldCare.format_next_field_care_action(world, member)
    if not next_hint.to_lower().contains("tourniquet"):
        CombatRegressionHarness._fail(
            failures, "field_tq_first: next hint should prefer tourniquet got '%s'" % next_hint
        )
    world.free()
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Arterial hemorrhage under compression alone: meaningful blood loss over one field-care procedure.


## Arterial hemorrhage under compression alone: meaningful blood loss over one field-care procedure.
static func _run_field_care_arterial_blood_loss_meaningful(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.blood_volume = BleedingConstants.MAX_BLOOD_VOLUME
    # Severe arterial chest wound  -  high initial rate that stays meaningful even with clotting under pressure.
    ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 3.0,
            "base_bleeding_rate": 4.8,
            "severity": BleedingConstants.SEVERITY_SEVERE,
            "is_arterial": true,
            "is_stabilized": false,
        },
    ]
    ent.apply_direct_pressure("chest")
    if ent.has_method("process_bleeding"):
        ent.process_bleeding(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    if ent.has_method("process_blood_loss"):
        ent.process_blood_loss(MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS)
    var loss_pct: float = BleedingConstants.MAX_BLOOD_VOLUME - float(ent.blood_volume)
    ## Direct pressure promotes hemostasis (CLOTTING_RATE_UNDER_DIRECT_PRESSURE = 0.032/s);
    ## even an arterial wound under sustained pressure loses meaningful blood volume in one
    ## procedure  -  ~0.3% over one procedure tick with arterial flow retained at 50%.
    if loss_pct < 0.1:
        CombatRegressionHarness._fail(
            failures,
            "field_care_arterial_loss: pressure alone should still lose meaningful blood got loss=%.2f%%" % loss_pct
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Ally/self pressure requires active hemorrhage (display rate above epsilon).


## Ally/self pressure requires active hemorrhage (display rate above epsilon).
static func _run_direct_pressure_requires_active_bleed(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.wounds["left_leg"] = [
        {
            "current_bleeding_rate": 0.0,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_stabilized": false,
        },
    ]
    if ent._can_apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "pressure_active_bleed: self-pressure blocked when rate=0")
    var ally: Node = CombatRegressionHarness._new_entity("SWORD")
    var healer: Node = CombatRegressionHarness._new_entity("SWORD")
    if ent._can_apply_direct_pressure_from_ally("left_leg", healer):
        CombatRegressionHarness._fail(failures, "pressure_active_bleed: ally-pressure blocked when rate=0")
    ent.wounds["left_leg"][0]["current_bleeding_rate"] = 0.12
    if not ent._can_apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "pressure_active_bleed: self-pressure should allow active bleed")
    if not ent._can_apply_direct_pressure_from_ally("left_leg", healer):
        CombatRegressionHarness._fail(failures, "pressure_active_bleed: ally-pressure should allow active bleed")
    MedicalPhaseGateTests._free_entity_fixture(ent)
    MedicalPhaseGateTests._free_entity_fixture(ally)
    MedicalPhaseGateTests._free_entity_fixture(healer)


## Clotting k: sustained direct pressure decays bleed rate faster than open moderate venous wound.


## Clotting k: sustained direct pressure decays bleed rate faster than open moderate venous wound.
static func _run_clotting_pressure_faster_than_open_bleed(failures: PackedStringArray) -> void:
    var wound_row: Dictionary = {
        "current_bleeding_rate": 0.08,
        "base_bleeding_rate": 0.4,
        "severity": BleedingConstants.SEVERITY_MODERATE,
        "is_arterial": false,
        "is_stabilized": false,
    }
    var open: Node = CombatRegressionHarness._new_entity("SWORD")
    open.wounds["left_leg"] = [wound_row.duplicate(true)]
    var pressed: Node = CombatRegressionHarness._new_entity("SWORD")
    pressed.wounds["left_leg"] = [wound_row.duplicate(true)]
    if not pressed.apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "clot_pressure: apply_direct_pressure failed")
        MedicalPhaseGateTests._free_entity_fixture(open)
        MedicalPhaseGateTests._free_entity_fixture(pressed)
        return
    var steps: int = 45
    for _i in range(steps):
        EntityWounds.process_bleeding(open, 1.0)
        EntityWounds.process_bleeding(pressed, 1.0)
    var inj_open: float = float(open.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    var inj_press: float = float(pressed.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    if inj_press >= inj_open - 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "clot_pressure: pressure should decay intrinsic rate faster got open=%.5f press=%.5f"
                % [inj_open, inj_press]
            )
        )
    var moderate_k: float = (
        BleedingConstants.get_clotting_rate(BleedingConstants.SEVERITY_MODERATE)
        * BleedingConstants.get_clotting_multiplier(BleedingConstants.SEVERITY_MODERATE)
    )
    var delta_k: float = BleedingConstants.CLOTTING_RATE_UNDER_DIRECT_PRESSURE - moderate_k
    var want_ratio: float = exp(-delta_k * float(steps))
    if inj_press > inj_open * want_ratio * 1.05 + 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "clot_pressure: intrinsic ratio want <=%.3f got %.3f (open=%.5f press=%.5f)"
                % [want_ratio, inj_press / inj_open if inj_open > 0.0 else 0.0, inj_open, inj_press]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(open)
    MedicalPhaseGateTests._free_entity_fixture(pressed)


## Medical phase integrated loss: clotting during tick replay stays below constant-rate ATLS drain.


## Medical phase integrated loss: clotting during tick replay stays below constant-rate ATLS drain.
static func _run_medical_phase_blood_loss_clotting_below_constant_drain(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(6.0, 2.0, "chest")
    ent.blood_volume = 60.0
    ent._set_combat_blood_loss_mult(1.0)
    ent._set_combat_blood_recovery_per_s(0.0)
    var rate0: float = EntityWounds.get_total_bleeding_rate(ent)
    if rate0 <= 0.0:
        CombatRegressionHarness._fail(failures, "med_clot_drain: need active bleed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    var seconds: float = 12.0
    var constant_want: float = rate0 * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER * seconds
    var steps: int = int(seconds)
    for _i in range(steps):
        ent.process_bleeding(1.0)
        ent.process_blood_loss(1.0)
    var actual_loss: float = 60.0 - float(ent.blood_volume)
    if actual_loss >= constant_want - 0.02:
        CombatRegressionHarness._fail(
            failures,
            (
                "med_clot_drain: clotting should reduce integrated loss got %.3f want < %.3f"
                % [actual_loss, constant_want - 0.02]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


## Hemostasis k: definitive bandage (`CLOTTING_RATE_STABILIZED`) decays slower than sustained compression
## (`CLOTTING_RATE_UNDER_DIRECT_PRESSURE`) at matched intrinsic rate.


## Hemostasis k: definitive bandage (`CLOTTING_RATE_STABILIZED`) decays slower than sustained compression
## (`CLOTTING_RATE_UNDER_DIRECT_PRESSURE`) at matched intrinsic rate.
static func _run_clotting_bandaged_slower_k_than_pressure_held(failures: PackedStringArray) -> void:
    var start_rate: float = 0.08
    var steps: int = 60
    var bandaged: Node = CombatRegressionHarness._new_entity("SWORD")
    bandaged.wounds["left_leg"] = [
        {
            "current_bleeding_rate": start_rate,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": true,
        },
    ]
    bandaged.bandaged_parts["left_leg"] = true
    var pressed: Node = CombatRegressionHarness._new_entity("SWORD")
    pressed.wounds["left_leg"] = [
        {
            "current_bleeding_rate": start_rate,
            "base_bleeding_rate": 0.4,
            "severity": BleedingConstants.SEVERITY_MODERATE,
            "is_arterial": false,
            "is_stabilized": false,
        },
    ]
    if not pressed.apply_direct_pressure("left_leg"):
        CombatRegressionHarness._fail(failures, "clot_bandage_vs_press: apply_direct_pressure failed")
        MedicalPhaseGateTests._free_entity_fixture(bandaged)
        MedicalPhaseGateTests._free_entity_fixture(pressed)
        return
    for _i in range(steps):
        EntityWounds.process_bleeding(bandaged, 1.0)
        EntityWounds.process_bleeding(pressed, 1.0)
    var inj_bandaged: float = float(bandaged.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    var inj_pressed: float = float(pressed.wounds["left_leg"][0].get("current_bleeding_rate", 0.0))
    if inj_bandaged <= inj_pressed + 0.0001:
        CombatRegressionHarness._fail(
            failures,
            (
                "clot_bandage_vs_press: stabilized bandage k should stay above pressure-held intrinsic rate got ban"
                + "d=%.5f press=%.5f" % [inj_bandaged, inj_pressed]
            )
        )
    var want_ratio: float = exp(
        (
            -(BleedingConstants.CLOTTING_RATE_STABILIZED - BleedingConstants.CLOTTING_RATE_UNDER_DIRECT_PRESSURE)
            * float(steps)
        )
    )
    if inj_bandaged < inj_pressed * want_ratio * 0.92:
        CombatRegressionHarness._fail(
            failures,
            (
                "clot_bandage_vs_press: intrinsic ratio want >=%.2f got %.2f"
                % [want_ratio, inj_bandaged / inj_pressed if inj_pressed > 0.0 else 0.0]
            )
        )
    MedicalPhaseGateTests._free_entity_fixture(bandaged)
    MedicalPhaseGateTests._free_entity_fixture(pressed)


static func _run_battle_ui_receiving_care_gauge_primary(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.medical_phase = true
    var c: Dictionary = {
        "state": CombatConstants.STATE_RECEIVING_MEDICAL_ATTENTION,
        "alive": true,
        "gauge": 0.0,
        "stamina": 40.0,
    }
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
    var tip: String = CombatUiHints.medical_busy_row_tooltip_line(c)
    CombatRegressionHarness._free_manager(mgr)
    if not label.contains("Receiving care"):
        CombatRegressionHarness._fail(failures, "battle_ui_receiving: want Receiving care primary got '%s'" % label)
    if not tip.contains("Receiving care"):
        CombatRegressionHarness._fail(failures, "battle_ui_receiving: want tooltip line got '%s'" % tip)


## TCCC: sustained compression raises dressing success (`TREATMENT_PRESSURE_HELD_SUCCESS_MULT`)  -  combat + field care
## share `EntityMedical.apply_bandage`.


## TCCC: sustained compression raises dressing success (`TREATMENT_PRESSURE_HELD_SUCCESS_MULT`)  -  combat + field care
## share `EntityMedical.apply_bandage`.
static func _run_pressure_held_bandage_success_mult_parity(failures: PackedStringArray) -> void:
    if not is_equal_approx(BleedingConstants.TREATMENT_PRESSURE_HELD_SUCCESS_MULT, 1.18):
        CombatRegressionHarness._fail(
            failures,
            "pressure_held_mult: expected 1.18 got %.3f" % BleedingConstants.TREATMENT_PRESSURE_HELD_SUCCESS_MULT
        )
    var eff: float = 0.55
    var extra_with_pressure: int = 0
    for i in range(256):
        seed(88100 + i)
        var no_p: Node = CombatRegressionHarness._new_entity("SWORD")
        no_p.wounds["left_leg"] = [
            {"current_bleeding_rate": 0.5, "severity": "moderate", "is_stabilized": false},
        ]
        var ok_no: bool = no_p._apply_bandage("left_leg", eff)
        seed(88100 + i)
        var with_p: Node = CombatRegressionHarness._new_entity("SWORD")
        with_p.wounds["left_leg"] = [
            {"current_bleeding_rate": 0.5, "severity": "moderate", "is_stabilized": false},
        ]
        if not with_p.apply_direct_pressure("left_leg"):
            CombatRegressionHarness._fail(failures, "pressure_held_mult: self-pressure setup failed")
            MedicalPhaseGateTests._free_entity_fixture(no_p)
            MedicalPhaseGateTests._free_entity_fixture(with_p)
            return
        var ok_yes: bool = with_p._apply_bandage("left_leg", eff)
        if ok_yes and not ok_no:
            extra_with_pressure += 1
        if ok_no and not ok_yes:
            CombatRegressionHarness._fail(failures, "pressure_held_mult: pressure must not reduce success at same roll")
        MedicalPhaseGateTests._free_entity_fixture(no_p)
        MedicalPhaseGateTests._free_entity_fixture(with_p)
    if extra_with_pressure < 8:
        CombatRegressionHarness._fail(
            failures, "pressure_held_mult: want pressure-held bonus wins got %d (eff=%.2f)" % [extra_with_pressure, eff]
        )


## Camp-3.3: medical wind-up primary label shows procedure + remaining seconds.


## Camp-3.3: medical wind-up primary label shows procedure + remaining seconds.
static func _run_battle_ui_medical_wind_up_gauge_primary(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.medical_phase = true
    var c: Dictionary = {
        "state": CombatConstants.STATE_MEDICAL_WIND_UP,
        "alive": true,
        "state_timer": 0.5,
        "state_duration": 3.0,
        "pending_medical":
        {
            "medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
            "target_combatant_id": 1,
        },
        "gauge": 0.0,
        "stamina": 40.0,
    }
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
    var tip: String = CombatUiHints.medical_busy_row_tooltip_line(c)
    CombatRegressionHarness._free_manager(mgr)
    if not label.contains("Bandaging") or not label.contains("2.5s"):
        CombatRegressionHarness._fail(failures, "battle_ui_med_wu: want procedure + timer primary got '%s'" % label)
    if not tip.contains("Medical wind-up"):
        CombatRegressionHarness._fail(failures, "battle_ui_med_wu: want wind-up tooltip got '%s'" % tip)


static func _run_wound_merge_same_subregion(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 3.0, "face", BleedingConstants.SEVERITY_MODERATE
    )
    EntityWounds.add_wound(
        ent, "head", BleedingConstants.INJURY_TYPE_CUT, 3.0, "face", BleedingConstants.SEVERITY_MODERATE
    )
    if ent.wounds.get("head", []).size() != 1:
        CombatRegressionHarness._fail(
            failures,
            "wound_merge: expected 1 injury row for same sub_region got %d" % ent.wounds.get("head", []).size()
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


static func _run_medical_phase_losing_side_stays_fled(failures: PackedStringArray) -> void:
    var mgr: Node = CombatRegressionHarness._harness_start_1v1()
    var enemy_c: Dictionary = mgr.combatants[1]
    enemy_c["combat_absent"] = true
    enemy_c.state = CombatConstants.STATE_FLED
    mgr._end_combat_phase("player", null)
    if not bool(enemy_c.get("combat_absent", false)):
        CombatRegressionHarness._fail(failures, "med_phase_rout: enemy combat_absent should stay set")
    if CombatantEntityAccess.state_str(enemy_c) != CombatConstants.STATE_FLED:
        CombatRegressionHarness._fail(failures, "med_phase_rout: enemy should remain STATE_FLED")
    CombatRegressionHarness._free_manager(mgr)


static func _run_medical_coordination_stack_assist_during_windup(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
    var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
    var patient: Node = CombatRegressionHarness._new_entity("SWORD")
    patient.take_damage_split(12.0, 4.0, "left_arm")
    mgr.register(healer_a, "player")
    mgr.register(healer_b, "player")
    mgr.register(patient, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var ha: Dictionary = mgr.combatants[0]
    var hb: Dictionary = mgr.combatants[1]
    var pt: Dictionary = mgr.combatants[2]
    var hb_id: int = CombatantEntityAccess.id_int(hb)
    var pt_id: int = CombatantEntityAccess.id_int(pt)
    if not patient._apply_direct_pressure_from_ally("left_arm", healer_a):
        CombatRegressionHarness._fail(failures, "med_coord_assist: primary pressure setup failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
    ha.pending_medical = {
        "medical_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET,
        "target_part": "left_arm",
        "target_combatant_id": pt_id,
    }
    if not CombatMedicalCoordination.can_stack_assist_pressure(mgr, hb_id, pt_id, "left_arm"):
        CombatRegressionHarness._fail(failures, "med_coord_assist: B should stack-assist while A holds during wind-up")
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, hb, pt, "left_arm")
    var has_assist_pressure: bool = false
    for raw in acts:
        if raw is Dictionary and CombatConstants.is_direct_pressure_move(str((raw as Dictionary).get("move_id", ""))):
            has_assist_pressure = true
    if not has_assist_pressure:
        CombatRegressionHarness._fail(failures, "med_coord_assist: listing should offer stack-assist pressure")
    var pick_pool: Array = [
        {
            "target_id": pt_id,
            "move_id": CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
            "target_part": "left_arm",
        }
    ]
    var filtered: Array = CombatMedicalCoordination.filter_actions_for_pick(mgr, hb_id, pick_pool)
    if filtered.is_empty():
        CombatRegressionHarness._fail(failures, "med_coord_assist: filtered pick pool should include assist pressure")
    CombatRegressionHarness._free_manager(mgr)


static func _run_medical_coordination_blocks_overlapping_treatment(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
    var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
    var patient: Node = CombatRegressionHarness._new_entity("SWORD")
    patient.take_damage_split(14.0, 5.0, "left_arm")
    mgr.register(healer_a, "player")
    mgr.register(healer_b, "player")
    mgr.register(patient, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var ha: Dictionary = mgr.combatants[0]
    var hb: Dictionary = mgr.combatants[1]
    var pt: Dictionary = mgr.combatants[2]
    var hb_id: int = CombatantEntityAccess.id_int(hb)
    var pt_id: int = CombatantEntityAccess.id_int(pt)
    ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
    ha.state_duration = 8.0
    ha.pending_medical = {
        "medical_id": CombatConstants.MOVE_ID_APPLY_TOURNIQUET,
        "target_part": "left_arm",
        "target_combatant_id": pt_id,
    }
    if CombatMedicalCoordination.medical_action_allowed(
        mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_TOURNIQUET
    ):
        CombatRegressionHarness._fail(failures, "med_coord: second medic must not start tourniquet during ally wind-up")
    if CombatMedicalCoordination.medical_action_allowed(
        mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
    ):
        CombatRegressionHarness._fail(failures, "med_coord: second medic must not replace pressure during ally wind-up")
    var acts_overlap: Array = MedicalPhaseController.get_ally_medical_actions(mgr, hb, pt, "left_arm")
    for raw in acts_overlap:
        if raw is not Dictionary:
            continue
        var mid: String = str((raw as Dictionary).get("move_id", ""))
        if CombatConstants.is_tourniquet_move(mid) or CombatConstants.is_direct_pressure_move(mid):
            CombatRegressionHarness._fail(
                failures, "med_coord: listing must omit overlap moves during wind-up got %s" % mid
            )
    if not patient._apply_direct_pressure_from_ally("left_arm", healer_a):
        CombatRegressionHarness._fail(failures, "med_coord: setup ally pressure failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    ha.state = CombatConstants.STATE_WAITING
    ha.pending_medical = {}
    if not CombatMedicalCoordination.can_stack_assist_pressure(mgr, hb_id, pt_id, "left_arm"):
        CombatRegressionHarness._fail(failures, "med_coord: B should stack-assist when A holds compression")
    if not CombatMedicalCoordination.medical_action_allowed(
        mgr, hb_id, pt_id, "left_arm", CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
    ):
        CombatRegressionHarness._fail(failures, "med_coord: stack-assist pressure should be allowed")
    var acts_held: Array = MedicalPhaseController.get_ally_medical_actions(mgr, hb, pt, "left_arm")
    var assist_listed: bool = false
    for raw2 in acts_held:
        if raw2 is Dictionary and CombatConstants.is_direct_pressure_move(str((raw2 as Dictionary).get("move_id", ""))):
            assist_listed = true
    if not assist_listed:
        CombatRegressionHarness._fail(failures, "med_coord: listing should offer stack-assist direct_pressure")
    CombatRegressionHarness._free_manager(mgr)


## Bandage/pack blocked on a part while another medic's wind-up targets the same part.


## Bandage/pack blocked on a part while another medic's wind-up targets the same part.
static func _run_medical_coordination_blocks_bandage_during_ally_windup(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    var healer_a: Node = CombatRegressionHarness._new_entity("SWORD")
    var healer_b: Node = CombatRegressionHarness._new_entity("SWORD")
    var patient: Node = CombatRegressionHarness._new_entity("SWORD")
    patient.take_damage_split(10.0, 3.0, "chest")
    mgr.register(healer_a, "player")
    mgr.register(healer_b, "player")
    mgr.register(patient, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var ha: Dictionary = mgr.combatants[0]
    var hb: Dictionary = mgr.combatants[1]
    var pt: Dictionary = mgr.combatants[2]
    var hb_id: int = CombatantEntityAccess.id_int(hb)
    var pt_id: int = CombatantEntityAccess.id_int(pt)
    if not patient._apply_direct_pressure_from_ally("chest", healer_a):
        CombatRegressionHarness._fail(failures, "med_coord_bandage: setup ally pressure failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    ha.state = CombatConstants.STATE_MEDICAL_WIND_UP
    ha.state_duration = 6.0
    ha.pending_medical = {
        "medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
        "target_part": "chest",
        "target_combatant_id": pt_id,
    }
    if CombatMedicalCoordination.medical_action_allowed(
        mgr, hb_id, pt_id, "chest", CombatConstants.MOVE_ID_BANDAGE_SELF
    ):
        CombatRegressionHarness._fail(failures, "med_coord_bandage: second medic must not bandage during ally wind-up")
    if CombatMedicalCoordination.medical_action_allowed(mgr, hb_id, pt_id, "chest", CombatConstants.MOVE_ID_PACK_WOUND):
        CombatRegressionHarness._fail(
            failures, "med_coord_bandage: second medic must not pack during ally bandage wind-up"
        )
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, hb, pt, "chest")
    for raw in acts:
        if raw is not Dictionary:
            continue
        var mid: String = str((raw as Dictionary).get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_BANDAGE_SELF or mid == CombatConstants.MOVE_ID_PACK_WOUND:
            CombatRegressionHarness._fail(
                failures, "med_coord_bandage: listing must omit dress moves during ally wind-up got %s" % mid
            )
    CombatRegressionHarness._free_manager(mgr)


static func _run_medical_windup_prepare_preserves_ally_head_pressure(failures: PackedStringArray) -> void:
    var patient: Node = CombatRegressionHarness._new_entity("SWORD")
    var ally: Node = CombatRegressionHarness._new_entity("SWORD")
    patient.take_damage_split(8.0, 3.0, "head")
    if not patient.wounds.has("head"):
        CombatRegressionHarness._fail(failures, "windup_prepare: need head wound")
        CombatRegressionHarness._free_harness_node(patient)
        CombatRegressionHarness._free_harness_node(ally)
        return
    if not patient._apply_direct_pressure_from_ally("head", ally):
        CombatRegressionHarness._fail(failures, "windup_prepare: ally pressure failed")
        CombatRegressionHarness._free_harness_node(patient)
        CombatRegressionHarness._free_harness_node(ally)
        return
    var held: float = EntityWounds.get_bleeding_rate_for_part(patient, "head")
    if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
        CombatRegressionHarness._fail(failures, "windup_prepare: ally hold not registered")
        CombatRegressionHarness._free_harness_node(patient)
        CombatRegressionHarness._free_harness_node(ally)
        return
    EntityMedical._prepare_for_medical_windup(patient, patient, "head")
    if patient.direct_pressure_part != "head" or patient.direct_pressure_held_by != ally:
        CombatRegressionHarness._fail(failures, "windup_prepare: ally hold cleared on treatment part")
        CombatRegressionHarness._free_harness_node(patient)
        CombatRegressionHarness._free_harness_node(ally)
        return
    var after: float = EntityWounds.get_bleeding_rate_for_part(patient, "head")
    if after > held + BleedingConstants.BLEEDING_RATE_EPSILON:
        CombatRegressionHarness._fail(
            failures, "windup_prepare: rebound during prepare held=%.3f after=%.3f" % [held, after]
        )
    CombatRegressionHarness._free_harness_node(patient)
    CombatRegressionHarness._free_harness_node(ally)


## MS-MID: mid-fight listing for ally immediate peril + L1 coordinated pick (not medical phase).


## MS-MID: mid-fight listing for ally immediate peril + L1 coordinated pick (not medical phase).
static func _run_ms_mid_infight_med_depth_suite(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_MS_MID_INFIGHT_MED:
        CombatRegressionHarness._fail(failures, "ms_mid_depth: FEATURE_MS_MID_INFIGHT_MED should be enabled")
        return
    if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
        CombatRegressionHarness._fail(failures, "ms_mid_depth: production getter should be on")
        return
    MedicalCoordinationBattleTests._run_ms_mid_infight_ally_medical_listing(failures)


static func _run_ms_mid_infight_ally_medical_listing(failures: PackedStringArray) -> void:
    var FootworkTail := preload("res://harness/attention_footwork/AttentionFootworkTail.gd")
    var MentalStack := preload("res://combat/MentalStackDecider.gd")
    if not CombatConstants.is_feature_ms_mid_infight_med_enabled():
        CombatRegressionHarness._fail(failures, "ms_mid_listing: FEATURE_MS_MID_INFIGHT_MED must be on in production")
        return
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = CombatantEntityAccess.id_int(medic)
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    medic["gauge"] = 100.0
    medic.state = CombatConstants.STATE_WAITING
    medic.rank = 1
    medic["file"] = 0
    ally["file"] = 0
    var perf_fid_med: String = CombatantEntityAccess.formation_id_str(medic)
    if not perf_fid_med.is_empty():
        var fdict: Dictionary = mgr.formations.get(perf_fid_med, {})
        if not fdict.is_empty():
            fdict.engagement_posture = CombatConstants.ENGAGEMENT_POSTURE_LINE
    var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    FootworkTail._harness_immediate_peril_bleeding_chest(ally_ent, 38.0)
    if mgr.medical_phase:
        CombatRegressionHarness._fail(failures, "ms_mid_listing: fixture must stay in combat phase")
        CombatRegressionHarness._free_manager_restore_global_rng(mgr)
        return
    var built: Array = AvailableActionsBuilder.build(mgr, medic_id)
    var has_ally_pressure: bool = false
    for raw in built:
        if raw is not Dictionary:
            continue
        var act: Dictionary = raw as Dictionary
        if (
            str(act.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
            and int(act.get("target_id", -1)) == ally_id
            and str(act.get("target_part", "")) == "chest"
        ):
            has_ally_pressure = true
    if not has_ally_pressure:
        CombatRegressionHarness._fail(
            failures, "ms_mid_listing: want ally chest pressure in mid-fight build got %d actions" % built.size()
        )
    var saved: bool = CombatConstants.is_feature_ms_mid_infight_med_enabled()
    CombatConstants.set_feature_ms_mid_infight_med_load(false)
    var built_off: Array = AvailableActionsBuilder.build(mgr, medic_id)
    CombatConstants.set_feature_ms_mid_infight_med_load(saved)
    for raw in built_off:
        if raw is not Dictionary:
            continue
        var act_off: Dictionary = raw as Dictionary
        if (
            CombatConstants.is_medical_move(str(act_off.get("move_id", "")))
            and int(act_off.get("target_id", -1)) == ally_id
        ):
            CombatRegressionHarness._fail(failures, "ms_mid_listing: flag off should not list ally medical mid-fight")
            break
    var picked: Dictionary = MentalStack.try_pick(built, medic_id, mgr)
    if picked.is_empty():
        CombatRegressionHarness._fail(failures, "ms_mid_listing: mental stack expected L1 medical pick")
    elif (
        str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        != CombatConstants.MENTAL_STACK_LAYER_MEDICAL
    ):
        CombatRegressionHarness._fail(
            failures,
            (
                "ms_mid_listing: want layer medical got %s"
                % str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
            )
        )
    elif str(picked.get("move_id", "")) != CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
        CombatRegressionHarness._fail(
            failures, "ms_mid_listing: want apply_direct_pressure got %s" % str(picked.get("move_id", ""))
        )
    var filtered: Array = CombatMedicalCoordination.filter_actions_for_pick(mgr, medic_id, built)
    var filtered_has_pressure: bool = false
    for raw in filtered:
        if raw is not Dictionary:
            continue
        var act_f: Dictionary = raw as Dictionary
        if (
            str(act_f.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE
            and int(act_f.get("target_id", -1)) == ally_id
        ):
            filtered_has_pressure = true
    if not filtered_has_pressure:
        CombatRegressionHarness._fail(
            failures, "ms_mid_listing: mid-fight pick filter dropped coordinated ally pressure"
        )
    CombatRegressionHarness._free_manager_restore_global_rng(mgr)


static func _run_ally_medical_tourniquet_path_pressure_first(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(12.0, 4.0, "right_leg")
    var mgr: Node = CombatManager.new()
    var healer: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(healer, "player")
    mgr.register(ent, "player")
    var healer_c: Dictionary = mgr.combatants[0]
    var ally_c: Dictionary = mgr.combatants[1]
    var acts: Array = MedicalPhaseController.get_ally_medical_actions(mgr, healer_c, ally_c, "right_leg")
    CombatRegressionHarness._free_manager(mgr)
    if acts.is_empty():
        CombatRegressionHarness._fail(failures, "tq_path: expected actions on bleeding leg")
        return
    var mids: Array = []
    for raw in acts:
        if raw is Dictionary:
            mids.append(str((raw as Dictionary).get("move_id", "")))
    if CombatConstants.MOVE_ID_APPLY_TOURNIQUET not in mids:
        CombatRegressionHarness._fail(failures, "tq_path: expected tourniquet on severe leg bleed")
    if CombatConstants.MOVE_ID_BANDAGE_SELF in mids or CombatConstants.MOVE_ID_PACK_WOUND in mids:
        CombatRegressionHarness._fail(failures, "tq_path: should not list bandage/pack before tourniquet path")


## Winner locked after `enemies_eliminated`: party bleed-out during triage must not flip to enemy `combat_ended`.


## Winner locked after `enemies_eliminated`: party bleed-out during triage must not flip to enemy `combat_ended`.
static func _run_medical_phase_winner_locked_on_party_bleed_out(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr._end_combat_phase("player", CombatantEntityAccess.scene_node(mgr.combatants[2]))
    if not mgr.medical_phase or mgr.medical_phase_winner != "player":
        CombatRegressionHarness._fail(
            failures, "medical_phase_winner_lock: expected player medical phase after victory"
        )
        CombatRegressionHarness._free_manager(mgr)
        return
    if not MedicalPhaseController.should_apply_phase_end(mgr, "enemy"):
        pass
    else:
        CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: enemy victor should be blocked")
    var ended_box: Array = [0]
    mgr.combat_ended.connect(func(_w: String, _d: Node) -> void: ended_box[0] = int(ended_box[0]) + 1)
    var p0: Dictionary = mgr.combatants[0]
    var p_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, p0)
    if p_ent == null:
        CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: missing player entity")
        CombatRegressionHarness._free_manager(mgr)
        return
    p_ent.blood_volume = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
    p0.alive = true
    mgr.set_process(true)
    CombatProcessTick.tick(mgr, 0.05)
    if int(ended_box[0]) != 0:
        CombatRegressionHarness._fail(
            failures,
            "medical_phase_winner_lock: combat_ended must not fire on party bleed-out (count=%d)" % int(ended_box[0])
        )
    if not mgr.medical_phase or mgr.medical_phase_winner != "player":
        CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: medical phase should persist")
    if not CombatantEntityAccess.is_dead(p0):
        CombatRegressionHarness._fail(failures, "medical_phase_winner_lock: expected player marked dead on entity")
    CombatRegressionHarness._free_manager(mgr)


## Locked phase-end must not abort the rest of the tick (e.g. ally medical wind-up still advances).


## Locked phase-end must not abort the rest of the tick (e.g. ally medical wind-up still advances).
static func _run_medical_phase_tick_continues_after_locked_bleed_out(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var medic_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(medic_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr._end_combat_phase("player", CombatantEntityAccess.scene_node(mgr.combatants[2]))
    var casualty: Dictionary = mgr.combatants[0]
    var medic: Dictionary = mgr.combatants[1]
    var cas_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, casualty)
    if cas_ent == null:
        CombatRegressionHarness._fail(failures, "medical_phase_tick_continue: missing casualty entity")
        CombatRegressionHarness._free_manager(mgr)
        return
    cas_ent.blood_volume = BleedingConstants.BLOOD_LOSS_DEATH_THRESHOLD - 1.0
    casualty.alive = true
    medic.state = CombatConstants.STATE_MEDICAL_WIND_UP
    medic.state_timer = 0.0
    medic.state_duration = 2.0
    medic.pending_medical = {
        "medical_id": CombatConstants.MOVE_ID_BANDAGE_SELF,
        "target_part": "chest",
        "target_combatant_id": CombatantEntityAccess.id_int(medic),
    }
    mgr.set_process(true)
    CombatProcessTick.tick(mgr, 0.25)
    if CombatantEntityAccess.state_str(medic) != CombatConstants.STATE_MEDICAL_WIND_UP:
        CombatRegressionHarness._fail(
            failures,
            (
                "medical_phase_tick_continue: medic wind-up should advance (state=%s timer=%.2f)"
                % [CombatantEntityAccess.state_str(medic), float(medic.get("state_timer", 0.0))]
            )
        )
    elif float(medic.get("state_timer", 0.0)) < 0.01:
        CombatRegressionHarness._fail(
            failures, "medical_phase_tick_continue: medic state_timer should advance after tick"
        )
    CombatRegressionHarness._free_manager(mgr)


static func _run_medical_phase_full_blood_loss_rate(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    ent.take_damage_split(6.0, 2.0, "chest")
    ent.blood_volume = 60.0
    var rate: float = EntityWounds.get_total_bleeding_rate(ent)
    if rate <= 0.0:
        CombatRegressionHarness._fail(failures, "med_phase_bleed: need active bleed")
        MedicalPhaseGateTests._free_entity_fixture(ent)
        return
    ent._set_combat_blood_loss_mult(1.0)
    ent._set_combat_blood_recovery_per_s(0.0)
    ent.process_blood_loss(1.0)
    var loss: float = 60.0 - ent.blood_volume
    var want: float = rate * BleedingConstants.BLOOD_LOSS_RATE_MULTIPLIER * 1.0
    if absf(loss - want) > 0.05:
        CombatRegressionHarness._fail(
            failures, "med_phase_bleed: expect full ATLS drain rate got loss=%.4f want~=%.4f" % [loss, want]
        )
    # No passive recovery without fluids (post-victory medical phase uses same physiology).
    ent.blood_volume = 55.0
    ent._set_combat_blood_recovery_per_s(0.06)
    ent.process_blood_loss(1.0)
    if ent.blood_volume > 55.01:
        CombatRegressionHarness._fail(
            failures, "med_phase_bleed: passive recovery should not run without explicit treatment"
        )
    MedicalPhaseGateTests._free_entity_fixture(ent)


static func _run_pack_wound_apply_packing_marks_packed_parts(failures: PackedStringArray) -> void:
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ent)
    MedicalPhaseGateTests._harness_hold_pressure_if_bleeding(ent, "chest")
    seed(88202)
    var ok: bool = ent._apply_packing("chest", 1.5)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if not ok:
        CombatRegressionHarness._fail(
            failures, "pack_wound_apply: apply_packing should succeed with high effectiveness"
        )
    if not bool(ent.packed_parts.get("chest", false)):
        CombatRegressionHarness._fail(failures, "pack_wound_apply: packed_parts[chest] should be set")
    MedicalPhaseGateTests._free_entity_fixture(ent)


static func _run_pack_wound_windup_complete_packed_outcome(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    var healer: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    var ally_node: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ally_node)
    if ally_node.is_dead():
        CombatRegressionHarness._fail(failures, "pack_wound_windup: harness wound must not kill ally")
        CombatRegressionHarness._free_manager(mgr)
        return
    healer.state = CombatConstants.STATE_MEDICAL_WIND_UP
    healer.state_duration = 2.0
    healer.pending_medical = {
        "medical_id": CombatConstants.MOVE_ID_PACK_WOUND,
        "target_part": "chest",
        "target_combatant_id": ally_id,
    }
    seed(88203)
    var outcome_box: Array = [""]
    mgr.action_resolved.connect(
        func(_a: int, _t: int, r: Dictionary) -> void: outcome_box[0] = str(r.get("outcome", ""))
    )
    MedicalWindUpHandler.complete(mgr, healer, healer.pending_medical)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    var packed_chest: bool = bool(ally_node.packed_parts.get("chest", false))
    CombatRegressionHarness._free_manager(mgr)
    if str(outcome_box[0]) != "packed" and str(outcome_box[0]) != "packing_failed":
        CombatRegressionHarness._fail(
            failures, "pack_wound_windup: want packed or packing_failed got '%s'" % str(outcome_box[0])
        )
    if str(outcome_box[0]) == "packed" and not packed_chest:
        CombatRegressionHarness._fail(failures, "pack_wound_windup: packed outcome should set packed_parts")


static func _run_instant_complete_finishes_in_progress_bandage(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
    var ally_ent: Node = CombatRegressionHarness._new_entity("SWORD")
    mgr.register(ally_ent, "player")
    mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.medical_phase = true
    mgr.medical_phase_winner = "player"
    MedicalPhaseGateTests._harness_wound_chest_for_packing(ally_ent)
    var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    var ally: Dictionary = mgr.combatants[1]
    var ally_id: int = CombatantEntityAccess.id_int(ally)
    if not CombatantEntityAccess.entity_apply_direct_pressure_from_ally(mgr, ally, mgr.combatants[0], "chest"):
        CombatRegressionHarness._fail(failures, "instant_complete_bandage: ally pressure setup failed")
        CombatRegressionHarness._free_manager(mgr)
        return
    MedicalActionStarter.start(mgr, healer_id, ally_id, CombatConstants.MOVE_ID_BANDAGE_SELF, "chest")
    if CombatantEntityAccess.state_str(mgr.combatants[0]) != CombatConstants.STATE_MEDICAL_WIND_UP:
        CombatRegressionHarness._fail(failures, "instant_complete_bandage: expected medical wind-up")
        CombatRegressionHarness._free_manager(mgr)
        return
    var clock_before: float = float(mgr.combat_clock)
    seed(88204)
    MedicalPhaseController.instant_complete_on_early_exit(mgr)
    seed(CombatRegressionHarness._HARNESS_RESTORE_GLOBAL_SEED)
    if float(mgr.combat_clock) <= clock_before:
        CombatRegressionHarness._fail(failures, "instant_complete_bandage: fast-forward should advance combat_clock")
    if CombatantEntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_MEDICAL_WIND_UP:
        CombatRegressionHarness._fail(
            failures, "instant_complete_bandage: wind-up should finish via simulated time, not stay active"
        )
    if not bool(ally_ent.bandaged_parts.get("chest", false)):
        CombatRegressionHarness._fail(
            failures, "instant_complete_bandage: ally chest should be bandaged after instant complete"
        )
    CombatRegressionHarness._free_manager(mgr)

## Idle fast-forward tick must advance clock when winners wait at full gauge with open wounds.
