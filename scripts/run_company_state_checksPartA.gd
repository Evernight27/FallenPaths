class_name CompanyStateChecksHarnessPartA
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


static func _run_camp_1_1_company_state(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    var state: Dictionary = CompanyState.get_state(world)
    if int(state.get("gold", -1)) != CompanyState.DEFAULT_GOLD:
        _fail(failures, "Camp-1.1: gold want %d got %s" % [CompanyState.DEFAULT_GOLD, state.get("gold")])
    else:
        _pass()
    if int(state.get("medical_supplies", -1)) != CompanyState.DEFAULT_MEDICAL_SUPPLIES:
        _fail(
            failures,
            "Camp-1.1: med want %d got %s" % [CompanyState.DEFAULT_MEDICAL_SUPPLIES, state.get("medical_supplies")]
        )
    else:
        _pass()
    if int(state.get("tool_supplies", -1)) != CompanyState.DEFAULT_TOOL_SUPPLIES:
        _fail(
            failures,
            "Camp-1.1: tools want %d got %s" % [CompanyState.DEFAULT_TOOL_SUPPLIES, state.get("tool_supplies")]
        )
    else:
        _pass()
    if int(state.get("food_supplies", -1)) != CompanyState.DEFAULT_FOOD_SUPPLIES:
        _fail(
            failures, "Camp-1.1: food want %d got %s" % [CompanyState.DEFAULT_FOOD_SUPPLIES, state.get("food_supplies")]
        )
    else:
        _pass()
    if int(state.get("renown", -1)) != CompanyState.DEFAULT_RENOWN:
        _fail(failures, "Camp-1.1: renown want 0 got %s" % state.get("renown"))
    else:
        _pass()
    if bool(state.get("bankrupt", true)):
        _fail(failures, "Camp-1.1: bankrupt should start false")
    else:
        _pass()
    if CompanyState.WORLD_META_COMPANY_STATE != "company_state":
        _fail(failures, "Camp-1.1: company_state meta key")
    else:
        _pass()
    _release_harness_world(world)

    var world_hud: Node2D = _make_world(1, 0, true)
    CompanyState.attach_to_world(world_hud)
    if not world_hud.has_meta(CompanyState.WORLD_META_COMPANY_HUD):
        _fail(failures, "Camp-1.1: attach_to_world should create company HUD meta")
    else:
        _pass()
    var hud: Control = world_hud.get_meta(CompanyState.WORLD_META_COMPANY_HUD) as Control
    if hud == null or not hud.has_method("refresh_from_state"):
        _fail(failures, "Camp-1.1: company HUD missing refresh_from_state")
    else:
        _pass()
    var gold_after_encounter: int = CompanyState.get_gold(world_hud)
    CompanyState.add_gold(world_hud, 77)
    if CompanyState.get_gold(world_hud) != gold_after_encounter + 77:
        _fail(failures, "Camp-1.1: gold should persist in company_state meta")
    else:
        _pass()
    if hud is CompanyHud:
        var gold_lbl: Label = (hud as CompanyHud)._gold_label
        if gold_lbl == null or not str(gold_lbl.text).contains(str(gold_after_encounter + 77)):
            _fail(failures, "Camp-1.1: HUD gold label want %d got '%s'" % [gold_after_encounter + 77, gold_lbl.text])
        else:
            _pass()
    _free_harness_world(world_hud)


# --- Camp-1.2 ---


static func _run_camp_1_2_wages_and_day(failures: PackedStringArray) -> void:
    if CompanyState.read_stub_day_tick_mode() != "hybrid":
        _fail(failures, "Camp-1.2: day_tick_mode want hybrid")
    else:
        _pass()
    var world: Node2D = _make_world(2)
    var steps: int = CompanyState.read_stub_steps_per_day()
    var bill: int = CompanyState.compute_next_wage_bill(world)
    for _i in steps:
        CompanyState.on_overworld_step(world)
    if CompanyState.get_day_index(world) != 1:
        _fail(failures, "Camp-1.2: day_index want 1 got %d after %d steps" % [CompanyState.get_day_index(world), steps])
    else:
        _pass()
    var want_gold: int = CompanyState.DEFAULT_GOLD - bill
    if CompanyState.get_gold(world) != want_gold:
        _fail(
            failures,
            "Camp-1.2: gold want %d got %d (bill=%d living=2)" % [want_gold, CompanyState.get_gold(world), bill]
        )
    else:
        _pass()
    if CompanyState.get_overworld_step_count(world) != 0:
        _fail(failures, "Camp-1.2: step count should reset after day advance")
    else:
        _pass()
    _release_harness_world(world)

    var world_dead: Node2D = _make_world(1, 1)
    if CompanyState.compute_next_wage_bill(world_dead) != CompanyState.DEFAULT_WAGE_PER_MEMBER:
        _fail(failures, "Camp-1.2: dead brother excluded from wage bill")
    else:
        _pass()
    _release_harness_world(world_dead)

    var world_hybrid: Node2D = _make_world(1, 0, true)
    _add_player_at_camp(world_hybrid)
    world_hybrid.get_node("Character").position = Vector2(192, 192)
    if CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day off camp should fail")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(160, 160)
    if CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day still off camp at (2,2)")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(32, 32)
    var gold_before: int = CompanyState.get_gold(world_hybrid)
    if not CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day on camp should succeed")
    else:
        _pass()
    if CompanyState.get_gold(world_hybrid) != gold_before - CompanyState.DEFAULT_WAGE_PER_MEMBER:
        _fail(failures, "Camp-1.2: end_day on camp should deduct one living wage")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(192, 192)
    var off_camp_hint: String = CompanyState.format_party_end_day_unavailable_hint(world_hybrid)
    if not off_camp_hint.contains("camp tile"):
        _fail(failures, "Camp-1.2: off-camp End day hint expected got '%s'" % off_camp_hint)
    else:
        _pass()
    _free_harness_world(world_hybrid)

    var hint_state: Dictionary = {
        "gold": 20,
        "wage_per_member": CompanyState.DEFAULT_WAGE_PER_MEMBER,
    }
    if not CompanyState.should_show_next_wage_hint(hint_state, 2):
        _fail(failures, "Camp-1.2: wage hint when gold below bill")
    else:
        _pass()
    hint_state["gold"] = 100
    if CompanyState.should_show_next_wage_hint(hint_state, 2):
        _fail(failures, "Camp-1.2: no wage hint when gold sufficient")
    else:
        _pass()

    OperationalLog.begin_play_session("headless://camp_wage_warn", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var wage_world: Node2D = _make_world(2, 0, true)
    CompanyState.set_gold(wage_world, 10)
    CompanyState.try_advance_day(wage_world)
    var wage_warn_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_wages: gold=") and s.contains("below next wage bill="):
            wage_warn_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not wage_warn_logged:
        _fail(failures, "Camp-5: try_advance_day should log company_wages warn when gold below bill")
    else:
        _pass()
    _release_harness_world(wage_world)

    OperationalLog.begin_play_session("headless://camp_desertion_summary", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var desertion_logged: bool = false
    for seed_try in range(4000):
        seed(seed_try)
        OperationalLog.clear_capture()
        var des_world: Node2D = _make_world(2)
        var pm_des: Node = des_world.get_meta("party_manager")
        for raw in pm_des.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 12.0
        CompanyState._run_daily_desertion_pass(des_world)
        for line in OperationalLog.get_captured_lines():
            var s: String = str(line)
            if s.contains("desertion summary=") and s.contains("(mood="):
                desertion_logged = true
                break
        _release_harness_world(des_world)
        if desertion_logged:
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not desertion_logged:
        _fail(failures, "Camp-5: desertion summary should log name(mood=N) under desertion pass")
    else:
        _pass()
    var risk_world: Node2D = _make_world(2)
    var pm_risk: Node = risk_world.get_meta("party_manager")
    for raw in pm_risk.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 10.0
    if CompanyState.count_desertion_risk_roster(risk_world) < 1:
        _fail(
            failures,
            "Camp-5: desertion risk count want >= 1 got %d" % CompanyState.count_desertion_risk_roster(risk_world)
        )
    else:
        _pass()
    var risk_footer: String = CompanyState.format_party_desertion_risk_footer(risk_world)
    if not risk_footer.contains("desertion"):
        _fail(failures, "Camp-5: desertion risk footer expected got '%s'" % risk_footer)
    else:
        _pass()
    var menu_footer: String = CompanyState.format_party_menu_footer(risk_world)
    if not menu_footer.contains("desertion"):
        _fail(failures, "Camp-5: party menu footer should include desertion got '%s'" % menu_footer)
    else:
        _pass()
    _release_harness_world(risk_world)


# --- Camp-1.3 ---


static func _run_camp_1_3_supply_pools(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    if not CompanyState.consume_medical(world, 1):
        _fail(failures, "Camp-1.3: consume_medical should succeed")
    else:
        _pass()
    if CompanyState.get_medical_supplies(world) != CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1:
        _fail(
            failures,
            (
                "Camp-1.3: med supplies want %d got %d"
                % [CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1, CompanyState.get_medical_supplies(world)]
            )
        )
    else:
        _pass()
    if CompanyState.consume_medical(world, 99):
        _fail(failures, "Camp-1.3: consume_medical should fail when insufficient")
    else:
        _pass()
    if not CompanyState.consume_tool(world, 1):
        _fail(failures, "Camp-1.3: consume_tool should succeed")
    else:
        _pass()
    if CompanyState.get_tool_supplies(world) != 1:
        _fail(failures, "Camp-1.3: tool supplies want 1 got %d" % CompanyState.get_tool_supplies(world))
    else:
        _pass()
    if CompanyState.consume_tool(world, 5):
        _fail(failures, "Camp-1.3: consume_tool should fail when insufficient")
    else:
        _pass()
    world.free()


# --- Camp-1.4 ---


static func _run_camp_1_4_contracts(failures: PackedStringArray) -> void:
    if CompanyState.read_stub_persistence_mode() != "P2":
        _fail(failures, "Camp-5: persistence gate want P2 (single-slot autosave)")
    else:
        _pass()
    if not CompanyState.persistence_uses_disk_autosave():
        _fail(failures, "Camp-5: persistence_uses_disk_autosave should be true for P2")
    else:
        _pass()
    if not CompanyState.persistence_restore_on_main_restart():
        _fail(failures, "Camp-5: P2 testing should restore autosave on main restart")
    else:
        _pass()
    if CompanyState.persistence_clear_slot_on_run_end_reload():
        _fail(failures, "Camp-5: P2 testing should keep slot on run-end reload")
    else:
        _pass()
    if not CompanyState.P2_RESTORE_ON_MAIN_RESTART:
        _fail(failures, "Camp-5: P2_RESTORE_ON_MAIN_RESTART should be true for testing")
    else:
        _pass()
    if not CompanyState.can_offer_new_campaign_from_menu():
        _fail(failures, "Camp-5: new company wipe should be offered during P2 testing")
    else:
        _pass()
    var wage_world: Node2D = _make_world(2)
    CompanyState.set_gold(wage_world, 5)
    var wage_hint: String = CompanyState.format_next_wage_hint(CompanyState.get_state(wage_world), 2)
    if not wage_hint.contains("short") or not wage_hint.contains("mood"):
        _fail(failures, "Camp-5: wage hint should note shortfall + mood got '%s'" % wage_hint)
    else:
        _pass()
    var debt_hint: String = CompanyState.format_next_wage_hint(
        {"gold": -20, "wage_per_member": CompanyState.DEFAULT_WAGE_PER_MEMBER}, 2
    )
    if not debt_hint.contains("desertion"):
        _fail(failures, "Camp-5: wage hint in debt should cite desertion got '%s'" % debt_hint)
    else:
        _pass()
    var end_day_lbl: String = CompanyState.format_end_day_button_label(wage_world)
    if not end_day_lbl.contains("wages short"):
        _fail(failures, "Camp-2.6: End day button should warn when wages short got '%s'" % end_day_lbl)
    else:
        _pass()
    if (
        CompanyState.format_wages_short_log(10, 30)
        != ("Wages short  -  paid what you could; mood fell (gold 10, bill 30).")
    ):
        _fail(failures, "Camp-2.6: wages short log shape drift")
    else:
        _pass()
    if not CompanyState.format_company_debt_log(-25).contains("desert"):
        _fail(failures, "Camp-2.6: debt log should mention desertion")
    else:
        _pass()
    var wage_suffix: String = CompanyState.format_hud_wage_suffix(wage_world)
    if not wage_suffix.contains("wages short"):
        _fail(failures, "Camp-2.6: Party title wage suffix when short got '%s'" % wage_suffix)
    else:
        _pass()
    _release_harness_world(wage_world)
    var debt_suffix_world: Node2D = _make_world(2)
    CompanyState.set_gold(debt_suffix_world, 5)
    CompanyState.try_advance_day(debt_suffix_world)
    if CompanyState.get_gold(debt_suffix_world) >= 0:
        _fail(failures, "Camp-2.6: debt suffix harness needs negative gold after wage tick")
    else:
        _pass()
    var debt_suffix: String = CompanyState.format_hud_wage_suffix(debt_suffix_world)
    if not debt_suffix.contains("wage debt"):
        _fail(failures, "Camp-2.6: Party title wage suffix in debt got '%s'" % debt_suffix)
    else:
        _pass()
    var camp_lbl: String = CompanyState.format_camp_rest_button_label(debt_suffix_world, true)
    if not camp_lbl.contains("wage debt"):
        _fail(failures, "Camp-2.6: Camp rest button should warn wage debt got '%s'" % camp_lbl)
    else:
        _pass()
    _release_harness_world(debt_suffix_world)
    if (
        CompanyRunEndPanel.format_company_run_end_log("contract_failed")
        != ("company_run_end reason=contract_failed reload=true clears_slot=false")
    ):
        _fail(failures, "Camp-5: run-end log should keep slot during P2 testing restore")
    else:
        _pass()
    if CompanyState.read_stub_encounter_lifecycle() != "r3_loss_ends_run":
        _fail(failures, "Camp-1.4: encounter lifecycle want r3_loss_ends_run")
    else:
        _pass()
    if not CompanyState.contract_loss_ends_run():
        _fail(failures, "Camp-1.4: contract_loss_ends_run should be true")
    else:
        _pass()
    if ContractSpawner.get_template_count() < 2:
        _fail(failures, "Camp-1.4: need >= 2 contract templates")
    else:
        _pass()

    var world: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(world)
    var gold_before: int = CompanyState.get_gold(world)
    (
        CompanyState
        . set_active_contract(
            world,
            {
                "contract_title": "Border Skirmish",
                "pay_gold": 100,
                "difficulty_rating": 1,
                "contract_type": "skirmish",
            }
        )
    )
    var paid: int = CompanyState.apply_contract_victory_pay(world)
    if paid != 100:
        _fail(failures, "Camp-1.4: first contract pay want 100 got %d" % paid)
    else:
        _pass()
    if CompanyState.get_gold(world) != gold_before + 100:
        _fail(failures, "Camp-1.4: gold should increase by contract pay on win")
    else:
        _pass()
    if CompanyState.get_renown(world) != 1:
        _fail(failures, "Camp-1.4: renown +1 after contract win")
    else:
        _pass()
    CompanyState.set_active_contract(world, {"pay_gold": 100, "contract_type": "skirmish"})
    CompanyState.set_renown(world, 2)
    var paid2: int = CompanyState.apply_contract_victory_pay(world)
    var want_scaled: int = int(round(100.0 * (1.0 + 2.0 * CompanyState.RENOWN_PAY_SCALE)))
    if paid2 != want_scaled:
        _fail(failures, "Camp-1.4: scaled pay want %d got %d" % [want_scaled, paid2])
    else:
        _pass()
    world.free()

    var world_loss: Node2D = _make_world(1)
    CompanyState.mark_tutorial_completed(world_loss)
    var g0: int = CompanyState.get_gold(world_loss)
    CompanyState.set_active_contract(world_loss, {"pay_gold": 200, "contract_type": "skirmish"})
    CompanyState.clear_active_contract(world_loss)
    if CompanyState.get_gold(world_loss) != g0:
        _fail(failures, "Camp-1.4: loss path (clear contract) must not grant pay")
    else:
        _pass()
    world_loss.free()

    var enc: Node2D = EncounterNode.new()
    enc.encounter_config = ContractSpawner.build_encounter_config(ContractSpawner.CONTRACT_TEMPLATES[0])
    var bridge_world: Node2D = _make_world(1)
    CampaignEncounterBridge.prepare_combat_from_encounter(bridge_world, enc)
    var active: Dictionary = CompanyState.get_active_contract(bridge_world)
    if str(active.get("contract_title", "")).is_empty():
        _fail(failures, "Camp-1.4: prepare_combat should stash active_contract")
    else:
        _pass()
    if int(active.get("pay_gold", -1)) != int(ContractSpawner.CONTRACT_TEMPLATES[0].get("pay_gold", 0)):
        _fail(failures, "Camp-1.4: active_contract pay_gold mismatch")
    else:
        _pass()
    bridge_world.free()
    enc.free()

    var label: String = ContractSpawner.format_marker_label(ContractSpawner.CONTRACT_TEMPLATES[0])
    if not label.contains("100") or not label.contains("*"):
        _fail(failures, "Camp-1.4: marker label should show pay and difficulty")
    else:
        _pass()
    var world_renown: Node2D = _make_world(1)
    CompanyState.set_renown(world_renown, 2)
    var scaled_lbl: String = ContractSpawner.format_marker_label(ContractSpawner.CONTRACT_TEMPLATES[0], world_renown)
    if not scaled_lbl.contains("renown"):
        _fail(failures, "Camp-1.4: marker should show renown-scaled pay hint")
    else:
        _pass()
    world_renown.free()

    var recap: String = (
        CompanyState
        . format_death_recap_suffix(
            {
                "part": "chest",
                "cause": "hemorrhage",
                "killer": "Goblin",
                "weapon": "Rusty sword",
            }
        )
    )
    if not recap.contains("Goblin") or not recap.contains("Rusty"):
        _fail(failures, "Camp-1.8: death recap should include killer and weapon")
    else:
        _pass()

    var kill_world: Node2D = _make_world(0, 1)
    CampaignEncounterBridge.record_battle_kill(kill_world, "Brother0", "Raider", "Axe", "head")
    CampaignEncounterBridge.build_last_battle_summary(kill_world)
    var deaths: Array = CompanyState.get_last_battle_summary(kill_world).get("deaths", [])
    if deaths.is_empty() or str((deaths[0] as Dictionary).get("killer", "")) != "Raider":
        _fail(failures, "Camp-1.8: battle kill log should merge into last_battle_summary")
    else:
        _pass()
    kill_world.free()

    var defeat_world: Node2D = _make_world(0, 1)
    CampaignEncounterBridge.record_battle_kill(defeat_world, "Brother0", "Raider", "Spear", "chest")
    CampaignEncounterBridge.build_last_battle_summary(defeat_world, "enemy")
    var loss_summary: Dictionary = CompanyState.get_last_battle_summary(defeat_world)
    if str(loss_summary.get("winner", "")) != "enemy":
        _fail(failures, "Camp-1.8: defeat summary should record battle winner")
    else:
        _pass()
    var loss_lines: PackedStringArray = CompanyState.format_last_battle_death_lines(defeat_world)
    if loss_lines.is_empty() or not str(loss_lines[0]).contains("Raider"):
        _fail(failures, "Camp-1.8: defeat death lines should include killer recap")
    else:
        _pass()
    defeat_world.free()

    var defeat_live: Node2D = _make_world(1)
    CampaignEncounterBridge.record_battle_kill(defeat_live, "Brother0", "Orc", "Axe", "head")
    CampaignEncounterBridge.build_last_battle_summary(defeat_live, "enemy")
    var live_deaths: Array = CompanyState.get_last_battle_summary(defeat_live).get("deaths", [])
    if live_deaths.is_empty() or str((live_deaths[0] as Dictionary).get("killer", "")) != "Orc":
        _fail(failures, "Camp-1.8: defeat should merge kill log when roster not yet is_dead")
    else:
        _pass()
    defeat_live.free()

    var tut_contract: Dictionary = {"tutorial": true, "contract_type": "tutorial"}
    if CompanyState.defeat_should_end_company_run(tut_contract):
        _fail(failures, "Camp-1.4: tutorial loss must not end company run")
    else:
        _pass()
    if not CompanyState.is_tutorial_contract({"contract_type": "tutorial"}):
        _fail(failures, "Camp-1.4: contract_type tutorial must count as tutorial contract")
    else:
        _pass()
    if not CompanyState.is_tutorial_contract({"tutorial": true}):
        _fail(failures, "Camp-1.4: tutorial flag alone must count as tutorial contract")
    else:
        _pass()
    if CompanyState.is_tutorial_contract({"pay_gold": 100, "contract_type": "skirmish"}):
        _fail(failures, "Camp-1.4: paid skirmish must not count as tutorial contract")
    else:
        _pass()
    var paid_contract: Dictionary = {"pay_gold": 100, "contract_type": "skirmish"}
    if not CompanyState.defeat_should_end_company_run(paid_contract):
        _fail(failures, "Camp-1.4: paid contract loss should end run (R3)")
    else:
        _pass()
    if not CompanyRunEndPanel.run_end_logs_reload("contract_failed"):
        _fail(failures, "Camp-5: paid contract loss should log reload=true")
    else:
        _pass()
    if not CompanyRunEndPanel.run_end_logs_reload("bankrupt"):
        _fail(failures, "Camp-5: bankrupt run-end should log reload=true")
    else:
        _pass()
    if CompanyRunEndPanel.run_end_logs_reload("tutorial_failed"):
        _fail(failures, "Camp-5: tutorial loss should log reload=false")
    else:
        _pass()
    if CompanyRunEndPanel.run_end_logs_reload("soft_defeat_resume"):
        _fail(failures, "Camp-5: soft defeat resume should log reload=false")
    else:
        _pass()
    var paid_detail: String = "Failed: Border Skirmish. The company cannot recover this contract."
    var paid_body: String = CompanyRunEndPanel.format_run_end_body("contract_failed", paid_detail)
    if not paid_body.contains("Border Skirmish") or not paid_body.contains("Restart reloads main"):
        _fail(
            failures,
            (
                "Camp-2.6: paid loss detail should append reload footnote got '%s'"
                % paid_body.substr(0, mini(160, paid_body.length()))
            )
        )
    else:
        _pass()
    var soft_body: String = CompanyRunEndPanel.format_run_end_body(
        "soft_defeat_resume", "Battle lost. Return to camp and recover."
    )
    if not soft_body.contains("autosave"):
        _fail(failures, "Camp-2.6: soft defeat detail should append autosave footnote got '%s'" % soft_body)
    else:
        _pass()
    var tut_body: String = CompanyRunEndPanel.format_run_end_body(
        "tutorial_failed", "Tutorial lost. You'll return to camp  -  try again when ready."
    )
    if tut_body.contains("Restart reloads") or tut_body.contains("autosave"):
        _fail(failures, "Camp-2.6: tutorial loss detail should not append reload footnote got '%s'" % tut_body)
    else:
        _pass()
    if CompanyRunEndPanel.format_run_end_button_label("contract_failed") != "Reload camp (autosave)":
        _fail(failures, "Camp-2.6: paid loss button should offer P2 reload label")
    else:
        _pass()
    if CompanyRunEndPanel.format_run_end_button_label("tutorial_failed") != "Return to camp":
        _fail(failures, "Camp-2.6: tutorial loss button should return to camp")
    else:
        _pass()
    var bankrupt_body: String = CompanyRunEndPanel.format_run_end_body("bankrupt")
    if not bankrupt_body.contains("desert") or not bankrupt_body.contains("Restart reloads main"):
        _fail(
            failures,
            (
                "Camp-2.6: bankrupt body should explain desertion + reload got '%s'"
                % bankrupt_body.substr(0, mini(160, bankrupt_body.length()))
            )
        )
    else:
        _pass()


# --- Camp-1.5 ---


static func _run_camp_1_3_settlement_tool_repair(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    var pm: Node = world.get_meta("party_manager")
    var ent: Node = _add_living_entity_member(pm, "Gear")
    if ent.has_method("get_wounded_parts"):
        ent.wounds["chest"] = [{"current_bleeding_rate": 0.1}]
    if not CompanyState.can_offer_settlement_tool_repair(world):
        _fail(failures, "Camp-1.3: should offer tool repair when wounded + tools")
    else:
        _pass()
    if not CompanyState.apply_settlement_tool_repair(world):
        _fail(failures, "Camp-1.3: tool repair should succeed")
    else:
        _pass()
    if CompanyState.get_tool_supplies(world) != 1:
        _fail(failures, "Camp-1.3: tool repair should consume 1 tool")
    else:
        _pass()
    world.free()


static func _run_camp_1_5_settlement_data(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    var pm: Node = world.get_meta("party_manager")
    _add_living_entity_member(pm, "Survivor")
    CampaignEncounterBridge.build_last_battle_summary(world)
    var summary: Dictionary = CompanyState.get_last_battle_summary(world)
    var members: Variant = summary.get("members", [])
    if not (members is Array) or (members as Array).is_empty():
        _fail(failures, "Camp-1.5: last_battle_summary should list living members")
    else:
        _pass()
    var entry: Dictionary = (members as Array)[0]
    var snap: Dictionary = entry.get("snapshot", {})
    if float(snap.get("blood_volume", -1)) < 0:
        _fail(failures, "Camp-1.5: snapshot missing blood_volume")
    else:
        _pass()
    world.free()


# --- Camp-1.6 ---


static func _run_camp_1_6_camp_heal(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(0, 0, true)
    var pm: Node = world.get_meta("party_manager")
    _add_living_entity_member(pm, "Wounded")
    _add_player_at_camp(world)
    CompanyState.set_medical_supplies(world, 0)
    if CompanyState.try_camp_heal(world):
        _fail(failures, "Camp-1.6: camp heal must fail at 0 med")
    else:
        _pass()
    CompanyState.set_medical_supplies(world, 2)
    var day_before_camp: int = CompanyState.get_day_index(world)
    var gold_before_camp: int = CompanyState.get_gold(world)
    if not CompanyState.try_camp_heal(world):
        _fail(failures, "Camp-1.6: camp heal should succeed on camp with med")
    else:
        _pass()
    if CompanyState.get_medical_supplies(world) != 1:
        _fail(failures, "Camp-1.6: camp heal should consume 1 med")
    else:
        _pass()
    if CompanyState.get_day_index(world) != day_before_camp + 1:
        _fail(
            failures,
            "Camp-1.6: camp heal should advance day %d -> %d" % [day_before_camp, CompanyState.get_day_index(world)]
        )
    else:
        _pass()
    var wage_bill: int = CompanyState.compute_next_wage_bill(world)
    if CompanyState.get_gold(world) != gold_before_camp - wage_bill:
        _fail(
            failures,
            (
                "Camp-1.6: camp heal should pay wages (gold %d want %d bill=%d)"
                % [CompanyState.get_gold(world), gold_before_camp - wage_bill, wage_bill]
            )
        )
    else:
        _pass()
    _free_harness_world(world)

    var world_menu: Node2D = _make_world(0, 0, true)
    var pm2: Node = world_menu.get_meta("party_manager")
    _add_living_entity_member(pm2, "Field")
    _add_player_at_camp(world_menu)
    world_menu.get_node("Character").position = Vector2(192, 192)
    CompanyState.set_medical_supplies(world_menu, 2)
    if not CompanyState.can_offer_camp_heal(world_menu, true):
        _fail(failures, "Camp-1.6: party menu camp heal should be offered (H3 both)")
    else:
        _pass()
    var day_menu_before: int = CompanyState.get_day_index(world_menu)
    if not CompanyState.try_camp_heal(world_menu, true):
        _fail(failures, "Camp-1.6: party menu camp heal should succeed off camp tile")
    else:
        _pass()
    if CompanyState.get_day_index(world_menu) != day_menu_before + 1:
        _fail(failures, "Camp-1.6: party menu camp heal should advance day")
    else:
        _pass()
    _free_harness_world(world_menu)

    var bleed_world: Node2D = _make_world(0, 0, true)
    var pm_b: Node = bleed_world.get_meta("party_manager")
    var wounded: Node = _add_living_entity_member(pm_b, "Bleeder")
    wounded.wounds["left_arm"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    CompanyState.set_medical_supplies(bleed_world, 2)
    if CompanyState.camp_heal_ready(bleed_world, true):
        _fail(failures, "Camp-1.6: camp_heal_ready must be false while untreated wounds remain")
    else:
        _pass()
    if CompanyState.try_camp_heal(bleed_world, true):
        _fail(failures, "Camp-1.6: camp heal must fail while untreated wounds remain")
    else:
        _pass()
    wounded.bandaged_parts["left_arm"] = true
    if not CompanyState.camp_heal_ready(bleed_world, true):
        _fail(failures, "Camp-1.6: camp_heal_ready should be true after wound dressed")
    else:
        _pass()
    if not CompanyState.try_camp_heal(bleed_world, true):
        _fail(failures, "Camp-1.6: camp heal should succeed after wound dressed")
    else:
        _pass()
    _free_harness_world(bleed_world)


# --- Camp-1.7 ---


static func _run_camp_1_7_renown_scaling(failures: PackedStringArray) -> void:
    var easy: Dictionary = ContractSpawner.CONTRACT_TEMPLATES[0]
    var hard: Dictionary = ContractSpawner.CONTRACT_TEMPLATES[1]
    var n_easy: int = int(easy.get("enemy_count", 0))
    var n_hard: int = int(hard.get("enemy_count", 0))
    if n_hard <= n_easy:
        _fail(failures, "Camp-1.7: escort enemy_count should exceed skirmish")
    else:
        _pass()
    if int(hard.get("pay_gold", 0)) <= int(easy.get("pay_gold", 0)):
        _fail(failures, "Camp-1.7: later template base pay should exceed first")
    else:
        _pass()
    var f_easy: Dictionary = ContractSpawner.build_enemy_formation_for_template(easy)
    var f_hard: Dictionary = ContractSpawner.build_enemy_formation_for_template(hard)
    var slots_easy: int = int(f_easy.get("files", 1)) * int(f_easy.get("ranks", 1))
    var slots_hard: int = int(f_hard.get("files", 1)) * int(f_hard.get("ranks", 1))
    if slots_hard <= slots_easy:
        _fail(failures, "Camp-1.7: harder contract formation slots want > easy (%d vs %d)" % [slots_hard, slots_easy])
    else:
        _pass()
    var world: Node2D = _make_world(1)
    CompanyState.set_renown(world, 4)
    var scaled: Dictionary = ContractSpawner.scale_template_for_renown(world, easy)
    if int(scaled.get("enemy_count", 0)) < int(easy.get("enemy_count", 0)) + 2:
        _fail(
            failures,
            (
                "Camp-1.7: renown=4 should add +2 enemies (got %d base %d)"
                % [scaled.get("enemy_count"), easy.get("enemy_count")]
            )
        )
    else:
        _pass()
    var tut: Dictionary = ContractSpawner.scale_template_for_renown(world, ContractSpawner.TUTORIAL_TEMPLATE)
    if int(tut.get("enemy_count", 0)) != int(ContractSpawner.TUTORIAL_TEMPLATE.get("enemy_count", 0)):
        _fail(failures, "Camp-1.7: tutorial enemy_count must not scale with renown")
    else:
        _pass()
    world.free()


# --- Camp-1.8 ---


static func _run_camp_1_8_roster_cleanup(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1, 1)
    var pm: Node = world.get_meta("party_manager")
    CampaignEncounterBridge.build_last_battle_summary(world)
    if pm.members.size() != 2:
        _fail(failures, "Camp-1.8: harness want 2 roster entries before cleanup")
    else:
        _pass()
    var lines: PackedStringArray = CompanyState.apply_casualty_cleanup(world)
    if lines.is_empty():
        _fail(failures, "Camp-1.8: memorial line expected for dead brother")
    else:
        _pass()
    if pm.members.size() != 1:
        _fail(failures, "Camp-1.8: dead brother removed from roster")
    else:
        _pass()
    var fightable: Array = CampaignEncounterBridge.get_fightable_party_nodes(world)
    if fightable.size() != 1:
        _fail(failures, "Camp-1.8: fightable roster want 1 got %d" % fightable.size())
    else:
        _pass()
    world.free()

# --- XCamp-3.1 hire ---
