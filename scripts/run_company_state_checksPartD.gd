class_name CompanyStateChecksHarnessPartD
extends RefCounted

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


static func _run_combat_start_abort_cleanup(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1, 0, true)
    world.set_script(CampaignWorldScript)
    _add_player_at_camp(world)
    var pm: Node = world.get_meta("party_manager")
    if pm is Node and "members" in pm and pm.members.size() > 0:
        var dead_ref: Variant = pm.members[0].get("node_ref")
        if dead_ref is Node:
            (dead_ref as Node).set_script(load("res://scripts/_harness_dead_stub.gd") as Script)
    CompanyState.set_active_contract(world, {"contract_title": "Abort Test", "pay_gold": 50})
    world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"tutorial": false})
    var dummy: Node2D = Node2D.new()
    dummy.name = "SpawnedEnemyStub"
    world.add_child(dummy)
    world.set_meta("_combat_enemies", [dummy])
    CombatFlow.start_combat(world, [])
    if world.has_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT):
        _fail(failures, "Camp-1.4: aborted combat start should clear active_contract")
    else:
        _pass()
    if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
        _fail(failures, "Camp-1.4: aborted combat start should clear combat_encounter meta")
    else:
        _pass()
    if world.has_meta("_combat_enemies"):
        _fail(failures, "Camp-1.4: aborted combat start should clear _combat_enemies")
    else:
        _pass()
    if is_instance_valid(dummy) and not dummy.is_queued_for_deletion():
        _fail(failures, "Camp-1.4: aborted combat start should free spawned enemy nodes")
    else:
        _pass()
    _free_harness_world(world)


static func _run_encounter_entry_rollback(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1, 0, true)
    world.set_script(CampaignWorldScript)
    var rng := RandomNumberGenerator.new()
    var enc: Node2D = EncounterNode.new()
    enc.enemy_count = 0
    enc.encounter_config = ContractSpawner.build_encounter_config(ContractSpawner.TUTORIAL_TEMPLATE)
    world.add_child(enc)
    var before_children: int = world.get_child_count()
    var enemies: Array = CampaignEncounterBridge.begin_contract_encounter(world, enc, rng)
    if not enemies.is_empty():
        _fail(failures, "Camp-1.4: zero-count encounter should return no enemies")
    else:
        _pass()
    if world.has_meta(CompanyState.WORLD_META_ACTIVE_CONTRACT):
        _fail(failures, "Camp-1.4: failed spawn should clear active_contract")
    else:
        _pass()
    if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
        _fail(failures, "Camp-1.4: failed spawn should clear combat_encounter meta")
    else:
        _pass()
    if not is_instance_valid(enc) or not enc.is_inside_tree():
        _fail(failures, "Camp-1.4: failed spawn should keep encounter marker on map")
    else:
        _pass()
    if world.get_child_count() != before_children:
        _fail(failures, "Camp-1.4: failed spawn should not remove encounter node")
    else:
        _pass()
    enc.free()
    _free_harness_world(world)


static func _run_camp_3_player_front_count_encounter(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(7)
    world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 7})
    CampaignEncounterBridge.refresh_party_formation_meta(world)
    var pf: Dictionary = world.get_meta("party_formation", {}) as Dictionary
    if int(pf.get("files", 0)) != 7:
        _fail(failures, "Camp-3/III-4: player_front_count=7 want files=7 got %d" % int(pf.get("files", 0)))
    elif int(pf.get("ranks", 0)) != 1:
        _fail(failures, "Camp-3/III-4: player_front_count=7 want ranks=1 got %d" % int(pf.get("ranks", 0)))
    else:
        _pass()
    world.free()


static func _run_camp_4_contract_flavor(failures: PackedStringArray) -> void:
    var SoakPresets := preload("res://world/SoakEncounterPresets.gd")
    var CombatConstants := preload("res://combat/CombatConstants.gd")
    var skirmish: Dictionary = ContractSpawner.build_encounter_config(ContractSpawner.CONTRACT_TEMPLATES[0])
    if str(skirmish.get(SoakPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")) != "SWORD":
        _fail(failures, "Camp-4.3: skirmish should force SWORD")
    else:
        _pass()
    if int(skirmish.get(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 7:
        _fail(failures, "Camp-4/III-4: Border Skirmish template want player_front_count=7")
    else:
        _pass()
    if (
        str(skirmish.get(CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "Camp-4/III-4: Border Skirmish should set enemy pinch_center doctrine")
    else:
        _pass()
    var world_sk: Node2D = _make_world(7)
    var enc_sk: Node2D = EncounterNode.new()
    enc_sk.encounter_config = skirmish
    CampaignEncounterBridge.prepare_combat_from_encounter(world_sk, enc_sk)
    var pf_sk: Dictionary = world_sk.get_meta("party_formation", {}) as Dictionary
    if int(pf_sk.get("files", 0)) != 7 or int(pf_sk.get("ranks", 0)) != 1:
        _fail(
            failures,
            (
                "Camp-4/III-4: skirmish prepare_combat want 7x1 party_formation got files=%d ranks=%d"
                % [int(pf_sk.get("files", 0)), int(pf_sk.get("ranks", 0))]
            )
        )
    else:
        _pass()
    world_sk.free()
    enc_sk.free()
    var escort: Dictionary = ContractSpawner.build_encounter_config(ContractSpawner.CONTRACT_TEMPLATES[1])
    if (
        str(escort.get(CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "Camp-4.2: escort should set enemy pinch_center doctrine")
    else:
        _pass()
    if float(escort.get("flee_line_cohesion_max_enemy", 0.0)) <= 0.0:
        _fail(failures, "Camp-4.2: escort should set flee_line_cohesion_max_enemy")
    else:
        _pass()
    if int(escort.get(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 5:
        _fail(failures, "Camp-4/III-4: Escort template want player_front_count=5 (Formation 5x2, not Skirmish 7-wide)")
    else:
        _pass()
    var world_esc: Node2D = _make_world(7)
    world_esc.set_meta(
        CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 5}
    )
    CampaignEncounterBridge.refresh_party_formation_meta(world_esc)
    var pf_esc: Dictionary = world_esc.get_meta("party_formation", {}) as Dictionary
    if int(pf_esc.get("files", 0)) != 5 or int(pf_esc.get("ranks", 0)) != 2:
        _fail(
            failures,
            (
                "Camp-4/III-4: escort party_formation want 5x2 got files=%d ranks=%d"
                % [int(pf_esc.get("files", 0)), int(pf_esc.get("ranks", 0))]
            )
        )
    else:
        _pass()
    world_esc.free()
    var world_esc_pc: Node2D = _make_world(7)
    var enc_esc: Node2D = EncounterNode.new()
    enc_esc.encounter_config = escort
    CampaignEncounterBridge.prepare_combat_from_encounter(world_esc_pc, enc_esc)
    var pf_esc_pc: Dictionary = world_esc_pc.get_meta("party_formation", {}) as Dictionary
    if int(pf_esc_pc.get("files", 0)) != 5 or int(pf_esc_pc.get("ranks", 0)) != 2:
        _fail(
            failures,
            (
                "Camp-4/III-4: escort prepare_combat want 5x2 party_formation got files=%d ranks=%d"
                % [int(pf_esc_pc.get("files", 0)), int(pf_esc_pc.get("ranks", 0))]
            )
        )
    else:
        _pass()
    world_esc_pc.free()
    enc_esc.free()
    var enc: Node2D = EncounterNode.new()
    enc.encounter_config = escort
    var meta_world: Node2D = _make_world(1)
    CampaignEncounterBridge.prepare_combat_from_encounter(meta_world, enc)
    var got: Dictionary = meta_world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if got.is_empty() or not got.has(CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY):
        _fail(failures, "Camp-4.2: escort doctrine should reach combat meta")
    else:
        _pass()
    meta_world.free()
    enc.free()
    var lbl: String = ContractSpawner.format_marker_label(ContractSpawner.CONTRACT_TEMPLATES[1])
    if not lbl.contains("Escort") and not lbl.contains("120"):
        _fail(failures, "Camp-4: escort marker label should show title/pay")
    elif not lbl.contains("5-wide"):
        _fail(failures, "Camp-4/III-4: escort marker label should show 5-wide formation hint")
    else:
        _pass()
    var skirmish_lbl: String = ContractSpawner.format_marker_label(ContractSpawner.CONTRACT_TEMPLATES[0])
    if not skirmish_lbl.contains("7-wide"):
        _fail(failures, "Camp-4/III-4: skirmish marker label should show 7-wide formation hint")
    else:
        _pass()
    var tut_default: Dictionary = FormationPreset.default_for_count(7)
    var world_fresh_tut: Node2D = _make_world(7)
    ContractSpawner._spawn_contract_at_tile(world_fresh_tut, Vector2i(1, 0), ContractSpawner.TUTORIAL_TEMPLATE, null)
    var fresh_enc: EncounterNode = null
    for child in world_fresh_tut.get_children():
        if child is EncounterNode:
            fresh_enc = child as EncounterNode
            break
    if fresh_enc == null:
        _fail(failures, "Camp-4/III-4: tutorial spawn should create encounter marker")
    else:
        _pass()
    if fresh_enc != null:
        CampaignEncounterBridge.prepare_combat_from_encounter(world_fresh_tut, fresh_enc)
        var pf_fresh: Dictionary = world_fresh_tut.get_meta("party_formation", {}) as Dictionary
        if (
            int(pf_fresh.get("files", 0)) != int(tut_default.get("files", 0))
            or int(pf_fresh.get("ranks", 0)) != int(tut_default.get("ranks", 0))
        ):
            _fail(
                failures,
                (
                    "Camp-4/III-4: tutorial spawn want default party_formation got files=%d ranks=%d"
                    % [int(pf_fresh.get("files", 0)), int(pf_fresh.get("ranks", 0))]
                )
            )
        else:
            _pass()
    world_fresh_tut.free()
    var tut_lbl: String = ContractSpawner.format_marker_label(ContractSpawner.TUTORIAL_TEMPLATE)
    if not tut_lbl.contains("Tutorial") or not tut_lbl.contains("2 foes"):
        _fail(failures, "Camp-4/III-4: tutorial marker label should show tutorial title and foe count")
    else:
        _pass()
    if ContractSpawner.TUTORIAL_TEMPLATE.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT):
        _fail(failures, "Camp-4/III-4: tutorial template must not pin player_front_count")
    else:
        _pass()
    var old_save_tut: Dictionary = ContractSpawner.TUTORIAL_TEMPLATE.duplicate(true)
    old_save_tut[CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT] = 2
    old_save_tut[CombatConstants.ENCOUNTER_KEY_PLAYER_FORMATION] = {"files": 2, "ranks": 4}
    var world_saved_tut: Node2D = _make_world(7)
    ContractSpawner.spawn_saved_encounter_at_tile(
        world_saved_tut, Vector2i(1, 0), old_save_tut, 2, {}, "Tutorial", "tutorial", null
    )
    var saved_enc: EncounterNode = null
    for child in world_saved_tut.get_children():
        if child is EncounterNode:
            saved_enc = child as EncounterNode
            break
    if saved_enc == null:
        _fail(failures, "Camp-4/III-4: spawn_saved_encounter_at_tile should create tutorial marker")
    else:
        _pass()
    if (
        saved_enc != null
        and (
            saved_enc.encounter_config.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT)
            or saved_enc.encounter_config.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FORMATION)
        )
    ):
        _fail(failures, "Camp-4/III-4: saved tutorial marker must store normalized encounter_config")
    else:
        _pass()
    if saved_enc != null:
        CampaignEncounterBridge.prepare_combat_from_encounter(world_saved_tut, saved_enc)
        var pf_saved: Dictionary = world_saved_tut.get_meta("party_formation", {}) as Dictionary
        if (
            int(pf_saved.get("files", 0)) != int(tut_default.get("files", 0))
            or int(pf_saved.get("ranks", 0)) != int(tut_default.get("ranks", 0))
        ):
            _fail(
                failures,
                (
                    "Camp-4/III-4: saved tutorial marker want default party_formation got files=%d ranks=%d"
                    % [int(pf_saved.get("files", 0)), int(pf_saved.get("ranks", 0))]
                )
            )
        else:
            _pass()
    world_saved_tut.free()


static func _run_camp_5_ea_log_markers(failures: PackedStringArray) -> void:
    OperationalLog.set_capture_enabled(true)
    if OperationalLog.is_play_session_active():
        OperationalLog.end_play_session()
    var silent_ok: bool = false
    for seed_try in range(8000):
        seed(seed_try)
        OperationalLog.clear_capture()
        var silent_world: Node2D = _make_world(1)
        var pm_silent: Node = silent_world.get_meta("party_manager")
        for raw in pm_silent.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 10.0
        CompanyState._run_daily_desertion_pass(silent_world)
        var summary_logged: bool = false
        for line in OperationalLog.get_captured_lines():
            if str(line).contains("desertion summary="):
                summary_logged = true
                break
        if CompanyState.is_bankrupt(silent_world) and not summary_logged:
            silent_ok = true
        _release_harness_world(silent_world)
        if silent_ok:
            break
    OperationalLog.set_capture_enabled(false)
    if not silent_ok:
        _fail(failures, "Camp-5: desertion should collapse roster without desertion summary outside play session")
    else:
        _pass()

    OperationalLog.begin_play_session("headless://camp_debt_warn", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var debt_world: Node2D = _make_world(2, 0, true)
    CompanyState.set_gold(debt_world, 5)
    CompanyState.try_advance_day(debt_world)
    var debt_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("Company is in debt"):
            debt_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not debt_logged:
        _fail(failures, "Camp-5: try_advance_day should log debt warning when gold negative")
    else:
        _pass()
    _release_harness_world(debt_world)

    OperationalLog.begin_play_session("headless://camp_settlement_continue", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var settle_world: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(settle_world)
    (
        CompanyState
        . set_active_contract(
            settle_world,
            {
                "pay_gold": 120,
                "contract_title": "Border Skirmish",
                "contract_type": "skirmish",
            }
        )
    )
    var settle_contract: Dictionary = CompanyState.get_active_contract(settle_world)
    var settle_pay: int = CompanyState.apply_contract_victory_pay(settle_world)
    OperationalLog.play_world(SettlementPanel.format_settlement_continue_log(settle_world, settle_contract, settle_pay))
    var victory_logged: bool = false
    var continue_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("contract_victory pay=") and s.contains("gold="):
            victory_logged = true
        if s.contains("settlement_continue pay=") and s.contains("tutorial=false"):
            continue_logged = true
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not victory_logged:
        _fail(failures, "Camp-5: paid contract win should log contract_victory pay=")
    else:
        _pass()
    if not continue_logged:
        _fail(failures, "Camp-5: settlement continue should log pay= gold= renown= tutorial=false")
    else:
        _pass()
    _release_harness_world(settle_world)

    var tut_settle_world: Node2D = _make_world(1)
    CompanyState.set_active_contract(
        tut_settle_world, ContractSpawner.build_encounter_config(ContractSpawner.TUTORIAL_TEMPLATE)
    )
    var tut_contract: Dictionary = CompanyState.get_active_contract(tut_settle_world)
    OperationalLog.begin_play_session("headless://camp_tutorial_settlement", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var tut_pay: int = CompanyState.apply_contract_victory_pay(tut_settle_world)
    OperationalLog.play_world(SettlementPanel.format_settlement_continue_log(tut_settle_world, tut_contract, tut_pay))
    var tut_victory_logged: bool = false
    var tut_continue_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("contract_victory tutorial"):
            tut_victory_logged = true
        if s.contains("settlement_continue pay=0") and s.contains("tutorial=true"):
            tut_continue_logged = true
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if tut_pay != 0:
        _fail(failures, "Camp-5: tutorial contract victory pay should be 0")
    else:
        _pass()
    if not tut_victory_logged:
        _fail(failures, "Camp-5: tutorial win should log contract_victory tutorial")
    else:
        _pass()
    if not tut_continue_logged:
        _fail(failures, "Camp-5: tutorial settlement continue should log pay=0 tutorial=true")
    else:
        _pass()
    _release_harness_world(tut_settle_world)

    OperationalLog.begin_play_session("headless://camp_field_care_pressure", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var press_world: Node2D = _make_world(1, 0, true)
    var leader_ent: Node = _harness_core_entity()
    leader_ent.name = "Character"
    press_world.add_child(leader_ent)
    var pm_press: Node = press_world.get_meta("party_manager")
    var press_patient: Node = _harness_core_entity()
    press_patient.wounds["right_arm"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    pm_press.add_child(press_patient)
    pm_press.members.append({"name": "PressBro", "node_ref": press_patient, "company_mood": 50.0})
    var press_member: Dictionary = PartyMemberSnapshot.snapshot_from_member(
        {"name": "PressBro", "node_ref": press_patient}
    )
    if not MapFieldCare.try_field_pressure(press_world, press_member):
        _fail(failures, "Camp-5: field pressure action should succeed on ally arm wound")
    else:
        _pass()
    var pressure_logged: bool = false
    var pressure_sim_seconds_logged: bool = false
    var field_care_sim_seconds_s: String = "seconds=%.0f" % MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("field_care pressure part=right_arm"):
            pressure_logged = true
        if s.contains("field_care pressure") and s.contains(field_care_sim_seconds_s):
            pressure_sim_seconds_logged = true
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not pressure_logged:
        _fail(failures, "Camp-5: field pressure success should log field_care pressure part=")
    else:
        _pass()
    if not pressure_sim_seconds_logged:
        _fail(failures, "Camp-2.1: field pressure log should report sim advance %s" % field_care_sim_seconds_s)
    else:
        _pass()
    _release_harness_world(press_world)

    OperationalLog.begin_play_session("headless://camp_field_care_hint", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var hint_world: Node2D = _make_world(1)
    var pm_hint: Node = hint_world.get_meta("party_manager")
    var hint_ent: Node = _add_living_entity_member(pm_hint, "HintBro")
    hint_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    var hint_line: String = CompanyState.format_post_fight_field_care_world_log(hint_world)
    if not hint_line.begins_with("field_care:"):
        _fail(failures, "Camp-5: post-fight field care hint should begin with field_care:")
    else:
        _pass()
    OperationalLog.play_world(hint_line)
    var hint_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("need dressing"):
            hint_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not hint_logged:
        _fail(failures, "Camp-5: field_care hint should log need dressing on map return")
    else:
        _pass()
    _release_harness_world(hint_world)

    OperationalLog.begin_play_session("headless://camp_company_day", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var day_world: Node2D = _make_world(2, 0, true)
    var day_before: int = CompanyState.get_day_index(day_world)
    CompanyState.try_advance_day(day_world)
    var day_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if (
            s.contains("company_day_advanced day=%d" % (day_before + 1))
            and s.contains("wages_paid=")
            and s.contains("living=2")
        ):
            day_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not day_logged:
        _fail(failures, "Camp-5: try_advance_day should log company_day_advanced day=%d living=2" % (day_before + 1))
    else:
        _pass()
    _release_harness_world(day_world)

    OperationalLog.begin_play_session("headless://camp_rest_day_advance", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var rest_world: Node2D = _make_world(1, 0, true)
    CompanyState.mark_tutorial_completed(rest_world)
    CompanyState.set_medical_supplies(rest_world, 3)
    var pm_rest: Node = rest_world.get_meta("party_manager")
    var rest_ent: Node = _add_living_entity_member(pm_rest, "CampRest")
    rest_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    rest_ent.apply_direct_pressure("chest")
    var rest_member: Dictionary = PartyMemberSnapshot.snapshot_from_member({"name": "CampRest", "node_ref": rest_ent})
    var rest_dressed: bool = false
    for attempt in range(24):
        rest_ent.bandaged_parts.erase("chest")
        if rest_ent.self_direct_pressure_part != "chest":
            rest_ent.apply_direct_pressure("chest")
        seed(90300 + attempt)
        if MapFieldCare.try_field_bandage(rest_world, rest_member):
            rest_dressed = true
            break
    if not rest_dressed:
        _fail(failures, "Camp-5: camp rest day test could not dress chest")
    else:
        _pass()
    var rest_day_before: int = CompanyState.get_day_index(rest_world)
    if not CompanyState.try_camp_heal(rest_world, true):
        _fail(failures, "Camp-5: camp rest should succeed when all wounds dressed")
    else:
        _pass()
    var camp_day_logged: bool = false
    var camp_heal_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_day_advanced day=%d" % (rest_day_before + 1)) and s.contains("wages_paid="):
            camp_day_logged = true
        if s.contains("camp_heal") and s.contains("all_dressed=true"):
            camp_heal_logged = true
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not camp_day_logged:
        _fail(failures, "Camp-5: Party camp rest should log company_day_advanced day=%d" % (rest_day_before + 1))
    else:
        _pass()
    if not camp_heal_logged:
        _fail(failures, "Camp-5: Party camp rest should log camp_heal all_dressed=true")
    else:
        _pass()
    _release_harness_world(rest_world)

    OperationalLog.begin_play_session("headless://camp_bankrupt_collapse", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var bankrupt_collapse: bool = false
    for seed_try in range(8000):
        seed(seed_try)
        OperationalLog.clear_capture()
        var broke_world: Node2D = _make_world(1)
        var pm_broke: Node = broke_world.get_meta("party_manager")
        for raw in pm_broke.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 10.0
        CompanyState._run_daily_desertion_pass(broke_world)
        if not CompanyState.is_bankrupt(broke_world):
            _release_harness_world(broke_world)
            continue
        if CompanyState.count_living_roster(broke_world) > 0:
            _release_harness_world(broke_world)
            continue
        OperationalLog.play_world(CompanyRunEndPanel.format_company_run_end_log("bankrupt"))
        var desertion_seen: bool = false
        var bankrupt_log_seen: bool = false
        for line in OperationalLog.get_captured_lines():
            var s: String = str(line)
            if s.contains("desertion summary=") and s.contains("(mood="):
                desertion_seen = true
            if s.contains("company_run_end reason=bankrupt reload=true"):
                bankrupt_log_seen = true
        if desertion_seen and bankrupt_log_seen:
            bankrupt_collapse = true
        _release_harness_world(broke_world)
        if bankrupt_collapse:
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not bankrupt_collapse:
        _fail(failures, "Camp-5: total desertion should set bankrupt and log reason=bankrupt reload=true")
    else:
        _pass()

    OperationalLog.begin_play_session("headless://camp_run_end_logs", "", false, false)
    OperationalLog.set_capture_enabled(true)
    for reason in ["contract_failed", "tutorial_failed", "soft_defeat_resume"]:
        OperationalLog.play_world(CompanyRunEndPanel.format_company_run_end_log(reason))
    var paid_logged: bool = false
    var tut_logged: bool = false
    var soft_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_run_end reason=contract_failed reload=true"):
            paid_logged = true
        if s.contains("company_run_end reason=tutorial_failed reload=false"):
            tut_logged = true
        if s.contains("company_run_end reason=soft_defeat_resume reload=false"):
            soft_logged = true
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not paid_logged:
        _fail(failures, "Camp-5: company_run_end should log contract_failed reload=true")
    else:
        _pass()
    if not tut_logged:
        _fail(failures, "Camp-5: company_run_end should log tutorial_failed reload=false")
    else:
        _pass()
    if not soft_logged:
        _fail(failures, "Camp-5: company_run_end should log soft_defeat_resume reload=false")
    else:
        _pass()

    OperationalLog.begin_play_session("headless://camp_party_triage", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var triage_world: Node2D = _make_world(1, 0, true)
    var pm_triage: Node = triage_world.get_meta("party_manager")
    _add_living_entity_member(pm_triage, "OkBro")
    var wound_bro: Node = _add_living_entity_member(pm_triage, "WoundBro")
    wound_bro.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
    var roster: Array = []
    for raw in pm_triage.members:
        if raw is Dictionary:
            roster.append(PartyMemberSnapshot.snapshot_from_member(raw as Dictionary))
    var menu: PopupPanel = _new_party_menu()
    triage_world.add_child(menu)
    menu.show_party(triage_world, roster)
    var triage_open_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("party_triage_open living=") and s.contains("untreated="):
            triage_open_logged = true
            break
    var label_blob: String = " ".join(_collect_control_label_texts(menu))
    if not triage_open_logged:
        _fail(failures, "Camp-5: Party open should log party_triage_open living=")
    else:
        _pass()
    if not label_blob.contains("Needs dressing") or not label_blob.contains("Chest"):
        _fail(
            failures,
            (
                "Camp-5: Party triage row should list untreated part (got snippet '%s')"
                % label_blob.substr(0, mini(120, label_blob.length()))
            )
        )
    else:
        _pass()
    if not label_blob.contains("WoundBro") or not label_blob.contains("Wounded"):
        _fail(failures, "Camp-5: Party triage should surface wounded brother section")
    else:
        _pass()
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    menu.queue_free()
    _release_harness_world(triage_world)
