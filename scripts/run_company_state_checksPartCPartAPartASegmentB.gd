class_name CompanyStateChecksHarnessPartCPartAPartASegmentB
extends CompanyStateChecksHarnessPartCPartAPartASegmentA

## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json`
## untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const HARNESS_NAME := "CompanyStateChecks"
static var _test_count: int = 0


static func _run_camp_2_bridge_spot_checkssegmentb(failures: PackedStringArray) -> void:
    var pack_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(pack_world, 2)
    var pm_pack: Node = pack_world.get_meta("party_manager")
    var field_pack_ent: Node = _add_living_entity_member(pm_pack, "FieldPack")
    field_pack_ent.linen_strips_remaining = 4
    field_pack_ent.wounds["chest"] = [
        {
            "current_bleeding_rate": 0.5,
            "severity": "severe",
            "sub_region": "thoracic",
        },
    ]
    field_pack_ent.apply_direct_pressure("chest")
    var pack_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "FieldPack", "node_ref": field_pack_ent}
    )
    if not MapFieldCare.can_offer_field_pack(pack_world, pack_member):
        _fail(failures, "Camp-2.1: field pack should be offered on pressured junctional wound")
    else:
        _pass()
    var packed_ok: bool = false
    for attempt in range(32):
        CompanyState.set_medical_supplies(pack_world, 2)
        field_pack_ent.packed_parts.erase("chest")
        if not EntityMedical.has_direct_pressure_on_part(field_pack_ent, "chest"):
            field_pack_ent.apply_direct_pressure("chest")
        seed(99200 + attempt)
        if MapFieldCare.try_field_pack(pack_world, pack_member):
            packed_ok = true
            break
    if not packed_ok:
        _fail(failures, "Camp-2.1: field pack should eventually pack junctional chest")
    else:
        _pass()
    if CompanyState.camp_heal_ready(pack_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: field pack should count as dressed for camp rest")
    _release_harness_world(pack_world)

    var tq_world: Node2D = _make_world(1, 0, true)
    var pm_tq: Node = tq_world.get_meta("party_manager")
    var tq_ent: Node = _add_living_entity_member(pm_tq, "FieldTQ")
    tq_ent.wounds["left_leg"] = [
        {"current_bleeding_rate": 1.4, "severity": "severe", "is_arterial": true},
    ]
    var tq_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "FieldTQ", "node_ref": tq_ent})
    if not MapFieldCare.can_offer_field_tourniquet(tq_world, tq_member):
        _fail(failures, "Camp-2.1: field tourniquet should be offered on severe limb bleed")
    else:
        _pass()
    if not MapFieldCare.try_field_tourniquet(tq_world, tq_member):
        _fail(failures, "Camp-2.1: field tourniquet should succeed on indicated limb")
    else:
        _pass()
    if not CompanyState.camp_heal_ready(tq_world, true):
        _fail(failures, "Camp-2.1: field tourniquet should dress part for camp rest")
    else:
        _pass()
    _release_harness_world(tq_world)

    var label_world: Node2D = _make_world(1)
    var pm_lbl: Node = label_world.get_meta("party_manager")
    var lbl_ent: Node = _add_living_entity_member(pm_lbl, "LabelTest")
    lbl_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.5, "severity": "moderate"},
    ]
    var lbl_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "LabelTest", "node_ref": lbl_ent})
    var pressure_lbl: String = MapFieldCare.format_field_pressure_button_label(label_world, lbl_member)
    if not pressure_lbl.contains("Chest"):
        _fail(failures, "Camp-2.1: field pressure button should name target part got '%s'" % pressure_lbl)
    else:
        _pass()
    var budget: Dictionary = CompanyState.triage_med_budget(label_world)
    if int(budget.get("parts_need", 0)) != 1 or int(budget.get("total_worst_case", 0)) != 2:
        _fail(failures, "Camp-2.1: triage_med_budget want parts=1 total=2 got %s" % str(budget))
    else:
        _pass()
    if int(budget.get("med_shortfall", -1)) != 0:
        _fail(failures, "Camp-2.1: med_shortfall should be 0 when supplies sufficient")
    else:
        _pass()
    CompanyState.set_medical_supplies(label_world, 0)
    var budget_zero: Dictionary = CompanyState.triage_med_budget(label_world)
    if int(budget_zero.get("field_bandage_med_est", -1)) != 0:
        _fail(failures, "Camp-2.1 E3: triage budget at 0 med should not charge for bandages")
    else:
        _pass()
    var hud_suffix: String = CompanyState.format_hud_triage_suffix(label_world)
    if not hud_suffix.contains("1"):
        _fail(failures, "Camp-2.1: HUD triage suffix should show part count got '%s'" % hud_suffix)
    else:
        _pass()
    var wait_member: Dictionary = lbl_member
    var wait_lbl: String = MapFieldCare.format_field_bandage_waiting_label(wait_member)
    if not wait_lbl.contains("Chest"):
        _fail(failures, "Camp-2.1: bandage waiting label should name part got '%s'" % wait_lbl)
    else:
        _pass()
    var pm_multi: Node = label_world.get_meta("party_manager")
    var multi_ent: Node = _add_living_entity_member(pm_multi, "MultiPart")
    multi_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    multi_ent.wounds["left_leg"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
    var multi_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "MultiPart", "node_ref": multi_ent}
    )
    var multi_hint: String = MapFieldCare.format_member_field_care_hint(multi_member)
    if not multi_hint.contains("2 untreated part"):
        _fail(failures, "Camp-2.1: member field care hint should count parts got '%s'" % multi_hint)
    else:
        _pass()
    var single_hint: String = MapFieldCare.format_member_field_care_hint(lbl_member)
    if not single_hint.contains("One part left"):
        _fail(failures, "Camp-2.1: single-part hint expected got '%s'" % single_hint)
    else:
        _pass()
    var next_action: String = MapFieldCare.format_next_field_care_action(label_world, lbl_member)
    if not next_action.contains("Field pressure"):
        _fail(failures, "Camp-2.1: next field care action should start with pressure got '%s'" % next_action)
    else:
        _pass()
    var party_lbl: String = CompanyState.format_party_button_label(label_world)
    if not party_lbl.contains("to dress"):
        _fail(failures, "Camp-2.1: party button label should show dress count got '%s'" % party_lbl)
    else:
        _pass()
    var btn_world: Node2D = _make_world(0, 0, true)
    btn_world.set_script(CampaignWorldScript)
    var player_char := Node2D.new()
    player_char.name = "Character"
    btn_world.add_child(player_char)
    PartySetup.setup_party(btn_world)
    var pm_btn: Node = btn_world.get_meta("party_manager")
    var btn_ent: Node = _add_living_entity_member(pm_btn, "BtnTint")
    btn_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    CompanyState.refresh_party_button(btn_world)
    var pb: Control = CombatFlow._find_party_button(btn_world)
    if pb == null or not pb is Button:
        _fail(failures, "Camp-2.1: refresh_party_button should find PartyButton on overlay")
    else:
        var party_btn: Button = pb as Button
        if not party_btn.text.contains("to dress"):
            _fail(failures, "Camp-2.1: overlay PartyButton text want dress count got '%s'" % party_btn.text)
        elif not party_btn.has_theme_color_override("font_color"):
            _fail(failures, "Camp-2.1: overlay PartyButton should tint when wounds need dressing")
        elif party_btn.tooltip_text.is_empty():
            _fail(failures, "Camp-2.1: overlay PartyButton tooltip should hint field care")
        else:
            _pass()
    CompanyState.set_medical_supplies(btn_world, 0)
    CompanyState.refresh_party_button(btn_world)
    var pb_zero: Control = CombatFlow._find_party_button(btn_world)
    if pb_zero == null or not pb_zero is Button:
        _fail(failures, "Camp-2.1: PartyButton missing for 0-med tooltip test")
    elif not (pb_zero as Button).tooltip_text.contains("0-med"):
        _fail(
            failures,
            (
                "Camp-2.1: PartyButton tooltip at 0 med should mention 0-med bandages got '%s'"
                % (pb_zero as Button).tooltip_text
            )
        )
    else:
        _pass()
    btn_ent.apply_direct_pressure("chest")
    var btn_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
    var btn_dressed: bool = false
    for attempt in range(24):
        btn_ent.bandaged_parts.erase("chest")
        if btn_ent.self_direct_pressure_part != "chest":
            btn_ent.apply_direct_pressure("chest")
        btn_member = PartyMemberSnapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
        seed(90300 + attempt)
        if MapFieldCare.try_field_bandage(btn_world, btn_member):
            btn_dressed = true
            break
    if not btn_dressed:
        _fail(failures, "Camp-2.1: PartyButton clear test could not dress chest")
    else:
        _pass()
    (
        btn_world
        . set_meta(
            CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {
                "members":
                [
                    {
                        "name": "BtnTint",
                        "snapshot": {"name": "BtnTint", "has_untreated_wounds": true},
                    }
                ],
                "deaths": [],
                "winner": "player",
            }
        )
    )
    CompanyState.set_medical_supplies(btn_world, 0)
    if not CompanyState.should_show_party_camp_rest_button(btn_world):
        _fail(failures, "Camp-2.1: dressed roster with 0 med should show camp rest button")
    else:
        _pass()
    CompanyState.refresh_party_button(btn_world)
    var pb_clear: Button = CombatFlow._find_party_button(btn_world) as Button
    if pb_clear == null:
        _fail(failures, "Camp-2.1: PartyButton missing after dress")
    elif pb_clear.text != "Party" or pb_clear.has_theme_color_override("font_color"):
        _fail(failures, "Camp-2.1: PartyButton should clear dress tint after dressing got '%s'" % pb_clear.text)
    else:
        _pass()
    _free_harness_world(btn_world)
    _cleanup_harness_ui_overlay()
    var part_list: String = MapFieldCare.format_part_list(PackedStringArray(["chest", "left_leg"]))
    if not part_list.contains("Chest") or not part_list.contains("L.Leg"):
        _fail(failures, "Camp-2.1: format_part_list want human labels got '%s'" % part_list)
    else:
        _pass()
    CompanyState.set_medical_supplies(label_world, 1)
    var budget_short: Dictionary = CompanyState.triage_med_budget(label_world)
    if int(budget_short.get("med_shortfall", 0)) < 1:
        _fail(failures, "Camp-2.1: med_shortfall should be positive when under-supplied")
    else:
        _pass()
    var gate_line: String = CompanyState.format_party_triage_gate_line(label_world)
    if not gate_line.contains("Short"):
        _fail(failures, "Camp-2.1: triage gate should warn med shortfall got '%s'" % gate_line)
    else:
        _pass()
    var short_hud: String = CompanyState.format_hud_triage_suffix(label_world)
    if not short_hud.contains("about") and not short_hud.contains("need"):
        _fail(failures, "Camp-2.1: HUD suffix should note med estimate got '%s'" % short_hud)
    else:
        _pass()
    _release_harness_world(label_world)

    var undressed_world: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(undressed_world)
    var pm_ud: Node = undressed_world.get_meta("party_manager")
    var ud_ent: Node = _add_living_entity_member(pm_ud, "Clotted")
    ud_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
    var move_msg: String = MapBleedPolicy.map_move_blocked_message(undressed_world)
    if not move_msg.contains("Dress wounds") or not move_msg.contains("1 part"):
        _fail(failures, "Camp-2.1: undressed-only map block should mention dressing got '%s'" % move_msg)
    elif not move_msg.contains("bandage"):
        _fail(failures, "Camp-2.1: map block should cite MARCH chain got '%s'" % move_msg)
    else:
        _pass()
    var hud_ud: String = MapBleedPolicy.hud_bleed_hint(undressed_world)
    if not hud_ud.contains("Dress wounds"):
        _fail(failures, "Camp-2.1: HUD should hint dress when clotted but undressed got '%s'" % hud_ud)
    elif not hud_ud.contains("pressure"):
        _fail(failures, "Camp-2.1: HUD dress hint should cite MARCH chain got '%s'" % hud_ud)
    else:
        _pass()
    var complete_line: String = CompanyState.format_field_care_complete_line(undressed_world)
    if not complete_line.contains("Camp rest unlocked"):
        _fail(failures, "Camp-2.1: field care complete line expected got '%s'" % complete_line)
    else:
        _pass()
    _release_harness_world(undressed_world)

    var step_world: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(step_world)
    var pm_st: Node = step_world.get_meta("party_manager")
    var st_ent: Node = _add_living_entity_member(pm_st, "ClotStep")
    st_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
    CompanyState.set_medical_supplies(step_world, 0)
    MapBleedPolicy.on_overworld_step(step_world)
    if not step_world.has_meta(MapBleedPolicy.WORLD_META_BLEED_WARN):
        _fail(failures, "Camp-2.1: overworld step should warn when clotted but undressed")
    else:
        var warn_msg: String = str(step_world.get_meta(MapBleedPolicy.WORLD_META_BLEED_WARN))
        if not warn_msg.contains("need dressing"):
            _fail(failures, "Camp-2.1: clotted step warn should mention need dressing got '%s'" % warn_msg)
        elif not warn_msg.contains("0-med"):
            _fail(failures, "Camp-2.1: clotted step warn at 0 med should mention 0-med bandages got '%s'" % warn_msg)
        else:
            _pass()
    var settle_hint: String = CompanyState.format_settlement_field_care_hint(step_world)
    if not settle_hint.contains("1 part") or not settle_hint.contains("Party"):
        _fail(failures, "Camp-2.1: settlement field care hint missing got '%s'" % settle_hint)
    elif not settle_hint.contains("0 med"):
        _fail(failures, "Camp-2.1: settlement field care hint at 0 med should cite dress note got '%s'" % settle_hint)
    else:
        _pass()
    (
        step_world
        . set_meta(
            CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {
                "members":
                [
                    {
                        "name": "ClotStep",
                        "snapshot":
                        {
                            "name": "ClotStep",
                            "blood_volume": 100.0,
                            "total_bleeding_rate": 0.0,
                            "has_untreated_wounds": true,
                        },
                    }
                ],
                "deaths": [],
                "winner": "player",
            }
        )
    )
    var worst_settle: Dictionary = PartyRowFormatter.worst_triage_from_member_rows(
        CampaignEncounterBridge.party_member_snapshots(step_world)
    )
    if not str(worst_settle.get("triage_line", "")).contains("bandage/pack/TQ"):
        _fail(
            failures,
            (
                "Camp-2.1: settlement worst triage should cover clotted undressed got '%s'"
                % str(worst_settle.get("triage_line", ""))
            )
        )
    else:
        _pass()
    var clot_snap: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "ClotStep", "node_ref": st_ent})
    var settle_next: String = MapFieldCare.format_next_field_care_action(step_world, clot_snap)
    if not settle_next.contains("Field bandage"):
        _fail(
            failures, "Camp-2.1: settlement row next-action should offer bandage on clotted part got '%s'" % settle_next
        )
    else:
        _pass()
    _release_harness_world(step_world)

    var persist_world: Node2D = _make_world(1)
    var pm_p: Node = persist_world.get_meta("party_manager")
    var persist_ent: Node = _add_living_entity_member(pm_p, "Persist")
    persist_ent.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
    var persist_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "Persist", "node_ref": persist_ent}
    )
    MapFieldCare.try_field_pressure(persist_world, persist_member)
    if not EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
        _fail(failures, "Camp-2.1: field pressure should set compression before step")
    else:
        _pass()
    var held_line: String = MapFieldCare.format_member_pressure_held_line(persist_member)
    if not held_line.contains("Chest"):
        _fail(failures, "Camp-2.1: pressure held line should name part got '%s'" % held_line)
    else:
        _pass()
    CampaignEncounterBridge.advance_party_overworld_minute(persist_world)
    if not EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
        _fail(failures, "Camp-2.1: overworld step must retain field pressure until dressed")
    else:
        _pass()
    _release_harness_world(persist_world)

    OperationalLog.begin_play_session("headless://camp_field_care_done", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var log_world: Node2D = _make_world(1)
    var pm_log: Node = log_world.get_meta("party_manager")
    var log_ent: Node = _add_living_entity_member(pm_log, "LogDress")
    log_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    log_ent.apply_direct_pressure("chest")
    var log_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "LogDress", "node_ref": log_ent})
    CompanyState.set_medical_supplies(log_world, 2)
    var dressed: bool = false
    for attempt in range(24):
        log_ent.bandaged_parts.erase("chest")
        if log_ent.self_direct_pressure_part != "chest":
            log_ent.apply_direct_pressure("chest")
        seed(90210 + attempt)
        if MapFieldCare.try_field_bandage(log_world, log_member):
            dressed = true
            break
    if not dressed:
        _fail(failures, "Camp-2.1: field care log test could not dress chest")
    else:
        _pass()
    var bandage_logged: bool = false
    var bandage_part_logged: bool = false
    var bandage_sim_seconds_logged: bool = false
    var camp_logged: bool = false
    var sim_seconds_s: String = "seconds=%.0f" % MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("field_care bandage") and s.contains("camp_rest_ready"):
            bandage_logged = true
        if s.contains("field_care bandage part=chest"):
            bandage_part_logged = true
        if s.contains("field_care bandage") and s.contains(sim_seconds_s):
            bandage_sim_seconds_logged = true
        if s.contains("camp_heal") and s.contains("all_dressed=true"):
            camp_logged = true
    if not bandage_logged:
        _fail(failures, "Camp-2.1: field bandage success should log camp_rest_ready")
    else:
        _pass()
    if not bandage_part_logged:
        _fail(failures, "Camp-5: field bandage success should log part=chest for F5 grep")
    else:
        _pass()
    if not bandage_sim_seconds_logged:
        _fail(failures, "Camp-2.1: field bandage log should report sim advance %s (not UI 120s)" % sim_seconds_s)
    else:
        _pass()
    if CompanyState.try_camp_heal(log_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: camp heal should succeed after all_dressed log test")
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("camp_heal") and str(line).contains("all_dressed=true"):
            camp_logged = true
            break
    if not camp_logged:
        _fail(failures, "Camp-2.1: camp heal success should log all_dressed=true")
    else:
        _pass()
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    _release_harness_world(log_world)

    OperationalLog.begin_play_session("headless://camp_heal_blocked", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var block_world: Node2D = _make_world(1)
    CompanyState.set_medical_supplies(block_world, 3)
    var pm_block: Node = block_world.get_meta("party_manager")
    var block_ent: Node = _add_living_entity_member(pm_block, "BlockCamp")
    block_ent.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    if CompanyState.try_camp_heal(block_world, true):
        _fail(failures, "Camp-2.1: camp heal should fail when wounds undressed")
    else:
        _pass()
    var block_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("camp_heal blocked:") and s.contains("parts_need=1"):
            block_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not block_logged:
        _fail(failures, "Camp-2.1: camp heal blocked log should include parts_need")
    else:
        _pass()
    _release_harness_world(block_world)

    var healthy_world: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(healthy_world)
    CompanyState.set_medical_supplies(healthy_world, 0)
    if CompanyState.should_show_party_camp_rest_button(healthy_world):
        _fail(failures, "Camp-2.1: healthy roster at 0 med should hide camp rest button")
    else:
        _pass()
    _release_harness_world(healthy_world)

    OperationalLog.begin_play_session("headless://field_care_hint_zero_med", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var zero_hint_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_medical_supplies(zero_hint_world, 0)
    var pm_zh: Node = zero_hint_world.get_meta("party_manager")
    var zh_ent: Node = _add_living_entity_member(pm_zh, "ZeroHint")
    zh_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    CampaignEncounterBridge.on_return_from_combat(zero_hint_world, "player")
    var zero_hint_ok: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("0-med bandages OK"):
            zero_hint_ok = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not zero_hint_ok:
        _fail(failures, "Camp-2.2: post-fight field_care hint at 0 med should mention 0-med bandages")
    else:
        _pass()
    _release_harness_world(zero_hint_world)

    OperationalLog.begin_play_session("headless://contract_victory_triage", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var pay_world: Node2D = _make_world(1)
    CompanyState.set_active_contract(
        pay_world, {"contract_title": "Escort", "pay_gold": 100, "contract_type": "escort"}
    )
    var pm_pay: Node = pay_world.get_meta("party_manager")
    var pay_ent: Node = _add_living_entity_member(pm_pay, "PayBleed")
    pay_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    CompanyState.apply_contract_victory_pay(pay_world)
    var pay_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("contract_victory triage"):
            pay_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not pay_logged:
        _fail(failures, "Camp-2.1: contract victory should log triage budget when wounds remain")
    else:
        _pass()
    _release_harness_world(pay_world)

    var mgr_cnt: Node = CombatManager.new()
    var wounded_cnt: Node = _harness_core_entity()
    wounded_cnt.apply_species()
    wounded_cnt.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    mgr_cnt.register(wounded_cnt, "player")
    var enemy_cnt: Node = _harness_core_entity()
    enemy_cnt.apply_species()
    mgr_cnt.register(enemy_cnt, "enemy")
    mgr_cnt.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr_cnt.medical_phase = true
    mgr_cnt.medical_phase_winner = "player"
    if MedicalPhaseController.winner_side_untreated_part_count(mgr_cnt) != 1:
        _fail(failures, "Camp-2.1: winner_side_untreated_part_count want 1")
    else:
        _pass()
    HarnessFixtures._free_manager(mgr_cnt)

    var bleed_sim_world: Node2D = _make_world(1)
    var pm_bleed: Node = bleed_sim_world.get_meta("party_manager")
    var bleed_sim_ent: Node = _add_living_entity_member(pm_bleed, "BleedSim")
    bleed_sim_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    bleed_sim_ent.apply_direct_pressure("chest")
    var bv_before_pressure: float = float(bleed_sim_ent.blood_volume)
    var cut_before: float = float(bleed_sim_ent.body_cutting.get("chest", 0.0))
    var bleed_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "BleedSim", "node_ref": bleed_sim_ent}
    )
    MapFieldCare.try_field_pressure(bleed_sim_world, bleed_member)
    if float(bleed_sim_ent.blood_volume) > bv_before_pressure + 0.01:
        _fail(failures, "Camp-2.1: field care must not recover blood during active hemorrhage")
    else:
        _pass()
    if float(bleed_sim_ent.body_cutting.get("chest", 0.0)) > cut_before + 0.01:
        _fail(failures, "Camp-2.1: field care procedure must not run tissue healing")
    else:
        _pass()
    _release_harness_world(bleed_sim_world)

    OperationalLog.begin_play_session("headless://camp_field_care_hint", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var hint_world: Node2D = _make_world(1, 0, true)
    var pm_h: Node = hint_world.get_meta("party_manager")
    var bleeder: Node = _add_living_entity_member(pm_h, "HintBleed")
    bleeder.wounds["right_arm"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    CampaignEncounterBridge.on_return_from_combat(hint_world, "player")
    var hint_found: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("Camp rest"):
            hint_found = true
            if not str(line).contains("bandage_med_est="):
                _fail(failures, "Camp-2.2: field_care hint should log med budget estimates")
            if not str(line).contains("med_shortfall="):
                _fail(failures, "Camp-2.2: field_care hint should log med_shortfall")
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not hint_found:
        _fail(failures, "Camp-2.2: on_return_from_combat should log field-care hint when untreated")
    else:
        _pass()
    _release_harness_world(hint_world)

    var triage: String = PartyRowFormatter.format_triage_line(72.0, 1.2)
    if not triage.contains("Class II") or not triage.contains("Bleeding"):
        _fail(failures, "Camp-3.2: triage line should include ATLS band and bleed rate")
    else:
        _pass()
    var eta: String = PartyRowFormatter.format_danger_eta_phrase(40.0, 2.0)
    if eta.is_empty() or not eta.contains("danger"):
        _fail(failures, "Camp-3.2: danger ETA phrase missing for bleeding ally")
    else:
        _pass()

    var debt_world: Node2D = _make_world(2)
    CompanyState.set_gold(debt_world, 5)
    CompanyState.try_advance_day(debt_world)
    if CompanyState.get_gold(debt_world) >= 0:
        _fail(failures, "Camp-2.6: wages should drive gold negative when underfunded")
    else:
        _pass()
    _release_harness_world(debt_world)

    var soft_world: Node2D = _make_world(1, 0, true)
    soft_world.set_script(CampaignWorldScript)
    _add_player_at_camp(soft_world)
    CompanyState.set_gold(soft_world, 77)
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    soft_world.set_meta("rng", rng)
    soft_world.set_meta("enemy_scene", load(ResourcePaths.ENEMY_SCENE) as PackedScene)
    var lost: Dictionary = ContractSpawner.build_encounter_config(ContractSpawner.TUTORIAL_TEMPLATE)
    CombatFlow.resume_overworld_after_soft_defeat(soft_world, lost)
    if CompanyState.get_gold(soft_world) != 77:
        _fail(failures, "Camp-2.6: soft defeat resume must preserve company gold")
    else:
        _pass()
    var tutorial_markers: int = 0
    for child in soft_world.get_children():
        if child is EncounterNode and child.is_tutorial_encounter():
            tutorial_markers += 1
    if tutorial_markers != 1:
        _fail(failures, "Camp-2.6: soft defeat should respawn one tutorial marker got %d" % tutorial_markers)
    else:
        _pass()
    _free_harness_world(soft_world)

    var mood_world: Node2D = _make_world(1)
    var pm_mood: Node = mood_world.get_meta("party_manager")
    pm_mood.members[0]["company_mood"] = 50.0
    CompanyState.apply_battle_lost_mood(mood_world)
    var after: float = float(pm_mood.members[0].get("company_mood", 50.0))
    if not is_equal_approx(after, 49.55):
        _fail(failures, "Camp-2.6 B3: battle loss mood should be -0.45 on living roster got %.2f" % after)
    else:
        _pass()
    _release_harness_world(mood_world)

    var death_mood_world: Node2D = _make_world(1, 1)
    var pm_death: Node = death_mood_world.get_meta("party_manager")
    pm_death.members[0]["company_mood"] = 50.0
    CampaignEncounterBridge.build_last_battle_summary(death_mood_world)
    var survivor_mood: float = float(pm_death.members[0].get("company_mood", 50.0))
    if not is_equal_approx(survivor_mood, 49.75):
        _fail(
            failures, "Camp-2.6 B3: death witness mood should be -0.25 per death on survivors got %.2f" % survivor_mood
        )
    else:
        _pass()
    _release_harness_world(death_mood_world)

    var multi_death_world: Node2D = _make_world(1, 2)
    var pm_multi_death: Node = multi_death_world.get_meta("party_manager")
    pm_multi_death.members[0]["company_mood"] = 50.0
    CampaignEncounterBridge.build_last_battle_summary(multi_death_world)
    var multi_mood: float = float(pm_multi_death.members[0].get("company_mood", 50.0))
    if not is_equal_approx(multi_mood, 49.5):
        _fail(failures, "Camp-2.6 B3: two deaths should be -0.50 on survivor got %.2f" % multi_mood)
    else:
        _pass()
    _release_harness_world(multi_death_world)

    var r3_mood_world: Node2D = _make_world(1, 1)
    var pm_r3: Node = r3_mood_world.get_meta("party_manager")
    pm_r3.members[0]["company_mood"] = 50.0
    CompanyState.set_active_contract(
        r3_mood_world, {"pay_gold": 100, "contract_type": "skirmish", "contract_title": "Paid"}
    )
    CampaignEncounterBridge.build_last_battle_summary(r3_mood_world, "enemy")
    var r3_survivor: float = float(pm_r3.members[0].get("company_mood", 50.0))
    if not is_equal_approx(r3_survivor, 50.0):
        _fail(failures, "Camp-2.6 B3: R3 loss should skip death witness mood before reload got %.2f" % r3_survivor)
    else:
        _pass()
    _release_harness_world(r3_mood_world)

    var restart_world: Node2D = _make_world(1, 0, true)
    restart_world.set_script(CampaignWorldScript)
    PartySetup.setup_party(restart_world)
    var pm_a: Variant = restart_world.get_meta("party_manager")
    PartySetup.setup_party(restart_world)
    var pm_b: Variant = restart_world.get_meta("party_manager")
    var pm_on_world: int = 0
    for child in restart_world.get_children():
        if child.get_script() == _party_manager_script_ref() and not child.is_queued_for_deletion():
            pm_on_world += 1
    if pm_a == pm_b or pm_on_world != 1:
        _fail(failures, "Camp-2.6: setup_party should replace stale world PartyManager (count=%d)" % pm_on_world)
    else:
        _pass()
    var overlay_menus: int = 0
    var overlay_buttons: int = 0
    var harness_root: Node = _harness_root()
    if harness_root != null:
        for layer in harness_root.get_children():
            if layer.name != "UIOverlayLayer":
                continue
            for gc in layer.get_children():
                if gc.get_script() == _party_menu_script_ref():
                    overlay_menus += 1
                elif gc is Button and gc.name == "PartyButton":
                    overlay_buttons += 1
    if overlay_menus != 1 or overlay_buttons != 1:
        _fail(
            failures,
            (
                "Camp-2.6: setup_party should leave one PartyMenu and PartyButton on overlay got menu=%d button=%d"
                % [overlay_menus, overlay_buttons]
            )
        )
    else:
        _pass()
    _free_harness_world(restart_world)
    _cleanup_harness_ui_overlay()

    CompanyStateChecksHarnessPartD._run_camp_4_contract_flavor(failures)
    CompanyStateChecksHarnessPartD._run_encounter_entry_rollback(failures)
    CompanyStateChecksHarnessPartD._run_combat_start_abort_cleanup(failures)
