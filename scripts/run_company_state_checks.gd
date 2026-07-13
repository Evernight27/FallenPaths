extends SceneTree

## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json` untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const _OperationalLog := preload("res://core/OperationalLog.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _MapBleedPolicy := preload("res://world/MapBleedPolicy.gd")
const _MapFieldCare := preload("res://world/MapFieldCare.gd")
const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _ContractSpawner := preload("res://world/ContractSpawner.gd")
const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _CoreEntityScript := preload("res://core/CoreEntity.gd")
const _CampaignWorldScript := preload("res://scripts/_harness_campaign_world.gd")
const HARNESS_NAME := "CompanyStateChecks"
const _CompanyHud := preload("res://ui/CompanyHud.gd")
const _CombatFlow := preload("res://world/CombatFlow.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _MgrScript := preload("res://combat/CombatManager.gd")
const _PartySetup := preload("res://world/PartySetup.gd")
const _PlayerCompanionSetup := preload("res://world/PlayerCompanionSetup.gd")
const _OverworldMap := preload("res://world/OverworldMap.gd")
const _CampaignAfflictions := preload("res://world/CampaignAfflictions.gd")
const _Persistence := preload("res://world/CampaignPersistence.gd")
const _HarnessFixtures := preload("res://harness/HarnessFixtures.gd")
const _EncounterSpawner := preload("res://world/EncounterSpawner.gd")
const _CompanyRunEndPanel := preload("res://ui/CompanyRunEndPanel.gd")
const _SettlementPanel := preload("res://ui/SettlementPanel.gd")

static var _test_count: int = 0


static func _new_party_manager() -> Node:
    return load("res://world/PartyManager.gd").new()


static func _new_party_menu() -> PopupPanel:
    return load("res://ui/PartyMenu.gd").new() as PopupPanel


static func _party_manager_script_ref() -> Script:
    return load("res://world/PartyManager.gd") as Script


static func _party_menu_script_ref() -> Script:
    return load("res://ui/PartyMenu.gd") as Script


func _init() -> void:
    CombatConstants.set_headless_harness_quiet(true)
    call_deferred("_run_harness")


func _run_harness() -> void:
    _OperationalLog.ensure_harness_error_logger()
    _Persistence.begin_harness_isolated_save()
    var failures: PackedStringArray = PackedStringArray()
    _run_camp_1_1_company_state(failures)
    _run_camp_1_2_wages_and_day(failures)
    _run_camp_1_3_supply_pools(failures)
    _run_camp_1_3_settlement_tool_repair(failures)
    _run_camp_1_4_contracts(failures)
    _run_camp_1_5_settlement_data(failures)
    _run_camp_1_6_camp_heal(failures)
    _run_camp_1_7_renown_scaling(failures)
    _run_camp_1_8_roster_cleanup(failures)
    _run_hire_rookie(failures)
    _run_overworld_map_5x5(failures)
    _run_contract_deck_refresh(failures)
    _run_xcamp_34_affliction_catalog(failures)
    _run_xcamp_35_camp_tavern_mood(failures)
    _run_xcamp_36_provisions(failures)
    _run_xcamp_37_burial_costs(failures)
    _run_xcamp_38_ms_camp_bridge(failures)
    _run_xcamp_39_mood_bias_to_ms(failures)
    _run_camp_2_bridge_spot_checks(failures)
    _run_camp_3_player_front_count_encounter(failures)
    _run_camp_5_ea_log_markers(failures)
    _run_persistence_roundtrip(failures)
    _cleanup_harness_tree_leaks()
    call_deferred("_finish_harness", failures)


func _finish_harness(failures: PackedStringArray):
    await process_frame
    _cleanup_harness_tree_leaks()
    _HarnessFixtures.flush_harness_live_nodes()
    var script_errors: int = _OperationalLog.harness_script_error_count()
    if script_errors > 0:
        _fail(failures, "Harness: %d SCRIPT_ERROR(s) during CompanyStateChecks (see FP_ERROR lines)" % script_errors)
    _Persistence.end_harness_isolated_save()
    if failures.is_empty():
        quit(_OperationalLog.harness_ok(HARNESS_NAME, "(%d tests)" % _test_count))
    else:
        quit(_OperationalLog.harness_fail(HARNESS_NAME, failures, "(%d tests)" % _test_count))


static func _fail(failures: PackedStringArray, msg: String) -> void:
    failures.append(msg)


static func _pass() -> void:
    _test_count += 1


static func _harness_root() -> Node:
    var loop: Variant = Engine.get_main_loop()
    if loop is SceneTree:
        return (loop as SceneTree).root
    return null


static func _release_harness_world(world: Node) -> void:
    if world == null or not is_instance_valid(world):
        return
    if world is Node2D and (world as Node2D).is_inside_tree():
        _free_harness_world(world)
    else:
        world.free()


static func _detach_and_free_meta_node(world: Node, meta_key: String) -> void:
    if world == null or not world.has_meta(meta_key):
        return
    var node_ref: Variant = world.get_meta(meta_key)
    world.remove_meta(meta_key)
    if typeof(node_ref) != TYPE_OBJECT or not is_instance_valid(node_ref):
        return
    var node: Node = node_ref as Node
    if node == null:
        return
    var node_parent: Node = node.get_parent()
    if node_parent != null:
        node_parent.remove_child(node)
    node.free()


static func _free_harness_world(world: Node) -> void:
    if world == null or not is_instance_valid(world):
        return
    _detach_and_free_meta_node(world, _CompanyState.WORLD_META_COMPANY_HUD)
    _detach_and_free_meta_node(world, "party_menu")
    var root: Node = _harness_root()
    if root != null:
        for layer in root.get_children():
            if layer.name != "UIOverlayLayer":
                continue
            for gc in layer.get_children().duplicate():
                if gc is Button and gc.name == "PartyButton":
                    layer.remove_child(gc)
                    gc.free()
    var parent: Node = world.get_parent()
    if parent != null:
        parent.remove_child(world)
    world.free()


static func _cleanup_harness_ui_overlay() -> void:
    var root: Node = _harness_root()
    if root == null:
        return
    for child in root.get_children():
        if child.name != "UIOverlayLayer":
            continue
        for gc in child.get_children():
            child.remove_child(gc)
            gc.free()
        root.remove_child(child)
        child.free()


static func _cleanup_harness_tree_leaks() -> void:
    var root: Node = _harness_root()
    if root == null:
        return
    for child in root.get_children().duplicate():
        if child is Node2D and child.get_script() == _CampaignWorldScript:
            _free_harness_world(child)
    _cleanup_harness_ui_overlay()


static func _make_world(living_count: int, dead_count: int = 0, in_tree: bool = false) -> Node2D:
    var world := Node2D.new()
    world.set_script(_CampaignWorldScript)
    var pm_script: Script = load("res://world/PartyManager.gd") as Script
    var pm: Node = pm_script.new()
    pm.name = "PartyManagerHarness"
    world.add_child(pm)
    for i in living_count + dead_count:
        var n := Node2D.new()
        n.name = "Brother%d" % i
        if i >= living_count:
            n.set_script(load("res://scripts/_harness_dead_stub.gd"))
        pm.add_child(n)
        pm.members.append({"name": n.name, "node_ref": n})
    world.set_meta("party_manager", pm)
    _CompanyState.init_from_defaults(world)
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    return world


static func _add_player_at_camp(world: Node2D) -> Node2D:
    var player := Node2D.new()
    player.name = "Character"
    player.position = Vector2(32, 32)
    world.add_child(player)
    return player


static func _add_living_entity_member(pm: Node, member_name: String) -> Node:
    var ent: Node = _harness_core_entity()
    ent.name = member_name
    ent.apply_species()
    pm.add_child(ent)
    (
        pm
        . members
        . append(
            {
                "name": member_name,
                "node_ref": ent,
                "company_mood": 50.0,
            }
        )
    )
    return ent


static func _harness_core_entity() -> Node:
    var ent: Node = _CoreEntityScript.new()
    _HarnessFixtures._track_harness_node(ent)
    return ent


static func _free_harness_core_entity(ent: Node) -> void:
    _HarnessFixtures._free_harness_node(ent)


# --- Camp-1.1 ---


static func _run_camp_1_1_company_state(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    var state: Dictionary = _CompanyState.get_state(world)
    if int(state.get("gold", -1)) != _CompanyState.DEFAULT_GOLD:
        _fail(failures, "Camp-1.1: gold want %d got %s" % [_CompanyState.DEFAULT_GOLD, state.get("gold")])
    else:
        _pass()
    if int(state.get("medical_supplies", -1)) != _CompanyState.DEFAULT_MEDICAL_SUPPLIES:
        _fail(
            failures,
            "Camp-1.1: med want %d got %s" % [_CompanyState.DEFAULT_MEDICAL_SUPPLIES, state.get("medical_supplies")]
        )
    else:
        _pass()
    if int(state.get("tool_supplies", -1)) != _CompanyState.DEFAULT_TOOL_SUPPLIES:
        _fail(
            failures,
            "Camp-1.1: tools want %d got %s" % [_CompanyState.DEFAULT_TOOL_SUPPLIES, state.get("tool_supplies")]
        )
    else:
        _pass()
    if int(state.get("food_supplies", -1)) != _CompanyState.DEFAULT_FOOD_SUPPLIES:
        _fail(
            failures,
            "Camp-1.1: food want %d got %s" % [_CompanyState.DEFAULT_FOOD_SUPPLIES, state.get("food_supplies")]
        )
    else:
        _pass()
    if int(state.get("renown", -1)) != _CompanyState.DEFAULT_RENOWN:
        _fail(failures, "Camp-1.1: renown want 0 got %s" % state.get("renown"))
    else:
        _pass()
    if bool(state.get("bankrupt", true)):
        _fail(failures, "Camp-1.1: bankrupt should start false")
    else:
        _pass()
    if _CompanyState.WORLD_META_COMPANY_STATE != "company_state":
        _fail(failures, "Camp-1.1: company_state meta key")
    else:
        _pass()
    _release_harness_world(world)

    var world_hud: Node2D = _make_world(1, 0, true)
    _CompanyState.attach_to_world(world_hud)
    if not world_hud.has_meta(_CompanyState.WORLD_META_COMPANY_HUD):
        _fail(failures, "Camp-1.1: attach_to_world should create company HUD meta")
    else:
        _pass()
    var hud: Control = world_hud.get_meta(_CompanyState.WORLD_META_COMPANY_HUD) as Control
    if hud == null or not hud.has_method("refresh_from_state"):
        _fail(failures, "Camp-1.1: company HUD missing refresh_from_state")
    else:
        _pass()
    var gold_after_encounter: int = _CompanyState.get_gold(world_hud)
    _CompanyState.add_gold(world_hud, 77)
    if _CompanyState.get_gold(world_hud) != gold_after_encounter + 77:
        _fail(failures, "Camp-1.1: gold should persist in company_state meta")
    else:
        _pass()
    if hud is _CompanyHud:
        var gold_lbl: Label = (hud as _CompanyHud)._gold_label
        if gold_lbl == null or not str(gold_lbl.text).contains(str(gold_after_encounter + 77)):
            _fail(failures, "Camp-1.1: HUD gold label want %d got '%s'" % [gold_after_encounter + 77, gold_lbl.text])
        else:
            _pass()
    _free_harness_world(world_hud)


# --- Camp-1.2 ---


static func _run_camp_1_2_wages_and_day(failures: PackedStringArray) -> void:
    if _CompanyState.read_stub_day_tick_mode() != "hybrid":
        _fail(failures, "Camp-1.2: day_tick_mode want hybrid")
    else:
        _pass()
    var world: Node2D = _make_world(2)
    var steps: int = _CompanyState.read_stub_steps_per_day()
    var bill: int = _CompanyState.compute_next_wage_bill(world)
    for _i in steps:
        _CompanyState.on_overworld_step(world)
    if _CompanyState.get_day_index(world) != 1:
        _fail(
            failures, "Camp-1.2: day_index want 1 got %d after %d steps" % [_CompanyState.get_day_index(world), steps]
        )
    else:
        _pass()
    var want_gold: int = _CompanyState.DEFAULT_GOLD - bill
    if _CompanyState.get_gold(world) != want_gold:
        _fail(
            failures,
            "Camp-1.2: gold want %d got %d (bill=%d living=2)" % [want_gold, _CompanyState.get_gold(world), bill]
        )
    else:
        _pass()
    if _CompanyState.get_overworld_step_count(world) != 0:
        _fail(failures, "Camp-1.2: step count should reset after day advance")
    else:
        _pass()
    _release_harness_world(world)

    var world_dead: Node2D = _make_world(1, 1)
    if _CompanyState.compute_next_wage_bill(world_dead) != _CompanyState.DEFAULT_WAGE_PER_MEMBER:
        _fail(failures, "Camp-1.2: dead brother excluded from wage bill")
    else:
        _pass()
    _release_harness_world(world_dead)

    var world_hybrid: Node2D = _make_world(1, 0, true)
    _add_player_at_camp(world_hybrid)
    world_hybrid.get_node("Character").position = Vector2(192, 192)
    if _CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day off camp should fail")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(160, 160)
    if _CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day still off camp at (2,2)")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(32, 32)
    var gold_before: int = _CompanyState.get_gold(world_hybrid)
    if not _CompanyState.request_end_day(world_hybrid):
        _fail(failures, "Camp-1.2: hybrid end_day on camp should succeed")
    else:
        _pass()
    if _CompanyState.get_gold(world_hybrid) != gold_before - _CompanyState.DEFAULT_WAGE_PER_MEMBER:
        _fail(failures, "Camp-1.2: end_day on camp should deduct one living wage")
    else:
        _pass()
    world_hybrid.get_node("Character").position = Vector2(192, 192)
    var off_camp_hint: String = _CompanyState.format_party_end_day_unavailable_hint(world_hybrid)
    if not off_camp_hint.contains("camp tile"):
        _fail(failures, "Camp-1.2: off-camp End day hint expected got '%s'" % off_camp_hint)
    else:
        _pass()
    _free_harness_world(world_hybrid)

    var hint_state: Dictionary = {
        "gold": 20,
        "wage_per_member": _CompanyState.DEFAULT_WAGE_PER_MEMBER,
    }
    if not _CompanyState.should_show_next_wage_hint(hint_state, 2):
        _fail(failures, "Camp-1.2: wage hint when gold below bill")
    else:
        _pass()
    hint_state["gold"] = 100
    if _CompanyState.should_show_next_wage_hint(hint_state, 2):
        _fail(failures, "Camp-1.2: no wage hint when gold sufficient")
    else:
        _pass()

    _OperationalLog.begin_play_session("headless://camp_wage_warn", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var wage_world: Node2D = _make_world(2, 0, true)
    _CompanyState.set_gold(wage_world, 10)
    _CompanyState.try_advance_day(wage_world)
    var wage_warn_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_wages: gold=") and s.contains("below next wage bill="):
            wage_warn_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not wage_warn_logged:
        _fail(failures, "Camp-5: try_advance_day should log company_wages warn when gold below bill")
    else:
        _pass()
    _release_harness_world(wage_world)

    _OperationalLog.begin_play_session("headless://camp_desertion_summary", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var desertion_logged: bool = false
    for seed_try in range(4000):
        seed(seed_try)
        _OperationalLog.clear_capture()
        var des_world: Node2D = _make_world(2)
        var pm_des: Node = des_world.get_meta("party_manager")
        for raw in pm_des.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 12.0
        _CompanyState._run_daily_desertion_pass(des_world)
        for line in _OperationalLog.get_captured_lines():
            var s: String = str(line)
            if s.contains("desertion summary=") and s.contains("(mood="):
                desertion_logged = true
                break
        _release_harness_world(des_world)
        if desertion_logged:
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not desertion_logged:
        _fail(failures, "Camp-5: desertion summary should log name(mood=N) under desertion pass")
    else:
        _pass()
    var risk_world: Node2D = _make_world(2)
    var pm_risk: Node = risk_world.get_meta("party_manager")
    for raw in pm_risk.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 10.0
    if _CompanyState.count_desertion_risk_roster(risk_world) < 1:
        _fail(
            failures,
            "Camp-5: desertion risk count want >= 1 got %d" % _CompanyState.count_desertion_risk_roster(risk_world)
        )
    else:
        _pass()
    var risk_footer: String = _CompanyState.format_party_desertion_risk_footer(risk_world)
    if not risk_footer.contains("desertion"):
        _fail(failures, "Camp-5: desertion risk footer expected got '%s'" % risk_footer)
    else:
        _pass()
    var menu_footer: String = _CompanyState.format_party_menu_footer(risk_world)
    if not menu_footer.contains("desertion"):
        _fail(failures, "Camp-5: party menu footer should include desertion got '%s'" % menu_footer)
    else:
        _pass()
    _release_harness_world(risk_world)


# --- Camp-1.3 ---


static func _run_camp_1_3_supply_pools(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    if not _CompanyState.consume_medical(world, 1):
        _fail(failures, "Camp-1.3: consume_medical should succeed")
    else:
        _pass()
    if _CompanyState.get_medical_supplies(world) != _CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1:
        _fail(
            failures,
            (
                "Camp-1.3: med supplies want %d got %d"
                % [_CompanyState.DEFAULT_MEDICAL_SUPPLIES - 1, _CompanyState.get_medical_supplies(world)]
            )
        )
    else:
        _pass()
    if _CompanyState.consume_medical(world, 99):
        _fail(failures, "Camp-1.3: consume_medical should fail when insufficient")
    else:
        _pass()
    if not _CompanyState.consume_tool(world, 1):
        _fail(failures, "Camp-1.3: consume_tool should succeed")
    else:
        _pass()
    if _CompanyState.get_tool_supplies(world) != 1:
        _fail(failures, "Camp-1.3: tool supplies want 1 got %d" % _CompanyState.get_tool_supplies(world))
    else:
        _pass()
    if _CompanyState.consume_tool(world, 5):
        _fail(failures, "Camp-1.3: consume_tool should fail when insufficient")
    else:
        _pass()
    world.free()


# --- Camp-1.4 ---


static func _run_camp_1_4_contracts(failures: PackedStringArray) -> void:
    if _CompanyState.read_stub_persistence_mode() != "P2":
        _fail(failures, "Camp-5: persistence gate want P2 (single-slot autosave)")
    else:
        _pass()
    if not _CompanyState.persistence_uses_disk_autosave():
        _fail(failures, "Camp-5: persistence_uses_disk_autosave should be true for P2")
    else:
        _pass()
    if not _CompanyState.persistence_restore_on_main_restart():
        _fail(failures, "Camp-5: P2 testing should restore autosave on main restart")
    else:
        _pass()
    if _CompanyState.persistence_clear_slot_on_run_end_reload():
        _fail(failures, "Camp-5: P2 testing should keep slot on run-end reload")
    else:
        _pass()
    if not _CompanyState.P2_RESTORE_ON_MAIN_RESTART:
        _fail(failures, "Camp-5: P2_RESTORE_ON_MAIN_RESTART should be true for testing")
    else:
        _pass()
    if not _CompanyState.can_offer_new_campaign_from_menu():
        _fail(failures, "Camp-5: new company wipe should be offered during P2 testing")
    else:
        _pass()
    var wage_world: Node2D = _make_world(2)
    _CompanyState.set_gold(wage_world, 5)
    var wage_hint: String = _CompanyState.format_next_wage_hint(_CompanyState.get_state(wage_world), 2)
    if not wage_hint.contains("short") or not wage_hint.contains("mood"):
        _fail(failures, "Camp-5: wage hint should note shortfall + mood got '%s'" % wage_hint)
    else:
        _pass()
    var debt_hint: String = _CompanyState.format_next_wage_hint(
        {"gold": -20, "wage_per_member": _CompanyState.DEFAULT_WAGE_PER_MEMBER}, 2
    )
    if not debt_hint.contains("desertion"):
        _fail(failures, "Camp-5: wage hint in debt should cite desertion got '%s'" % debt_hint)
    else:
        _pass()
    var end_day_lbl: String = _CompanyState.format_end_day_button_label(wage_world)
    if not end_day_lbl.contains("wages short"):
        _fail(failures, "Camp-2.6: End day button should warn when wages short got '%s'" % end_day_lbl)
    else:
        _pass()
    if (
        _CompanyState.format_wages_short_log(10, 30)
        != ("Wages short  -  paid what you could; mood fell (gold 10, bill 30).")
    ):
        _fail(failures, "Camp-2.6: wages short log shape drift")
    else:
        _pass()
    if not _CompanyState.format_company_debt_log(-25).contains("desert"):
        _fail(failures, "Camp-2.6: debt log should mention desertion")
    else:
        _pass()
    var wage_suffix: String = _CompanyState.format_hud_wage_suffix(wage_world)
    if not wage_suffix.contains("wages short"):
        _fail(failures, "Camp-2.6: Party title wage suffix when short got '%s'" % wage_suffix)
    else:
        _pass()
    _release_harness_world(wage_world)
    var debt_suffix_world: Node2D = _make_world(2)
    _CompanyState.set_gold(debt_suffix_world, 5)
    _CompanyState.try_advance_day(debt_suffix_world)
    if _CompanyState.get_gold(debt_suffix_world) >= 0:
        _fail(failures, "Camp-2.6: debt suffix harness needs negative gold after wage tick")
    else:
        _pass()
    var debt_suffix: String = _CompanyState.format_hud_wage_suffix(debt_suffix_world)
    if not debt_suffix.contains("wage debt"):
        _fail(failures, "Camp-2.6: Party title wage suffix in debt got '%s'" % debt_suffix)
    else:
        _pass()
    var camp_lbl: String = _CompanyState.format_camp_rest_button_label(debt_suffix_world, true)
    if not camp_lbl.contains("wage debt"):
        _fail(failures, "Camp-2.6: Camp rest button should warn wage debt got '%s'" % camp_lbl)
    else:
        _pass()
    _release_harness_world(debt_suffix_world)
    if (
        _CompanyRunEndPanel.format_company_run_end_log("contract_failed")
        != ("company_run_end reason=contract_failed reload=true clears_slot=false")
    ):
        _fail(failures, "Camp-5: run-end log should keep slot during P2 testing restore")
    else:
        _pass()
    if _CompanyState.read_stub_encounter_lifecycle() != "r3_loss_ends_run":
        _fail(failures, "Camp-1.4: encounter lifecycle want r3_loss_ends_run")
    else:
        _pass()
    if not _CompanyState.contract_loss_ends_run():
        _fail(failures, "Camp-1.4: contract_loss_ends_run should be true")
    else:
        _pass()
    if _ContractSpawner.get_template_count() < 2:
        _fail(failures, "Camp-1.4: need >= 2 contract templates")
    else:
        _pass()

    var world: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(world)
    var gold_before: int = _CompanyState.get_gold(world)
    (
        _CompanyState
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
    var paid: int = _CompanyState.apply_contract_victory_pay(world)
    if paid != 100:
        _fail(failures, "Camp-1.4: first contract pay want 100 got %d" % paid)
    else:
        _pass()
    if _CompanyState.get_gold(world) != gold_before + 100:
        _fail(failures, "Camp-1.4: gold should increase by contract pay on win")
    else:
        _pass()
    if _CompanyState.get_renown(world) != 1:
        _fail(failures, "Camp-1.4: renown +1 after contract win")
    else:
        _pass()
    _CompanyState.set_active_contract(world, {"pay_gold": 100, "contract_type": "skirmish"})
    _CompanyState.set_renown(world, 2)
    var paid2: int = _CompanyState.apply_contract_victory_pay(world)
    var want_scaled: int = int(round(100.0 * (1.0 + 2.0 * _CompanyState.RENOWN_PAY_SCALE)))
    if paid2 != want_scaled:
        _fail(failures, "Camp-1.4: scaled pay want %d got %d" % [want_scaled, paid2])
    else:
        _pass()
    world.free()

    var world_loss: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(world_loss)
    var g0: int = _CompanyState.get_gold(world_loss)
    _CompanyState.set_active_contract(world_loss, {"pay_gold": 200, "contract_type": "skirmish"})
    _CompanyState.clear_active_contract(world_loss)
    if _CompanyState.get_gold(world_loss) != g0:
        _fail(failures, "Camp-1.4: loss path (clear contract) must not grant pay")
    else:
        _pass()
    world_loss.free()

    var enc: Node2D = _EncounterNodeScript.new()
    enc.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
    var bridge_world: Node2D = _make_world(1)
    _CampaignBridge.prepare_combat_from_encounter(bridge_world, enc)
    var active: Dictionary = _CompanyState.get_active_contract(bridge_world)
    if str(active.get("contract_title", "")).is_empty():
        _fail(failures, "Camp-1.4: prepare_combat should stash active_contract")
    else:
        _pass()
    if int(active.get("pay_gold", -1)) != int(_ContractSpawner.CONTRACT_TEMPLATES[0].get("pay_gold", 0)):
        _fail(failures, "Camp-1.4: active_contract pay_gold mismatch")
    else:
        _pass()
    bridge_world.free()
    enc.free()

    var label: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[0])
    if not label.contains("100") or not label.contains("*"):
        _fail(failures, "Camp-1.4: marker label should show pay and difficulty")
    else:
        _pass()
    var world_renown: Node2D = _make_world(1)
    _CompanyState.set_renown(world_renown, 2)
    var scaled_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[0], world_renown)
    if not scaled_lbl.contains("renown"):
        _fail(failures, "Camp-1.4: marker should show renown-scaled pay hint")
    else:
        _pass()
    world_renown.free()

    var recap: String = (
        _CompanyState
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
    _CampaignBridge.record_battle_kill(kill_world, "Brother0", "Raider", "Axe", "head")
    _CampaignBridge.build_last_battle_summary(kill_world)
    var deaths: Array = _CompanyState.get_last_battle_summary(kill_world).get("deaths", [])
    if deaths.is_empty() or str((deaths[0] as Dictionary).get("killer", "")) != "Raider":
        _fail(failures, "Camp-1.8: battle kill log should merge into last_battle_summary")
    else:
        _pass()
    kill_world.free()

    var defeat_world: Node2D = _make_world(0, 1)
    _CampaignBridge.record_battle_kill(defeat_world, "Brother0", "Raider", "Spear", "chest")
    _CampaignBridge.build_last_battle_summary(defeat_world, "enemy")
    var loss_summary: Dictionary = _CompanyState.get_last_battle_summary(defeat_world)
    if str(loss_summary.get("winner", "")) != "enemy":
        _fail(failures, "Camp-1.8: defeat summary should record battle winner")
    else:
        _pass()
    var loss_lines: PackedStringArray = _CompanyState.format_last_battle_death_lines(defeat_world)
    if loss_lines.is_empty() or not str(loss_lines[0]).contains("Raider"):
        _fail(failures, "Camp-1.8: defeat death lines should include killer recap")
    else:
        _pass()
    defeat_world.free()

    var defeat_live: Node2D = _make_world(1)
    _CampaignBridge.record_battle_kill(defeat_live, "Brother0", "Orc", "Axe", "head")
    _CampaignBridge.build_last_battle_summary(defeat_live, "enemy")
    var live_deaths: Array = _CompanyState.get_last_battle_summary(defeat_live).get("deaths", [])
    if live_deaths.is_empty() or str((live_deaths[0] as Dictionary).get("killer", "")) != "Orc":
        _fail(failures, "Camp-1.8: defeat should merge kill log when roster not yet is_dead")
    else:
        _pass()
    defeat_live.free()

    var tut_contract: Dictionary = {"tutorial": true, "contract_type": "tutorial"}
    if _CompanyState.defeat_should_end_company_run(tut_contract):
        _fail(failures, "Camp-1.4: tutorial loss must not end company run")
    else:
        _pass()
    if not _CompanyState.is_tutorial_contract({"contract_type": "tutorial"}):
        _fail(failures, "Camp-1.4: contract_type tutorial must count as tutorial contract")
    else:
        _pass()
    if not _CompanyState.is_tutorial_contract({"tutorial": true}):
        _fail(failures, "Camp-1.4: tutorial flag alone must count as tutorial contract")
    else:
        _pass()
    if _CompanyState.is_tutorial_contract({"pay_gold": 100, "contract_type": "skirmish"}):
        _fail(failures, "Camp-1.4: paid skirmish must not count as tutorial contract")
    else:
        _pass()
    var paid_contract: Dictionary = {"pay_gold": 100, "contract_type": "skirmish"}
    if not _CompanyState.defeat_should_end_company_run(paid_contract):
        _fail(failures, "Camp-1.4: paid contract loss should end run (R3)")
    else:
        _pass()
    if not _CompanyRunEndPanel.run_end_logs_reload("contract_failed"):
        _fail(failures, "Camp-5: paid contract loss should log reload=true")
    else:
        _pass()
    if not _CompanyRunEndPanel.run_end_logs_reload("bankrupt"):
        _fail(failures, "Camp-5: bankrupt run-end should log reload=true")
    else:
        _pass()
    if _CompanyRunEndPanel.run_end_logs_reload("tutorial_failed"):
        _fail(failures, "Camp-5: tutorial loss should log reload=false")
    else:
        _pass()
    if _CompanyRunEndPanel.run_end_logs_reload("soft_defeat_resume"):
        _fail(failures, "Camp-5: soft defeat resume should log reload=false")
    else:
        _pass()
    var paid_detail: String = "Failed: Border Skirmish. The company cannot recover this contract."
    var paid_body: String = _CompanyRunEndPanel.format_run_end_body("contract_failed", paid_detail)
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
    var soft_body: String = _CompanyRunEndPanel.format_run_end_body(
        "soft_defeat_resume", "Battle lost. Return to camp and recover."
    )
    if not soft_body.contains("autosave"):
        _fail(failures, "Camp-2.6: soft defeat detail should append autosave footnote got '%s'" % soft_body)
    else:
        _pass()
    var tut_body: String = _CompanyRunEndPanel.format_run_end_body(
        "tutorial_failed", "Tutorial lost. You'll return to camp  -  try again when ready."
    )
    if tut_body.contains("Restart reloads") or tut_body.contains("autosave"):
        _fail(failures, "Camp-2.6: tutorial loss detail should not append reload footnote got '%s'" % tut_body)
    else:
        _pass()
    if _CompanyRunEndPanel.format_run_end_button_label("contract_failed") != "Reload camp (autosave)":
        _fail(failures, "Camp-2.6: paid loss button should offer P2 reload label")
    else:
        _pass()
    if _CompanyRunEndPanel.format_run_end_button_label("tutorial_failed") != "Return to camp":
        _fail(failures, "Camp-2.6: tutorial loss button should return to camp")
    else:
        _pass()
    var bankrupt_body: String = _CompanyRunEndPanel.format_run_end_body("bankrupt")
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
    if not _CompanyState.can_offer_settlement_tool_repair(world):
        _fail(failures, "Camp-1.3: should offer tool repair when wounded + tools")
    else:
        _pass()
    if not _CompanyState.apply_settlement_tool_repair(world):
        _fail(failures, "Camp-1.3: tool repair should succeed")
    else:
        _pass()
    if _CompanyState.get_tool_supplies(world) != 1:
        _fail(failures, "Camp-1.3: tool repair should consume 1 tool")
    else:
        _pass()
    world.free()


static func _run_camp_1_5_settlement_data(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    var pm: Node = world.get_meta("party_manager")
    _add_living_entity_member(pm, "Survivor")
    _CampaignBridge.build_last_battle_summary(world)
    var summary: Dictionary = _CompanyState.get_last_battle_summary(world)
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
    _CompanyState.set_medical_supplies(world, 0)
    if _CompanyState.try_camp_heal(world):
        _fail(failures, "Camp-1.6: camp heal must fail at 0 med")
    else:
        _pass()
    _CompanyState.set_medical_supplies(world, 2)
    var day_before_camp: int = _CompanyState.get_day_index(world)
    var gold_before_camp: int = _CompanyState.get_gold(world)
    if not _CompanyState.try_camp_heal(world):
        _fail(failures, "Camp-1.6: camp heal should succeed on camp with med")
    else:
        _pass()
    if _CompanyState.get_medical_supplies(world) != 1:
        _fail(failures, "Camp-1.6: camp heal should consume 1 med")
    else:
        _pass()
    if _CompanyState.get_day_index(world) != day_before_camp + 1:
        _fail(
            failures,
            "Camp-1.6: camp heal should advance day %d -> %d" % [day_before_camp, _CompanyState.get_day_index(world)]
        )
    else:
        _pass()
    var wage_bill: int = _CompanyState.compute_next_wage_bill(world)
    if _CompanyState.get_gold(world) != gold_before_camp - wage_bill:
        _fail(
            failures,
            (
                "Camp-1.6: camp heal should pay wages (gold %d want %d bill=%d)"
                % [_CompanyState.get_gold(world), gold_before_camp - wage_bill, wage_bill]
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
    _CompanyState.set_medical_supplies(world_menu, 2)
    if not _CompanyState.can_offer_camp_heal(world_menu, true):
        _fail(failures, "Camp-1.6: party menu camp heal should be offered (H3 both)")
    else:
        _pass()
    var day_menu_before: int = _CompanyState.get_day_index(world_menu)
    if not _CompanyState.try_camp_heal(world_menu, true):
        _fail(failures, "Camp-1.6: party menu camp heal should succeed off camp tile")
    else:
        _pass()
    if _CompanyState.get_day_index(world_menu) != day_menu_before + 1:
        _fail(failures, "Camp-1.6: party menu camp heal should advance day")
    else:
        _pass()
    _free_harness_world(world_menu)

    var bleed_world: Node2D = _make_world(0, 0, true)
    var pm_b: Node = bleed_world.get_meta("party_manager")
    var wounded: Node = _add_living_entity_member(pm_b, "Bleeder")
    wounded.wounds["left_arm"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    _CompanyState.set_medical_supplies(bleed_world, 2)
    if _CompanyState.camp_heal_ready(bleed_world, true):
        _fail(failures, "Camp-1.6: camp_heal_ready must be false while untreated wounds remain")
    else:
        _pass()
    if _CompanyState.try_camp_heal(bleed_world, true):
        _fail(failures, "Camp-1.6: camp heal must fail while untreated wounds remain")
    else:
        _pass()
    wounded.bandaged_parts["left_arm"] = true
    if not _CompanyState.camp_heal_ready(bleed_world, true):
        _fail(failures, "Camp-1.6: camp_heal_ready should be true after wound dressed")
    else:
        _pass()
    if not _CompanyState.try_camp_heal(bleed_world, true):
        _fail(failures, "Camp-1.6: camp heal should succeed after wound dressed")
    else:
        _pass()
    _free_harness_world(bleed_world)


# --- Camp-1.7 ---


static func _run_camp_1_7_renown_scaling(failures: PackedStringArray) -> void:
    var easy: Dictionary = _ContractSpawner.CONTRACT_TEMPLATES[0]
    var hard: Dictionary = _ContractSpawner.CONTRACT_TEMPLATES[1]
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
    var f_easy: Dictionary = _ContractSpawner.build_enemy_formation_for_template(easy)
    var f_hard: Dictionary = _ContractSpawner.build_enemy_formation_for_template(hard)
    var slots_easy: int = int(f_easy.get("files", 1)) * int(f_easy.get("ranks", 1))
    var slots_hard: int = int(f_hard.get("files", 1)) * int(f_hard.get("ranks", 1))
    if slots_hard <= slots_easy:
        _fail(failures, "Camp-1.7: harder contract formation slots want > easy (%d vs %d)" % [slots_hard, slots_easy])
    else:
        _pass()
    var world: Node2D = _make_world(1)
    _CompanyState.set_renown(world, 4)
    var scaled: Dictionary = _ContractSpawner.scale_template_for_renown(world, easy)
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
    var tut: Dictionary = _ContractSpawner.scale_template_for_renown(world, _ContractSpawner.TUTORIAL_TEMPLATE)
    if int(tut.get("enemy_count", 0)) != int(_ContractSpawner.TUTORIAL_TEMPLATE.get("enemy_count", 0)):
        _fail(failures, "Camp-1.7: tutorial enemy_count must not scale with renown")
    else:
        _pass()
    world.free()


# --- Camp-1.8 ---


static func _run_camp_1_8_roster_cleanup(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1, 1)
    var pm: Node = world.get_meta("party_manager")
    _CampaignBridge.build_last_battle_summary(world)
    if pm.members.size() != 2:
        _fail(failures, "Camp-1.8: harness want 2 roster entries before cleanup")
    else:
        _pass()
    var lines: PackedStringArray = _CompanyState.apply_casualty_cleanup(world)
    if lines.is_empty():
        _fail(failures, "Camp-1.8: memorial line expected for dead brother")
    else:
        _pass()
    if pm.members.size() != 1:
        _fail(failures, "Camp-1.8: dead brother removed from roster")
    else:
        _pass()
    var fightable: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if fightable.size() != 1:
        _fail(failures, "Camp-1.8: fightable roster want 1 got %d" % fightable.size())
    else:
        _pass()
    world.free()


# --- XCamp-3.1 hire ---


static func _instantiate_main_hire_world(in_tree: bool = false) -> Node2D:
    var packed: PackedScene = load("res://main.tscn") as PackedScene
    var world: Node2D = packed.instantiate() as Node2D
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 4242
    _PlayerCompanionSetup.setup_player_and_companion(world, rng)
    _PartySetup.setup_party(world)
    return world


static func _trim_party_to_leader(world: Node2D) -> void:
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null or not pm.has_method("remove_member_by_name"):
        return
    for i in range(1, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP):
        var suffix: String = "Companion" + ("" if i == 1 else str(i))
        pm.remove_member_by_name(suffix)


static func _run_hire_rookie(failures: PackedStringArray) -> void:
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    if _CompanyState.count_living_roster(world) != 1:
        _fail(failures, "XCamp-3.1: trimmed roster want 1 living got %d" % _CompanyState.count_living_roster(world))
    else:
        _pass()
    if _PartySetup.find_vacant_companion_node(world) == null:
        _fail(failures, "XCamp-3.1: vacant companion slot expected after trim")
    else:
        _pass()
    _CompanyState.set_gold(world, _CompanyState.HIRE_GOLD_COST + 50)
    var rng := RandomNumberGenerator.new()
    rng.seed = 99
    if not _CompanyState.try_hire_rookie(world, rng, true):
        _fail(failures, "XCamp-3.1: hire should succeed from Party menu with gold and vacant slot")
    else:
        _pass()
    if _CompanyState.count_living_roster(world) != 2:
        _fail(failures, "XCamp-3.1: roster after hire want 2 living got %d" % _CompanyState.count_living_roster(world))
    else:
        _pass()
    if _CompanyState.get_gold(world) != 50:
        _fail(failures, "XCamp-3.1: gold after hire want 50 got %d" % _CompanyState.get_gold(world))
    else:
        _pass()
    var pm: Node = world.get_meta("party_manager")
    var hired_in_roster: bool = false
    for member in pm.members:
        if member is Dictionary and str((member as Dictionary).get("name", "")) == "Companion":
            hired_in_roster = true
            break
    if not hired_in_roster:
        _fail(failures, "XCamp-3.1: hired Companion should appear in party roster")
    else:
        _pass()
    if not _CompanyState.roster_has_hire_room(world):
        _fail(failures, "XCamp-3.1: roster should still have hire room after one replacement")
    else:
        _pass()
    if _PartySetup.find_vacant_companion_node(world) == null:
        _fail(failures, "XCamp-3.1: additional vacant companion slots expected after one hire")
    else:
        _pass()
    _CompanyState.set_gold(world, 0)
    if _CompanyState.can_offer_hire(world, true):
        _fail(failures, "XCamp-3.1: broke company should not offer hire")
    else:
        _pass()
    var broke_reason: String = _CompanyState.format_hire_block_reason(world, true)
    if not broke_reason.contains("need"):
        _fail(failures, "XCamp-3.1: broke hire reason should mention gold got '%s'" % broke_reason)
    else:
        _pass()
    var full_world: Node2D = _instantiate_main_hire_world(true)
    if _CompanyState.count_living_roster(full_world) != _CompanyState.ROSTER_MAX_LIVING:
        _fail(
            failures,
            (
                "XCamp-3.1: full roster want %d living got %d"
                % [_CompanyState.ROSTER_MAX_LIVING, _CompanyState.count_living_roster(full_world)]
            )
        )
    else:
        _pass()
    if _CompanyState.can_offer_hire(full_world, true):
        _fail(failures, "XCamp-3.1: full roster should block hire")
    else:
        _pass()
    _free_harness_world(full_world)
    _free_harness_world(world)

    _Persistence.clear_slot()
    var persist_world: Node2D = _instantiate_main_hire_world(true)
    var pm_persist: Node = persist_world.get_meta("party_manager")
    for trim_i in range(2, 7):
        pm_persist.remove_member_by_name("Companion" + str(trim_i))
    _CompanyState.set_gold(persist_world, 500)
    var persist_rng := RandomNumberGenerator.new()
    persist_rng.seed = 77
    if not _CompanyState.try_hire_rookie(persist_world, persist_rng, true):
        _fail(failures, "XCamp-3.1 P2: hire before save should succeed")
    else:
        _pass()
    if not _Persistence.save_slot(persist_world):
        _fail(failures, "XCamp-3.1 P2: save_slot after hire failed")
    else:
        _pass()
    var hire_loaded: Dictionary = _Persistence.load_save()
    var hire_roster: Variant = hire_loaded.get("roster", [])
    if hire_roster is not Array or (hire_roster as Array).size() != 3:
        _fail(
            failures,
            (
                "XCamp-3.1 P2: save roster want 3 got %s"
                % str((hire_roster as Array).size() if hire_roster is Array else hire_roster)
            )
        )
    else:
        _pass()
    var fresh_hire: Node2D = _instantiate_main_hire_world(true)
    var restore_rng := RandomNumberGenerator.new()
    restore_rng.seed = 1
    _Persistence.apply_save(fresh_hire, hire_loaded, restore_rng, null)
    if _CompanyState.count_living_roster(fresh_hire) != 3:
        _fail(failures, "XCamp-3.1 P2: restore living want 3 got %d" % _CompanyState.count_living_roster(fresh_hire))
    else:
        _pass()
    _Persistence.clear_slot()
    _free_harness_world(persist_world)
    _free_harness_world(fresh_hire)


# --- XCamp-3.2 overworld map ---


static func _make_overworld_spawn_world(in_tree: bool = false) -> Node2D:
    var world := Node2D.new()
    world.set_script(_CampaignWorldScript)
    _OverworldMap.stamp_world_map_size(world)
    var pm_script: Script = load("res://world/PartyManager.gd") as Script
    var pm: Node = pm_script.new()
    pm.name = "PartyManagerHarness"
    world.add_child(pm)
    var brother: Node = _harness_core_entity()
    brother.name = "Brother0"
    brother.apply_species()
    pm.add_child(brother)
    pm.members.append({"name": brother.name, "node_ref": brother, "company_mood": 50.0})
    world.set_meta("party_manager", pm)
    _CompanyState.init_from_defaults(world)
    var player := Node2D.new()
    player.name = "Character"
    player.position = _OverworldMap.tile_center(_CompanyState.DEFAULT_CAMP_TILE)
    world.add_child(player)
    if in_tree:
        var root: Node = _harness_root()
        if root != null:
            root.add_child(world)
    return world


static func _count_encounter_markers(world: Node2D) -> int:
    var n: int = 0
    for child in world.get_children():
        if child.get_script() == _EncounterNodeScript:
            n += 1
    return n


static func _run_overworld_map_5x5(failures: PackedStringArray) -> void:
    if _OverworldMap.MAP_TILES != 5:
        _fail(failures, "XCamp-3.2: MAP_TILES want 5 got %d" % _OverworldMap.MAP_TILES)
    else:
        _pass()
    if _OverworldMap.all_tiles().size() != 25:
        _fail(failures, "XCamp-3.2: all_tiles want 25 got %d" % _OverworldMap.all_tiles().size())
    else:
        _pass()
    if not _OverworldMap.is_tile_in_bounds(Vector2i(4, 4)):
        _fail(failures, "XCamp-3.2: tile (4,4) should be in bounds")
    else:
        _pass()
    if _OverworldMap.is_tile_in_bounds(Vector2i(5, 0)):
        _fail(failures, "XCamp-3.2: tile (5,0) should be out of bounds")
    else:
        _pass()
    var spawn_world: Node2D = _make_overworld_spawn_world(true)
    _CompanyState.attach_to_world(spawn_world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 5151
    _ContractSpawner.spawn_campaign_contracts(spawn_world, rng, null)
    var markers: int = _count_encounter_markers(spawn_world)
    var want_markers: int = 1 + _ContractSpawner.get_template_count()
    if markers != want_markers:
        _fail(failures, "XCamp-3.2: contract markers want %d (tutorial + paid) got %d" % [want_markers, markers])
    else:
        _pass()
    var markers_ok: bool = true
    for child in spawn_world.get_children():
        if child.get_script() != _EncounterNodeScript:
            continue
        var tile: Vector2i = spawn_world.call("_tile_coords", child.position) as Vector2i
        if not _OverworldMap.is_tile_in_bounds(tile, spawn_world):
            _fail(failures, "XCamp-3.2: marker tile OOB %s" % tile)
            markers_ok = false
            break
        if tile == _ContractSpawner.CAMP_TILE:
            _fail(failures, "XCamp-3.2: contract should not spawn on camp tile")
            markers_ok = false
            break
    if markers_ok:
        _pass()
    _Persistence.clear_slot()
    _CompanyState.set_gold(spawn_world, 888)
    spawn_world.get_node("Character").position = _OverworldMap.tile_center(Vector2i(3, 2))
    if not _Persistence.save_slot(spawn_world):
        _fail(failures, "XCamp-3.2 P2: save on 5- - 5 map failed")
    else:
        _pass()
    var map_loaded: Dictionary = _Persistence.load_save()
    var player_tile: Variant = map_loaded.get("player_tile", [])
    if (
        player_tile is not Array
        or (player_tile as Array).size() < 2
        or int((player_tile as Array)[0]) != 3
        or int((player_tile as Array)[1]) != 2
    ):
        _fail(failures, "XCamp-3.2 P2: player_tile want [3,2] got %s" % player_tile)
    else:
        _pass()
    var fresh_map: Node2D = _make_overworld_spawn_world(true)
    _CompanyState.attach_to_world(fresh_map)
    _Persistence.apply_save(fresh_map, map_loaded, rng, null)
    var restored_pos: Vector2 = fresh_map.get_node("Character").position
    var restored_tile: Vector2i = fresh_map.call("_tile_coords", restored_pos) as Vector2i
    if restored_tile != Vector2i(3, 2):
        _fail(failures, "XCamp-3.2 P2: restored player tile want (3,2) got %s" % restored_tile)
    else:
        _pass()
    if _count_encounter_markers(fresh_map) != want_markers:
        _fail(
            failures,
            (
                "XCamp-3.2 P2: restored encounter count want %d got %d"
                % [want_markers, _count_encounter_markers(fresh_map)]
            )
        )
    else:
        _pass()
    _Persistence.clear_slot()
    _free_harness_world(spawn_world)
    _free_harness_world(fresh_map)


static func _clear_paid_contract_markers(world: Node2D) -> void:
    if world == null:
        return
    for child in world.get_children().duplicate():
        if child.get_script() != _EncounterNodeScript:
            continue
        if str(child.marker_kind) == "contract":
            child.free()


static func _run_contract_deck_refresh(failures: PackedStringArray) -> void:
    var world: Node2D = _make_overworld_spawn_world(true)
    var pm: Node = _new_party_manager()
    world.add_child(pm)
    world.set_meta("party_manager", pm)
    _add_living_entity_member(pm, "DeckBro")
    _CompanyState.attach_to_world(world)
    _CompanyState.mark_tutorial_completed(world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 3333
    _ContractSpawner.spawn_campaign_contracts(world, rng, null)
    if _ContractSpawner.count_paid_contract_markers(world) != _ContractSpawner.get_template_count():
        _fail(
            failures,
            (
                "XCamp-3.3: initial paid markers want %d got %d"
                % [
                    _ContractSpawner.get_template_count(),
                    _ContractSpawner.count_paid_contract_markers(world),
                ]
            )
        )
    else:
        _pass()
    if _ContractSpawner.try_refresh_contract_deck(world, null) != 0:
        _fail(failures, "XCamp-3.3: refresh should not run while paid markers remain")
    else:
        _pass()
    _clear_paid_contract_markers(world)
    if _ContractSpawner.count_paid_contract_markers(world) != 0:
        _fail(failures, "XCamp-3.3: harness should clear paid markers")
    else:
        _pass()
    var deck_hint: String = _ContractSpawner.format_settlement_deck_refresh_hint(world)
    if not deck_hint.contains("new jobs"):
        _fail(failures, "XCamp-3.3: deck refresh hint expected got '%s'" % deck_hint)
    else:
        _pass()
    var placed: int = _ContractSpawner.try_refresh_contract_deck(world, null)
    if placed != _ContractSpawner.get_template_count():
        _fail(
            failures, "XCamp-3.3: deck refresh want %d placed got %d" % [_ContractSpawner.get_template_count(), placed]
        )
    else:
        _pass()
    if _CompanyState.get_contract_deck_index(world) != 1:
        _fail(failures, "XCamp-3.3: contract_deck_index want 1 got %d" % _CompanyState.get_contract_deck_index(world))
    else:
        _pass()
    if _ContractSpawner.try_refresh_contract_deck(world, null) != 0:
        _fail(failures, "XCamp-3.3: second refresh should not run until wave cleared")
    else:
        _pass()
    _Persistence.clear_slot()
    if not _Persistence.save_slot(world):
        _fail(failures, "XCamp-3.3 P2: save with deck_index failed")
    else:
        _pass()
    var deck_loaded: Dictionary = _Persistence.load_save()
    var deck_state: Variant = deck_loaded.get("company_state", {})
    if deck_state is not Dictionary or int((deck_state as Dictionary).get("contract_deck_index", 0)) != 1:
        _fail(failures, "XCamp-3.3 P2: contract_deck_index not saved got %s" % deck_state)
    else:
        _pass()
    _Persistence.clear_slot()
    _free_harness_world(world)


static func _run_xcamp_34_affliction_catalog(failures: PackedStringArray) -> void:
    if _CampaignAfflictions.CATALOG_IDS.size() < 6:
        _fail(failures, "XCamp-3.4: affliction catalog want >= 6 ids")
    else:
        _pass()
    var lung: Dictionary = _CampaignAfflictions.catalog_def(_CampaignAfflictions.AFFLICTION_PARTLY_COLLAPSED_LUNG)
    if float(lung.get("stamina_mult", 1.0)) > 0.86:
        _fail(failures, "XCamp-3.4: collapsed lung stamina debuff expected")
    else:
        _pass()
    var grip: Dictionary = _CampaignAfflictions.catalog_def(_CampaignAfflictions.AFFLICTION_SHAKY_GRIP, "right_arm")
    if str(grip.get("label", "")) != "Shaky grip":
        _fail(failures, "XCamp-3.4: shaky grip label")
    else:
        _pass()
    var scar_line: String = _CampaignAfflictions.format_scar_line("Brother", lung)
    if not scar_line.contains("Stamina"):
        _fail(failures, "XCamp-3.4: scar line should include stamina effect got '%s'" % scar_line)
    else:
        _pass()
    var ent: Node = _harness_core_entity()
    ent.apply_species()
    if _CampaignAfflictions._bone_affliction_id("left_arm") != _CampaignAfflictions.AFFLICTION_SHAKY_GRIP:
        _fail(failures, "XCamp-3.4: crippled arm should map to shaky_grip")
    else:
        _pass()
    if _CampaignAfflictions._bone_affliction_id("left_leg") != _CampaignAfflictions.AFFLICTION_LIMPING_LIMB:
        _fail(failures, "XCamp-3.4: crippled leg should map to limping_limb")
    else:
        _pass()
    if _CampaignAfflictions._bone_affliction_id("chest") != _CampaignAfflictions.AFFLICTION_CRACKED_RIBS:
        _fail(failures, "XCamp-3.4: crippled chest should map to cracked_ribs")
    else:
        _pass()
    if not ent.add_campaign_affliction(lung):
        _fail(failures, "XCamp-3.4: should add catalog affliction")
    else:
        _pass()
    if ent.add_campaign_affliction(lung):
        _fail(failures, "XCamp-3.4: duplicate affliction id should be rejected")
    else:
        _pass()
    var aff_world: Node2D = _make_world(1, 0, true)
    _CompanyState.attach_to_world(aff_world)
    var pm: Node = aff_world.get_meta("party_manager")
    var bro: Node = _add_living_entity_member(pm, "ScarBro")
    bro.add_campaign_affliction(_CampaignAfflictions.catalog_def(_CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE))
    if _CampaignAfflictions.count_scarred_brothers(aff_world) != 1:
        _fail(
            failures,
            "XCamp-3.4: count_scarred_brothers want 1 got %d" % _CampaignAfflictions.count_scarred_brothers(aff_world)
        )
    else:
        _pass()
    _Persistence.clear_slot()
    if not _Persistence.save_slot(aff_world):
        _fail(failures, "XCamp-3.4 P2: save with afflictions failed")
    else:
        _pass()
    var loaded: Dictionary = _Persistence.load_save()
    var roster: Variant = loaded.get("roster", [])
    var saved_aff: Variant = null
    if roster is Array:
        for raw_entry in roster as Array:
            if raw_entry is not Dictionary:
                continue
            if str((raw_entry as Dictionary).get("name", "")) != "ScarBro":
                continue
            var entity_data: Variant = (raw_entry as Dictionary).get("entity", {})
            if entity_data is Dictionary:
                saved_aff = (entity_data as Dictionary).get("campaign_afflictions", [])
            break
    if saved_aff is not Array or (saved_aff as Array).is_empty():
        _fail(failures, "XCamp-3.4 P2: campaign_afflictions not in save")
    else:
        _pass()
    _Persistence.clear_slot()
    _free_harness_core_entity(ent)
    _release_harness_world(aff_world)


static func _run_xcamp_35_camp_tavern_mood(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(0, 0, true)
    _CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var bro_a: Node = _add_living_entity_member(pm, "TavernA")
    var bro_b: Node = _add_living_entity_member(pm, "TavernB")
    pm.members[0]["company_mood"] = 49.0
    pm.members[1]["company_mood"] = 50.0
    _add_player_at_camp(world)
    _CompanyState.set_medical_supplies(world, 2)
    if not _CompanyState.try_camp_heal(world, true):
        _fail(failures, "XCamp-3.5: camp rest should succeed for tavern mood test")
    else:
        _pass()
    var mood_a: float = float(pm.members[0].get("company_mood", 49.0))
    var mood_b: float = float(pm.members[1].get("company_mood", 50.0))
    if not is_equal_approx(mood_a, 50.0):
        _fail(failures, "XCamp-3.5: camp rest mood want 50.0 got %.2f" % mood_a)
    else:
        _pass()
    if not is_equal_approx(mood_b, 51.0):
        _fail(failures, "XCamp-3.5: camp rest mood want 51.0 got %.2f" % mood_b)
    else:
        _pass()
    var label: String = _CompanyState.format_camp_rest_button_label(world, true)
    if not label.contains("+1 mood"):
        _fail(failures, "XCamp-3.5: camp rest label should mention mood got '%s'" % label)
    else:
        _pass()
    _release_harness_world(world)


static func _run_xcamp_36_provisions(failures: PackedStringArray) -> void:
    var fed_world: Node2D = _make_world(2)
    _CompanyState.attach_to_world(fed_world)
    _CompanyState.set_food_supplies(fed_world, 2)
    var pm_fed: Node = fed_world.get_meta("party_manager")
    for raw in pm_fed.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 50.0
    if not _CompanyState.try_advance_day(fed_world):
        _fail(failures, "XCamp-3.6: try_advance_day should succeed")
    else:
        _pass()
    if _CompanyState.get_food_supplies(fed_world) != 0:
        _fail(
            failures, "XCamp-3.6: fed roster should consume 2 food got %d" % _CompanyState.get_food_supplies(fed_world)
        )
    else:
        _pass()
    var fed_mood: float = float(pm_fed.members[0].get("company_mood", 50.0))
    if not is_equal_approx(fed_mood, 50.0):
        _fail(failures, "XCamp-3.6: fed roster mood should stay 50 got %.2f" % fed_mood)
    else:
        _pass()
    _release_harness_world(fed_world)

    var short_world: Node2D = _make_world(2)
    _CompanyState.attach_to_world(short_world)
    _CompanyState.set_food_supplies(short_world, 1)
    var pm_short: Node = short_world.get_meta("party_manager")
    for raw in pm_short.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 50.0
    if not _CompanyState.try_advance_day(short_world):
        _fail(failures, "XCamp-3.6: day tick with short food should still advance day")
    else:
        _pass()
    if _CompanyState.get_food_supplies(short_world) != 0:
        _fail(failures, "XCamp-3.6: short food should consume remaining rations")
    else:
        _pass()
    var short_mood: float = float(pm_short.members[0].get("company_mood", 50.0))
    if not is_equal_approx(short_mood, 49.0):
        _fail(failures, "XCamp-3.6: not fed mood want 49 got %.2f" % short_mood)
    else:
        _pass()
    var prov_end_world: Node2D = _make_world(2)
    _CompanyState.attach_to_world(prov_end_world)
    _CompanyState.set_food_supplies(prov_end_world, 0)
    var prov_end_lbl: String = _CompanyState.format_end_day_button_label(prov_end_world)
    if not prov_end_lbl.contains("rations short"):
        _fail(failures, "XCamp-3.6: End day button should warn when rations short got '%s'" % prov_end_lbl)
    else:
        _pass()
    var prov_camp_world: Node2D = _make_world(2)
    _CompanyState.attach_to_world(prov_camp_world)
    _CompanyState.set_food_supplies(prov_camp_world, 0)
    var prov_camp_lbl: String = _CompanyState.format_camp_rest_button_label(prov_camp_world, true)
    if not prov_camp_lbl.contains("rations short"):
        _fail(failures, "XCamp-3.6: Camp rest button should warn when rations short got '%s'" % prov_camp_lbl)
    else:
        _pass()
    var prov_hud_suffix: String = _CompanyState.format_hud_provisions_suffix(prov_camp_world)
    if not prov_hud_suffix.contains("rations short"):
        _fail(failures, "XCamp-3.6: Party title provisions suffix expected got '%s'" % prov_hud_suffix)
    else:
        _pass()
    var prov_hud_hints: PackedStringArray = _CompanyState.format_hud_economy_hint_lines(
        _CompanyState.get_state(prov_camp_world), 2, prov_camp_world
    )
    if prov_hud_hints.is_empty() or not str(prov_hud_hints[0]).contains("rations"):
        _fail(failures, "XCamp-3.6: HUD economy hint should include rations got %s" % str(prov_hud_hints))
    else:
        _pass()
    _release_harness_world(prov_camp_world)
    _Persistence.clear_slot()
    _CompanyState.set_food_supplies(short_world, 7)
    if not _Persistence.save_slot(short_world):
        _fail(failures, "XCamp-3.6 P2: save with food failed")
    else:
        _pass()
    var loaded: Dictionary = _Persistence.load_save()
    var food_state: Variant = (loaded.get("company_state", {}) as Dictionary).get("food_supplies", -1)
    if int(food_state) != 7:
        _fail(failures, "XCamp-3.6 P2: food_supplies want 7 got %s" % str(food_state))
    else:
        _pass()
    _Persistence.clear_slot()
    _release_harness_world(short_world)


static func _run_xcamp_37_burial_costs(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    _CompanyState.set_gold(world, 100)
    (
        world
        . set_meta(
            _CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {"deaths": [{"name": "Brother0", "part": "chest", "cause": "exsanguination"}]},
        )
    )
    var lines: PackedStringArray = _CompanyState.apply_settlement_burial_costs(world)
    if _CompanyState.get_gold(world) != 100 - _CompanyState.BURIAL_GOLD_COST:
        _fail(
            failures,
            (
                "XCamp-3.7: burial cost want gold %d got %d"
                % [
                    100 - _CompanyState.BURIAL_GOLD_COST,
                    _CompanyState.get_gold(world),
                ]
            )
        )
    else:
        _pass()
    if lines.is_empty() or not str(lines[0]).contains("Burial"):
        _fail(failures, "XCamp-3.7: burial line expected got %s" % str(lines))
    else:
        _pass()
    if _CompanyState.compute_settlement_burial_cost(world) != _CompanyState.BURIAL_GOLD_COST:
        _fail(
            failures,
            (
                "XCamp-3.7: compute_settlement_burial_cost want %d got %d"
                % [_CompanyState.BURIAL_GOLD_COST, _CompanyState.compute_settlement_burial_cost(world)]
            )
        )
    else:
        _pass()
    var debt_preview_world: Node2D = _make_world(1)
    _CompanyState.set_gold(debt_preview_world, 10)
    (
        debt_preview_world
        . set_meta(
            _CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {"deaths": [{"name": "Brother0", "part": "chest", "cause": "exsanguination"}]},
        )
    )
    var debt_warn: String = _CompanyState.format_settlement_burial_debt_warning(debt_preview_world)
    if not debt_warn.contains("Burial") or not debt_warn.contains("debt"):
        _fail(failures, "XCamp-3.7: burial debt warning expected got '%s'" % debt_warn)
    else:
        _pass()
    _release_harness_world(debt_preview_world)
    var no_death_world: Node2D = _make_world(1)
    _CompanyState.set_gold(no_death_world, 50)
    no_death_world.set_meta(_CompanyState.WORLD_META_LAST_BATTLE_SUMMARY, {"deaths": []})
    if not _CompanyState.apply_settlement_burial_costs(no_death_world).is_empty():
        _fail(failures, "XCamp-3.7: no deaths should not charge burial")
    else:
        _pass()
    if _CompanyState.get_gold(no_death_world) != 50:
        _fail(failures, "XCamp-3.7: gold should be unchanged without deaths")
    else:
        _pass()
    _release_harness_world(world)
    _release_harness_world(no_death_world)


static func _run_xcamp_38_ms_camp_bridge(failures: PackedStringArray) -> void:
    if _CompanyState.stance_preference_for_campaign_mood(10.0) != preload("res://combat/CombatWeaponForm.gd").FORM_WALL:
        _fail(failures, "XCamp-3.8: low mood should map to wall")
    else:
        _pass()
    if (
        _CompanyState.stance_preference_for_campaign_mood(80.0)
        != preload("res://combat/CombatWeaponForm.gd").FORM_WRATH
    ):
        _fail(failures, "XCamp-3.8: high mood should map to wrath")
    else:
        _pass()
    if (
        _CompanyState.stance_preference_for_campaign_mood(50.0)
        != preload("res://combat/CombatWeaponForm.gd").FORM_BALANCED
    ):
        _fail(failures, "XCamp-3.8: mid mood should map to balanced")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    var pm: Node = world.get_meta("party_manager")
    var char_script: Script = load("res://character.gd") as Script
    var fighter := CharacterBody2D.new()
    fighter.set_script(char_script)
    fighter.name = "MoodFighter"
    pm.add_child(fighter)
    pm.members[0]["node_ref"] = fighter
    pm.members[0]["company_mood"] = 12.0
    _CampaignBridge.apply_campaign_mood_stance_preferences(world)
    if str(fighter.get("stance_preference")) != preload("res://combat/CombatWeaponForm.gd").FORM_WALL:
        _fail(
            failures,
            "XCamp-3.8: bridge should stamp wall for angry mood got '%s'" % str(fighter.get("stance_preference"))
        )
    else:
        _pass()
    fighter.set("stance_preference", "fool")
    pm.members[0]["company_mood"] = 12.0
    _CampaignBridge.apply_campaign_mood_stance_preferences(world)
    if str(fighter.get("stance_preference")) != "fool":
        _fail(failures, "XCamp-3.8: explicit stance_preference should not be overwritten")
    else:
        _pass()
    var stance_hint: String = _CompanyState.format_settlement_low_mood_stance_hint(world)
    if not stance_hint.contains("wall"):
        _fail(failures, "XCamp-3.8: low mood settlement hint expected got '%s'" % stance_hint)
    else:
        _pass()
    _release_harness_world(world)


## XCamp-3.9: campaign mood bias -> mental stack weight multipliers via bridge meta.
static func _run_xcamp_39_mood_bias_to_ms(failures: PackedStringArray) -> void:
    var _MoodBias := preload("res://combat/CombatCampaignMoodBias.gd")
    # Basic multiplier boundaries: low mood (<=25) -> defensive bias, high mood (>=70) -> aggressive bias.
    if _MoodBias.wait_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should increase wait weight above 1.0")
    else:
        _pass()
    if _MoodBias.wait_action_weight_mult(25.0) != 1.0:
        _fail(failures, "XCamp-3.9: mood=25 should be neutral for wait (1.0)")
    else:
        _pass()
    if _MoodBias.wait_action_weight_mult(70.0) < 1.0 or _MoodBias.wait_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should be neutral for wait (1.0)")
    else:
        _pass()
    if _MoodBias.offense_action_weight_mult(0.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should damp offense below 1.0")
    else:
        _pass()
    if _MoodBias.offense_action_weight_mult(25.0) != 1.0:
        _fail(failures, "XCamp-3.9: mood=25 should be neutral for offense (1.0)")
    else:
        _pass()
    if _MoodBias.offense_action_weight_mult(70.0) <= 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should boost offense above 1.0")
    else:
        _pass()
    if _MoodBias.focus_line_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost focus above 1.0")
    else:
        _pass()
    if _MoodBias.focus_line_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp focus below 1.0")
    else:
        _pass()
    if _MoodBias.flee_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost flee above 1.0")
    else:
        _pass()
    if _MoodBias.flee_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp flee below 1.0")
    else:
        _pass()
    if _MoodBias.disengage_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost disengage above 1.0")
    else:
        _pass()
    if _MoodBias.disengage_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp disengage below 1.0")
    else:
        _pass()
    # Batch compute returns all multipliers.
    var batch: Dictionary = _MoodBias.compute_all_multipliers(50.0)
    if not batch.has("wait_mult") or not batch.has("offense_mult"):
        _fail(failures, "XCamp-3.9: compute_all_multipliers should return wait_mult and offense_mult")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1})
    var pm: Node = world.get_meta("party_manager")
    var char_script := load("res://character.gd") as Script
    var fighter := CharacterBody2D.new()
    fighter.set_script(char_script)
    fighter.name = "MoodBiasFighter"
    pm.add_child(fighter)
    pm.members[0]["node_ref"] = fighter
    pm.members[0]["company_mood"] = 15.0
    _CampaignBridge.apply_campaign_mood_bias_to_encounter(world)
    var enc: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if not enc.has(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER):
        _fail(failures, "XCamp-3.9: encounter meta should have mood bias key")
    else:
        _pass()
    var biased_val: float = float(enc.get(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER, 50.0))
    if biased_val > 20.0:
        _fail(failures, "XCamp-3.9: mood bias should reflect low roster mood (~=15) got %.1f" % biased_val)
    else:
        _pass()
    pm.members[0]["company_mood"] = 85.0
    _CampaignBridge.apply_campaign_mood_bias_to_encounter(world)
    var enc2: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var high_val: float = float(enc2.get(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER, 50.0))
    if high_val < 80.0:
        _fail(failures, "XCamp-3.9: mood bias should reflect high roster mood (~=85) got %.1f" % high_val)
    else:
        _pass()
    # Enemy side: default 50.0 when no enemy_mood_bias in encounter config.
    var world2: Node2D = _make_world(1)
    world2.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1})
    _CampaignBridge.apply_campaign_mood_bias_to_encounter(world2)
    var enc3: Dictionary = world2.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_default: float = float(enc3.get(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_default != 50.0:
        _fail(failures, "XCamp-3.9: enemy mood bias default should be 50.0 (neutral), got %.1f" % enemy_default)
    else:
        _pass()
    # Enemy side: explicit enemy_mood_bias from encounter config.
    var world3: Node2D = _make_world(1)
    world3.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1, "enemy_mood_bias": 10.0})
    _CampaignBridge.apply_campaign_mood_bias_to_encounter(world3)
    var enc4: Dictionary = world3.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_low: float = float(enc4.get(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_low < 5.0 or enemy_low > 15.0:
        _fail(failures, "XCamp-3.9: enemy mood bias should reflect encounter config (~=10), got %.1f" % enemy_low)
    else:
        _pass()
    # Enemy side: clamp at 100 boundary.
    var world4: Node2D = _make_world(1)
    world4.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1, "enemy_mood_bias": 200.0})
    _CampaignBridge.apply_campaign_mood_bias_to_encounter(world4)
    var enc5: Dictionary = world4.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_clamped: float = float(enc5.get(_MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_clamped != 100.0:
        _fail(failures, "XCamp-3.9: enemy mood bias should clamp at 100 (got %.1f)" % enemy_clamped)
    else:
        _pass()
    _release_harness_world(world2)
    _release_harness_world(world3)
    _release_harness_world(world4)


# --- Camp-2+ (spot checks; full gates in combat harness) ---


static func _run_camp_2_bridge_spot_checks(failures: PackedStringArray) -> void:
    if _CompanyState.read_stub_map_bleed_policy() != "warn_eta":
        _fail(failures, "Camp-2.1: map_bleed policy want warn_eta")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    if _MapBleedPolicy.effective_policy(world) != _MapBleedPolicy.POLICY_BLOCK:
        _fail(failures, "Camp-2.1: tutorial incomplete should block")
    else:
        _pass()
    world.set_meta(_CompanyState.WORLD_META_MAP_BLEED_MULT, 0.25)
    _CampaignBridge.clear_transient_combat_meta(world)
    if world.has_meta(_CompanyState.WORLD_META_MAP_BLEED_MULT):
        _fail(failures, "Camp-2.1: map_bleed_mult should clear after combat")
    else:
        _pass()
    _CompanyState.mark_tutorial_completed(world)
    if _MapBleedPolicy.effective_policy(world) != _MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: post-tutorial map bleed policy want warn_eta")
    else:
        _pass()
    world.set_meta("active_contract", {"tutorial": true, "pay_gold": 0})
    if _CompanyState.apply_contract_victory_pay(world) != 0:
        _fail(failures, "Camp-3.1: tutorial pay want 0")
    else:
        _pass()
    var world_paid: Node2D = _make_world(1)
    _CompanyState.set_active_contract(
        world_paid, {"contract_title": "Escort", "pay_gold": 120, "contract_type": "escort"}
    )
    if _CompanyState.apply_contract_victory_pay(world_paid) != 120:
        _fail(failures, "Camp-2.1: paid contract pay want 120")
    else:
        _pass()
    if not _CompanyState.is_tutorial_completed(world_paid):
        _fail(failures, "Camp-2.1: paid contract win should lift map bleed block")
    else:
        _pass()
    if _MapBleedPolicy.effective_policy(world_paid) != _MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: after paid win map bleed policy want warn_eta")
    else:
        _pass()
    world.free()
    world_paid.free()
    var world_win: Node2D = _make_world(1)
    if _CompanyState.is_tutorial_completed(world_win):
        _fail(failures, "Camp-2.1: fresh world should start pre-first-win")
    else:
        _pass()
    _CampaignBridge.on_return_from_combat(world_win, "player")
    if not _CompanyState.is_tutorial_completed(world_win):
        _fail(failures, "Camp-2.1: on_return_from_combat(player) should lift map bleed block")
    else:
        _pass()
    if _MapBleedPolicy.effective_policy(world_win) != _MapBleedPolicy.POLICY_WARN_ETA:
        _fail(failures, "Camp-2.1: after combat return policy want warn_eta")
    else:
        _pass()
    world_win.free()

    var snap: Dictionary = {"name": "T", "blood_volume": 55.0, "total_bleeding_rate": 1.2}
    var entry: Dictionary = _CampaignBridge.member_battle_summary_entry(snap, null)
    if int(entry.get("worst_atls_band", 0)) < 2:
        _fail(failures, "Camp-2.2: worst_atls_band for 55%% blood")
    else:
        _pass()
    var bleed_ent: Node = _harness_core_entity()
    bleed_ent.apply_species()
    bleed_ent.wounds["left_arm"] = [
        {"current_bleeding_rate": 1.0, "is_arterial": false, "severity": "moderate"},
    ]
    var bleed_snap: Dictionary = {"name": "Bleeder", "blood_volume": 80.0, "total_bleeding_rate": 1.0}
    var bleed_entry: Dictionary = _CampaignBridge.member_battle_summary_entry(bleed_snap, bleed_ent)
    var snap_entry: Dictionary = bleed_entry.get("snapshot", {})
    if snap_entry is Dictionary and (snap_entry.get("untreated_parts", []) as PackedStringArray).size() > 0:
        _pass()
    else:
        _fail(failures, "Camp-2.2: battle snapshot should carry untreated_parts when present")
    _free_harness_core_entity(bleed_ent)

    var entity: Node = _harness_core_entity()
    entity.intelligence = 100
    entity.set_campaign_supply_factor(0.5)
    if absf(entity.get_medical_effectiveness() - 0.5) > 0.02:
        _fail(failures, "Camp-2.3: supply factor at 0 med floor")
    else:
        _pass()
    _free_harness_core_entity(entity)

    var world_med: Node2D = _make_world(1)
    _CompanyState.set_medical_supplies(world_med, 0)
    _CompanyState.wire_party_medical_supply(world_med)
    var hint: String = _CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint.contains("efficacy"):
        _fail(failures, "Camp-2.3: depleted med should produce supply hint")
    else:
        _pass()
    _CompanyState.set_medical_supplies(world_med, 1)
    _CompanyState.wire_party_medical_supply(world_med)
    var hint_one: String = _CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint_one.contains("One med left"):
        _fail(failures, "Camp-2.3: 1 med left should warn about next spend got '%s'" % hint_one)
    else:
        _pass()
    _CompanyState.set_medical_supplies(world_med, 3)
    _CompanyState.wire_party_medical_supply(world_med)
    var hint_tight: String = _CompanyState.format_battle_medical_supply_hint(world_med)
    if not hint_tight.contains("tight"):
        _fail(failures, "Camp-2.3: low med pool should warn about map dressings got '%s'" % hint_tight)
    else:
        _pass()
    world_med.free()

    var pre_stab: Node = _harness_core_entity()
    pre_stab.apply_species()
    pre_stab.wounds["chest"] = [
        {"current_bleeding_rate": 2.0, "is_arterial": true, "severity": "severe"},
    ]
    if _EntityMedical.can_apply_stabilize(pre_stab, "chest"):
        _fail(failures, "Camp-2.5: stabilize should require pressure first")
    else:
        _pass()
    _free_harness_core_entity(pre_stab)

    seed(90210)
    var stab_ent: Node = _harness_core_entity()
    stab_ent.apply_species()
    stab_ent.wounds["chest"] = [{"current_bleeding_rate": 0.8, "is_arterial": true, "severity": "severe"}]
    if not stab_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure on chest")
    else:
        _pass()
    if not stab_ent.can_apply_stabilize("chest"):
        _fail(failures, "Camp-2.5: should offer stabilize under pressure with bleed")
    else:
        _pass()
    if not stab_ent.apply_stabilize("chest", 2.0):
        _fail(failures, "Camp-2.5: apply_stabilize should succeed")
    else:
        _pass()
    if bool(stab_ent.bandaged_parts.get("chest", false)):
        _fail(failures, "Camp-2.5: stabilize must not set bandaged_parts")
    else:
        _pass()
    _free_harness_core_entity(stab_ent)

    seed(90210)
    var press_ent: Node = _harness_core_entity()
    press_ent.apply_species()
    press_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.6, "severity": "moderate"},
    ]
    if not press_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure for bandage failure retain")
    else:
        _pass()
    if not _EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
        _fail(failures, "Camp-2.5: want pressure held before bandage attempt")
    else:
        _pass()
    if press_ent.apply_bandage("chest", 0.0):
        _fail(failures, "Camp-2.5: zero-eff bandage should fail for pressure-retain test")
    else:
        _pass()
    if not _EntityMedical.has_direct_pressure_on_part(press_ent, "chest"):
        _fail(failures, "Camp-2.5: failed bandage must retain direct pressure for retry")
    else:
        _pass()
    _free_harness_core_entity(press_ent)

    seed(90210)
    var pack_ent: Node = _harness_core_entity()
    pack_ent.apply_species()
    pack_ent.linen_strips_remaining = 4
    pack_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    if not pack_ent.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.5: setup pressure for packing failure retain")
    else:
        _pass()
    if not pack_ent.apply_packing("chest", 0.0):
        _pass()
    else:
        _fail(failures, "Camp-2.5: zero-eff packing should fail for pressure-retain test")
    if not _EntityMedical.has_direct_pressure_on_part(pack_ent, "chest"):
        _fail(failures, "Camp-2.5: failed packing must retain direct pressure for retry")
    else:
        _pass()
    _free_harness_core_entity(pack_ent)

    var pain_ent: Node = _harness_core_entity()
    pain_ent.apply_species()
    if not pain_ent.add_campaign_affliction({"id": "old_wound_ache", "pain_mult": 1.1, "stamina_mult": 1.0}):
        _fail(failures, "Camp-2.4: pain affliction add")
    else:
        _pass()
    if absf(pain_ent.get_campaign_pain_mult() - 1.1) > 0.02:
        _fail(failures, "Camp-2.4: pain_mult want 1.1 got %.3f" % pain_ent.get_campaign_pain_mult())
    else:
        _pass()
    var aff_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "Scar", "node_ref": pain_ent})
    if not str(aff_snap.get("affliction_effects", "")).contains("Pain"):
        _fail(failures, "Camp-2.4: snapshot should expose affliction effect line")
    else:
        _pass()
    _free_harness_core_entity(pain_ent)

    var day_world: Node2D = _make_world(1)
    var day_line: String = _CompanyState.format_day_hud_line(day_world)
    if not day_line.contains("steps"):
        _fail(failures, "Camp-1.2: hybrid HUD should show step progress")
    else:
        _pass()
    _release_harness_world(day_world)

    var esc_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[1])
    if not esc_lbl.contains("bleed"):
        _fail(failures, "Camp-1.4: contract marker should show map bleed mult when <1")
    else:
        _pass()

    seed(90210)
    var field_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(field_world, 2)
    var pm_f: Node = field_world.get_meta("party_manager")
    var live: Node = _add_living_entity_member(pm_f, "Fielder")
    live.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    live.apply_direct_pressure("chest")
    var member_d: Dictionary = _Snapshot.snapshot_from_member({"name": "Fielder", "node_ref": live})
    if not _MapFieldCare.can_offer_field_stabilize(field_world, member_d):
        _fail(failures, "Camp-2.1: field stabilize should be offered under pressure")
    else:
        _pass()
    seed(90210)
    if not _MapFieldCare.try_field_stabilize(field_world, member_d):
        _fail(failures, "Camp-2.1: field stabilize should succeed")
    else:
        _pass()
    if bool(live.bandaged_parts.get("chest", false)):
        _fail(failures, "Camp-2.1: field stabilize must not set bandaged_parts (hemostatic hold only)")
    else:
        _pass()
    if _CompanyState.camp_heal_ready(field_world, true):
        _fail(failures, "Camp-2.1: camp rest must stay gated after stabilize until bandage dresses wound")
    else:
        _pass()
    if not _MapFieldCare.can_offer_field_bandage(field_world, member_d):
        _fail(failures, "Camp-2.1: field bandage should remain offered after stabilize while pressure held")
    else:
        _pass()
    _release_harness_world(field_world)

    seed(90210)
    var dress_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(dress_world, 2)
    var pm_d: Node = dress_world.get_meta("party_manager")
    var dresser: Node = _add_living_entity_member(pm_d, "Dresser")
    dresser.wounds["chest"] = [
        {"current_bleeding_rate": 0.6, "severity": "moderate"},
    ]
    var dress_member: Dictionary = _Snapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
    if _MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
        _fail(failures, "Camp-2.1: field bandage should require direct pressure first")
    else:
        _pass()
    if not dresser.apply_direct_pressure("chest"):
        _fail(failures, "Camp-2.1: setup pressure on chest for field bandage")
    else:
        _pass()
    dress_member = _Snapshot.snapshot_from_member({"name": "Dresser", "node_ref": dresser})
    if not _MapFieldCare.can_offer_field_bandage(dress_world, dress_member):
        _fail(failures, "Camp-2.1: field bandage should be offered on untreated chest")
    else:
        _pass()
    var bandaged_ok: bool = false
    for attempt in range(24):
        _CompanyState.set_medical_supplies(dress_world, 2)
        dresser.bandaged_parts.erase("chest")
        if dresser.self_direct_pressure_part != "chest":
            dresser.apply_direct_pressure("chest")
        seed(90210 + attempt)
        if _MapFieldCare.try_field_bandage(dress_world, dress_member):
            bandaged_ok = true
            break
    if not bandaged_ok:
        _fail(failures, "Camp-2.1: field bandage should eventually dress untreated chest")
    else:
        _pass()
    if _CompanyState.camp_heal_ready(dress_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: camp_heal_ready should be true after field bandage dresses wound")
    var day_before_rest: int = _CompanyState.get_day_index(dress_world)
    if not _CompanyState.try_camp_heal(dress_world, true):
        _fail(failures, "Camp-2.1: camp rest should succeed after pressure + field bandage")
    else:
        _pass()
    if _CompanyState.get_day_index(dress_world) != day_before_rest + 1:
        _fail(
            failures,
            (
                "Camp-2.1: camp rest after field care should advance day %d -> %d"
                % [day_before_rest, _CompanyState.get_day_index(dress_world)]
            )
        )
    else:
        _pass()
    _release_harness_world(dress_world)

    var ally_pressure_world: Node2D = _make_world(1, 0, true)
    var leader_ent: Node = _harness_core_entity()
    leader_ent.name = "Character"
    ally_pressure_world.add_child(leader_ent)
    var pm_ap: Node = ally_pressure_world.get_meta("party_manager")
    var patient_ent: Node = _harness_core_entity()
    patient_ent.wounds["right_arm"] = [
        {"current_bleeding_rate": 0.4, "severity": "moderate"},
    ]
    pm_ap.add_child(patient_ent)
    pm_ap.members.append({"name": "Patient", "node_ref": patient_ent, "company_mood": 50.0})
    var patient_member: Dictionary = _Snapshot.snapshot_from_member({"name": "Patient", "node_ref": patient_ent})
    var script_err_before: int = _OperationalLog.harness_script_error_count()
    if not _MapFieldCare.try_field_pressure(ally_pressure_world, patient_member):
        _fail(failures, "Camp-2.1: field pressure with leader performer should succeed on ally arm wound")
    else:
        _pass()
    if not _EntityMedical.has_direct_pressure_on_part(patient_ent, "right_arm"):
        _fail(failures, "Camp-2.1: ally field pressure should hold compression on right_arm")
    else:
        _pass()
    if _OperationalLog.harness_script_error_count() > script_err_before:
        _fail(
            failures,
            "Camp-2.1: field pressure with leader performer must not SCRIPT_ERROR (can_apply_direct_pressure_from_ally)"
        )
    else:
        _pass()
    _release_harness_world(ally_pressure_world)

    var treat_next_world: Node2D = _make_world(1, 0, true)
    var treat_leader: Node = _harness_core_entity()
    treat_leader.name = "Character"
    treat_next_world.add_child(treat_leader)
    _CompanyState.set_medical_supplies(treat_next_world, 3)
    var pm_tn: Node = treat_next_world.get_meta("party_manager")
    var bleed_bro: Node = _add_living_entity_member(pm_tn, "BleedBro")
    bleed_bro.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
    var ok_bro: Node = _add_living_entity_member(pm_tn, "OkBro")
    var roster: Array = []
    for raw in pm_tn.members:
        if raw is Dictionary:
            roster.append(_Snapshot.snapshot_from_member(raw as Dictionary))
    if not _MapFieldCare.try_treat_next_wound(treat_next_world, roster):
        _fail(failures, "Camp-2.1: treat next wound should apply field pressure on highest threat")
    else:
        _pass()
    if not _EntityMedical.has_direct_pressure_on_part(bleed_bro, "chest"):
        _fail(failures, "Camp-2.1: treat next wound should pressure highest-threat part first")
    else:
        _pass()
    var treat_next_dressed: bool = false
    for attempt in range(48):
        _CompanyState.set_medical_supplies(treat_next_world, 3)
        roster = []
        for raw in pm_tn.members:
            if raw is Dictionary:
                roster.append(_Snapshot.snapshot_from_member(raw as Dictionary))
        seed(90400 + attempt)
        # MARCH chain: pressure -> stabilize -> pack/bandage; RNG may fail one tick.
        _MapFieldCare.try_treat_next_wound(treat_next_world, roster)
        if _EntityWounds.part_has_definitive_hemostasis(bleed_bro, "chest"):
            treat_next_dressed = true
            break
    if not treat_next_dressed:
        _fail(failures, "Camp-2.1: treat next wound should eventually dress chest after pressure and stabilize")
    else:
        _pass()
    if not _CompanyState.camp_heal_ready(treat_next_world, true):
        _fail(failures, "Camp-2.1: camp rest should unlock after treat-next chain dresses wound")
    else:
        _pass()
    _release_harness_world(treat_next_world)

    var split_world: Node2D = _make_world(2, 0, true)
    var split_leader: Node = _harness_core_entity()
    split_leader.name = "Character"
    split_world.add_child(split_leader)
    _CompanyState.set_medical_supplies(split_world, 4)
    var pm_split: Node = split_world.get_meta("party_manager")
    var split_bro: Node = _add_living_entity_member(pm_split, "SplitDress")
    split_bro.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    split_bro.wounds["left_leg"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var split_roster: Array = []
    var split_member: Dictionary = {}
    for raw in pm_split.members:
        if raw is Dictionary:
            var split_snap: Dictionary = _Snapshot.snapshot_from_member(raw as Dictionary)
            split_roster.append(split_snap)
            if str(split_snap.get("name", "")) == "SplitDress":
                split_member = split_snap
    if split_member.is_empty():
        _fail(failures, "Camp-2.1: split dress harness member missing")
    else:
        _pass()
    if not _MapFieldCare.can_offer_field_bandage(split_world, split_member):
        _fail(failures, "Camp-2.1: treat-next should offer bandage on clotted part while another bleeds")
    else:
        _pass()
    if not _MapFieldCare.can_treat_next_wound(split_world, split_roster):
        _fail(failures, "Camp-2.1: treat-next should stay available when one part needs pressure and another can dress")
    else:
        _pass()
    if not _MapFieldCare.try_treat_next_wound(split_world, split_roster):
        _fail(failures, "Camp-2.1: treat-next should pressure bleeding part before dressing clotted part")
    else:
        _pass()
    if not _EntityMedical.has_direct_pressure_on_part(split_bro, "chest"):
        _fail(failures, "Camp-2.1: treat-next multi-part should hold pressure on bleeding chest first")
    else:
        _pass()
    split_member = _Snapshot.snapshot_from_member({"name": "SplitDress", "node_ref": split_bro})
    var next_after_pressure: String = _MapFieldCare.format_next_field_care_action(split_world, split_member)
    var next_is_dress_step: bool = (
        next_after_pressure.contains("Field stabilize")
        or next_after_pressure.contains("Field bandage")
        or next_after_pressure.contains("Field pack")
    )
    if not next_is_dress_step or next_after_pressure.contains("Field pressure"):
        _fail(
            failures,
            "Camp-2.1: next action after chest pressure should advance dressing got '%s'" % next_after_pressure
        )
    else:
        _pass()
    var treat_next_lbl: String = _MapFieldCare.format_treat_next_wound_button_label(split_world, split_roster)
    if not treat_next_lbl.contains("Treat next") or not treat_next_lbl.contains("SplitDress"):
        _fail(failures, "Camp-2.1: treat-next button should name brother and step got '%s'" % treat_next_lbl)
    else:
        _pass()
    _release_harness_world(split_world)

    var retry_world: Node2D = _make_world(1)
    var pm_retry: Node = retry_world.get_meta("party_manager")
    var retry_ent: Node = _add_living_entity_member(pm_retry, "RetryBand")
    retry_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    retry_ent.apply_direct_pressure("chest")
    var retry_member: Dictionary = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
    var saw_fail_refund: bool = false
    for attempt in range(48):
        _CompanyState.set_medical_supplies(retry_world, 2)
        retry_ent.bandaged_parts.erase("chest")
        if retry_ent.self_direct_pressure_part != "chest":
            retry_ent.apply_direct_pressure("chest")
        retry_member = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
        seed(88000 + attempt)
        var med_before: int = _CompanyState.get_medical_supplies(retry_world)
        if _MapFieldCare.try_field_bandage(retry_world, retry_member):
            continue
        if (
            _CompanyState.get_medical_supplies(retry_world) == med_before
            and not bool(retry_ent.bandaged_parts.get("chest", false))
            and _EntityMedical.has_direct_pressure_on_part(retry_ent, "chest")
        ):
            saw_fail_refund = true
            break
    if not saw_fail_refund:
        _fail(failures, "Camp-2.1: field bandage failure should refund med, keep wound undressed, retain pressure")
    else:
        _pass()
    _OperationalLog.begin_play_session("headless://field_bandage_fail_log", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    _CompanyState.set_medical_supplies(retry_world, 2)
    retry_ent.bandaged_parts.erase("chest")
    retry_ent.apply_direct_pressure("chest")
    retry_member = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
    for attempt in range(48):
        seed(88100 + attempt)
        if not _MapFieldCare.try_field_bandage(retry_world, retry_member):
            break
    var fail_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("field_care bandage failed") and s.contains("parts_left="):
            fail_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not fail_logged:
        _fail(failures, "Camp-2.1: bandage failure log should include parts_left")
    else:
        _pass()
    var retry_tree_root: Node = _harness_root()
    if retry_tree_root != null and retry_world.get_parent() == null:
        retry_tree_root.add_child(retry_world)
    var retry_menu: PopupPanel = _new_party_menu()
    retry_world.add_child(retry_menu)
    var retry_roster_ui: Array = []
    for raw in pm_retry.members:
        if raw is Dictionary:
            retry_roster_ui.append(_Snapshot.snapshot_from_member(raw as Dictionary))
    retry_menu.show_party(retry_world, retry_roster_ui)
    var fail_notice: bool = false
    for attempt in range(48):
        seed(88200 + attempt)
        _CompanyState.set_medical_supplies(retry_world, 2)
        retry_ent.bandaged_parts.erase("chest")
        if retry_ent.self_direct_pressure_part != "chest":
            retry_ent.apply_direct_pressure("chest")
        retry_member = _Snapshot.snapshot_from_member({"name": "RetryBand", "node_ref": retry_ent})
        var fail_step := func() -> bool: return _MapFieldCare.try_field_bandage(retry_world, retry_member)
        retry_menu._run_field_care_step(fail_step, "bandage")
        var ui_blob: String = " ".join(_collect_control_label_texts(retry_menu))
        if ui_blob.contains("retry") or ui_blob.contains("keep pressure"):
            fail_notice = true
            break
    if not fail_notice:
        _fail(failures, "Camp-2.1: Party menu should surface bandage failure retry notice")
    else:
        _pass()
    var retry_hint: String = _MapFieldCare.format_field_care_retry_hint("bandage")
    if not retry_hint.contains("retry"):
        _fail(failures, "Camp-2.1: field care retry hint should mention retry got '%s'" % retry_hint)
    else:
        _pass()
    retry_menu.queue_free()
    _release_harness_world(retry_world)

    var clot_world: Node2D = _make_world(1)
    var pm_clot: Node = clot_world.get_meta("party_manager")
    var clot_ent: Node = _add_living_entity_member(pm_clot, "ClotDress")
    clot_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var clot_member: Dictionary = _Snapshot.snapshot_from_member({"name": "ClotDress", "node_ref": clot_ent})
    if _MapFieldCare.can_offer_field_bandage(clot_world, clot_member):
        _pass()
    else:
        _fail(failures, "Camp-2.1: field bandage should be offered on clotted untreated part without pressure")
    if _MapFieldCare.field_bandage_needs_pressure_first(clot_member):
        _fail(failures, "Camp-2.1: clotted part should not block bandage waiting on pressure")
    else:
        _pass()
    var clot_dressed: bool = false
    for attempt in range(48):
        _CompanyState.set_medical_supplies(clot_world, 2)
        clot_ent.bandaged_parts.erase("chest")
        clot_member = _Snapshot.snapshot_from_member({"name": "ClotDress", "node_ref": clot_ent})
        seed(99000 + attempt)
        if _MapFieldCare.try_field_bandage(clot_world, clot_member):
            clot_dressed = true
            break
    if not clot_dressed:
        _fail(failures, "Camp-2.1: field bandage should eventually dress clotted untreated chest")
    else:
        _pass()
    if _CompanyState.camp_heal_ready(clot_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: clotted field bandage should dress part for camp rest")
    _release_harness_world(clot_world)

    var zero_med_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(zero_med_world, 0)
    var pm_zero: Node = zero_med_world.get_meta("party_manager")
    var zero_ent: Node = _add_living_entity_member(pm_zero, "ZeroMedDress")
    zero_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var zero_member: Dictionary = _Snapshot.snapshot_from_member({"name": "ZeroMedDress", "node_ref": zero_ent})
    if not _MapFieldCare.can_offer_field_bandage(zero_med_world, zero_member):
        _fail(failures, "Camp-2.1 E3: field bandage should be offered at 0 company med")
    else:
        _pass()
    var zero_gate: String = _CompanyState.format_party_triage_gate_line(zero_med_world)
    if not zero_gate.contains("0 med"):
        _fail(failures, "Camp-2.1 E3: triage gate at 0 med should mention 0-med bandage got '%s'" % zero_gate)
    else:
        _pass()
    var zero_hud: String = _CompanyState.format_hud_triage_suffix(zero_med_world)
    if not zero_hud.contains("0-med"):
        _fail(failures, "Camp-2.1 E3: HUD suffix at 0 med should mention 0-med bandages got '%s'" % zero_hud)
    else:
        _pass()
    var zero_camp_block: String = _CompanyState.format_camp_heal_block_reason(zero_med_world, true)
    if not zero_camp_block.contains("dressing"):
        _fail(failures, "Camp-2.1 E3: camp block at 0 med with wounds should cite dressing got '%s'" % zero_camp_block)
    else:
        _pass()
    var zero_menu: PopupPanel = _new_party_menu()
    zero_med_world.add_child(zero_menu)
    var zero_roster_before: Array = []
    for raw in pm_zero.members:
        if raw is Dictionary:
            zero_roster_before.append(_Snapshot.snapshot_from_member(raw as Dictionary))
    zero_menu.show_party(zero_med_world, zero_roster_before)
    var zero_dressed: bool = false
    for attempt in range(48):
        _CompanyState.set_medical_supplies(zero_med_world, 0)
        zero_ent.bandaged_parts.erase("chest")
        zero_member = _Snapshot.snapshot_from_member({"name": "ZeroMedDress", "node_ref": zero_ent})
        seed(99100 + attempt)
        if _MapFieldCare.try_field_bandage(zero_med_world, zero_member):
            zero_dressed = true
            break
    if not zero_dressed:
        _fail(failures, "Camp-2.1 E3: field bandage should succeed at 0 med with reduced efficacy")
    else:
        _pass()
    if _CompanyState.get_medical_supplies(zero_med_world) != 0:
        _fail(failures, "Camp-2.1 E3: field bandage at 0 med must not consume company med")
    else:
        _pass()
    var zero_roster_after: Array = []
    for raw in pm_zero.members:
        if raw is Dictionary:
            zero_roster_after.append(_Snapshot.snapshot_from_member(raw as Dictionary))
    zero_menu.show_party(zero_med_world, zero_roster_after)
    var zero_labels: String = " ".join(_collect_control_label_texts(zero_menu))
    if not zero_labels.contains("Camp rest unlocked"):
        _fail(
            failures,
            (
                "Camp-2.1 E3: Party should show dressed-complete banner at 0 med got '%s'"
                % zero_labels.substr(0, mini(120, zero_labels.length()))
            )
        )
    else:
        _pass()
    zero_menu.queue_free()
    _release_harness_world(zero_med_world)

    var wired_zero_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(wired_zero_world, 0)
    _CompanyState.wire_party_medical_supply(wired_zero_world)
    var pm_wz: Node = wired_zero_world.get_meta("party_manager")
    var wired_ent: Node = _add_living_entity_member(pm_wz, "WiredZeroMed")
    wired_ent.intelligence = 100
    wired_ent.wounds["chest"] = [
        {"current_bleeding_rate": 0.0, "base_bleeding_rate": 0.2, "severity": "moderate"},
    ]
    var wired_eff: float = _CompanyState.compute_field_treatment_effectiveness(wired_ent, wired_zero_world, false)
    if absf(wired_eff - 0.5) > 0.03:
        _fail(failures, "Camp-2.1 E3: post-fight wired 0-med field efficacy want ~0.50 got %.2f" % wired_eff)
    else:
        _pass()
    _CompanyState.set_medical_supplies(wired_zero_world, 4)
    if absf(float(wired_ent.get_campaign_supply_factor()) - 1.0) > 0.03:
        _fail(failures, "Camp-2.1 E3: set_medical_supplies should rewire entity supply stamp to 1.0 at 4 med")
    else:
        _pass()
    _release_harness_world(wired_zero_world)

    var sort_world: Node2D = _make_world(1)
    var pm_sort: Node = sort_world.get_meta("party_manager")
    var sort_ent: Node = _add_living_entity_member(pm_sort, "SortThreat")
    sort_ent.wounds["left_leg"] = [
        {"current_bleeding_rate": 0.08, "severity": "minor"},
    ]
    sort_ent.wounds["right_arm"] = [
        {"current_bleeding_rate": 0.9, "is_arterial": true, "severity": "severe"},
    ]
    var sorted: Array = _EntityWounds.sorted_untreated_part_names(sort_ent)
    if sorted.is_empty() or str(sorted[0]) != "right_arm":
        _fail(failures, "Camp-2.1: untreated parts should sort by threat (want right_arm first got %s)" % str(sorted))
    else:
        _pass()
    _release_harness_world(sort_world)

    var pack_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(pack_world, 2)
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
    var pack_member: Dictionary = _Snapshot.snapshot_from_member({"name": "FieldPack", "node_ref": field_pack_ent})
    if not _MapFieldCare.can_offer_field_pack(pack_world, pack_member):
        _fail(failures, "Camp-2.1: field pack should be offered on pressured junctional wound")
    else:
        _pass()
    var packed_ok: bool = false
    for attempt in range(32):
        _CompanyState.set_medical_supplies(pack_world, 2)
        field_pack_ent.packed_parts.erase("chest")
        if not _EntityMedical.has_direct_pressure_on_part(field_pack_ent, "chest"):
            field_pack_ent.apply_direct_pressure("chest")
        seed(99200 + attempt)
        if _MapFieldCare.try_field_pack(pack_world, pack_member):
            packed_ok = true
            break
    if not packed_ok:
        _fail(failures, "Camp-2.1: field pack should eventually pack junctional chest")
    else:
        _pass()
    if _CompanyState.camp_heal_ready(pack_world, true):
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
    var tq_member: Dictionary = _Snapshot.snapshot_from_member({"name": "FieldTQ", "node_ref": tq_ent})
    if not _MapFieldCare.can_offer_field_tourniquet(tq_world, tq_member):
        _fail(failures, "Camp-2.1: field tourniquet should be offered on severe limb bleed")
    else:
        _pass()
    if not _MapFieldCare.try_field_tourniquet(tq_world, tq_member):
        _fail(failures, "Camp-2.1: field tourniquet should succeed on indicated limb")
    else:
        _pass()
    if not _CompanyState.camp_heal_ready(tq_world, true):
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
    var lbl_member: Dictionary = _Snapshot.snapshot_from_member({"name": "LabelTest", "node_ref": lbl_ent})
    var pressure_lbl: String = _MapFieldCare.format_field_pressure_button_label(label_world, lbl_member)
    if not pressure_lbl.contains("Chest"):
        _fail(failures, "Camp-2.1: field pressure button should name target part got '%s'" % pressure_lbl)
    else:
        _pass()
    var budget: Dictionary = _CompanyState.triage_med_budget(label_world)
    if int(budget.get("parts_need", 0)) != 1 or int(budget.get("total_worst_case", 0)) != 2:
        _fail(failures, "Camp-2.1: triage_med_budget want parts=1 total=2 got %s" % str(budget))
    else:
        _pass()
    if int(budget.get("med_shortfall", -1)) != 0:
        _fail(failures, "Camp-2.1: med_shortfall should be 0 when supplies sufficient")
    else:
        _pass()
    _CompanyState.set_medical_supplies(label_world, 0)
    var budget_zero: Dictionary = _CompanyState.triage_med_budget(label_world)
    if int(budget_zero.get("field_bandage_med_est", -1)) != 0:
        _fail(failures, "Camp-2.1 E3: triage budget at 0 med should not charge for bandages")
    else:
        _pass()
    var hud_suffix: String = _CompanyState.format_hud_triage_suffix(label_world)
    if not hud_suffix.contains("1"):
        _fail(failures, "Camp-2.1: HUD triage suffix should show part count got '%s'" % hud_suffix)
    else:
        _pass()
    var wait_member: Dictionary = lbl_member
    var wait_lbl: String = _MapFieldCare.format_field_bandage_waiting_label(wait_member)
    if not wait_lbl.contains("Chest"):
        _fail(failures, "Camp-2.1: bandage waiting label should name part got '%s'" % wait_lbl)
    else:
        _pass()
    var pm_multi: Node = label_world.get_meta("party_manager")
    var multi_ent: Node = _add_living_entity_member(pm_multi, "MultiPart")
    multi_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    multi_ent.wounds["left_leg"] = [{"current_bleeding_rate": 0.2, "severity": "moderate"}]
    var multi_member: Dictionary = _Snapshot.snapshot_from_member({"name": "MultiPart", "node_ref": multi_ent})
    var multi_hint: String = _MapFieldCare.format_member_field_care_hint(multi_member)
    if not multi_hint.contains("2 untreated part"):
        _fail(failures, "Camp-2.1: member field care hint should count parts got '%s'" % multi_hint)
    else:
        _pass()
    var single_hint: String = _MapFieldCare.format_member_field_care_hint(lbl_member)
    if not single_hint.contains("One part left"):
        _fail(failures, "Camp-2.1: single-part hint expected got '%s'" % single_hint)
    else:
        _pass()
    var next_action: String = _MapFieldCare.format_next_field_care_action(label_world, lbl_member)
    if not next_action.contains("Field pressure"):
        _fail(failures, "Camp-2.1: next field care action should start with pressure got '%s'" % next_action)
    else:
        _pass()
    var party_lbl: String = _CompanyState.format_party_button_label(label_world)
    if not party_lbl.contains("to dress"):
        _fail(failures, "Camp-2.1: party button label should show dress count got '%s'" % party_lbl)
    else:
        _pass()
    var btn_world: Node2D = _make_world(0, 0, true)
    btn_world.set_script(_CampaignWorldScript)
    var player_char := Node2D.new()
    player_char.name = "Character"
    btn_world.add_child(player_char)
    _PartySetup.setup_party(btn_world)
    var pm_btn: Node = btn_world.get_meta("party_manager")
    var btn_ent: Node = _add_living_entity_member(pm_btn, "BtnTint")
    btn_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    _CompanyState.refresh_party_button(btn_world)
    var pb: Control = _CombatFlow._find_party_button(btn_world)
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
    _CompanyState.set_medical_supplies(btn_world, 0)
    _CompanyState.refresh_party_button(btn_world)
    var pb_zero: Control = _CombatFlow._find_party_button(btn_world)
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
    var btn_member: Dictionary = _Snapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
    var btn_dressed: bool = false
    for attempt in range(24):
        btn_ent.bandaged_parts.erase("chest")
        if btn_ent.self_direct_pressure_part != "chest":
            btn_ent.apply_direct_pressure("chest")
        btn_member = _Snapshot.snapshot_from_member({"name": "BtnTint", "node_ref": btn_ent})
        seed(90300 + attempt)
        if _MapFieldCare.try_field_bandage(btn_world, btn_member):
            btn_dressed = true
            break
    if not btn_dressed:
        _fail(failures, "Camp-2.1: PartyButton clear test could not dress chest")
    else:
        _pass()
    (
        btn_world
        . set_meta(
            _CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
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
    _CompanyState.set_medical_supplies(btn_world, 0)
    if not _CompanyState.should_show_party_camp_rest_button(btn_world):
        _fail(failures, "Camp-2.1: dressed roster with 0 med should show camp rest button")
    else:
        _pass()
    _CompanyState.refresh_party_button(btn_world)
    var pb_clear: Button = _CombatFlow._find_party_button(btn_world) as Button
    if pb_clear == null:
        _fail(failures, "Camp-2.1: PartyButton missing after dress")
    elif pb_clear.text != "Party" or pb_clear.has_theme_color_override("font_color"):
        _fail(failures, "Camp-2.1: PartyButton should clear dress tint after dressing got '%s'" % pb_clear.text)
    else:
        _pass()
    _free_harness_world(btn_world)
    _cleanup_harness_ui_overlay()
    var part_list: String = _MapFieldCare.format_part_list(PackedStringArray(["chest", "left_leg"]))
    if not part_list.contains("Chest") or not part_list.contains("L.Leg"):
        _fail(failures, "Camp-2.1: format_part_list want human labels got '%s'" % part_list)
    else:
        _pass()
    _CompanyState.set_medical_supplies(label_world, 1)
    var budget_short: Dictionary = _CompanyState.triage_med_budget(label_world)
    if int(budget_short.get("med_shortfall", 0)) < 1:
        _fail(failures, "Camp-2.1: med_shortfall should be positive when under-supplied")
    else:
        _pass()
    var gate_line: String = _CompanyState.format_party_triage_gate_line(label_world)
    if not gate_line.contains("Short"):
        _fail(failures, "Camp-2.1: triage gate should warn med shortfall got '%s'" % gate_line)
    else:
        _pass()
    var short_hud: String = _CompanyState.format_hud_triage_suffix(label_world)
    if not short_hud.contains("about") and not short_hud.contains("need"):
        _fail(failures, "Camp-2.1: HUD suffix should note med estimate got '%s'" % short_hud)
    else:
        _pass()
    _release_harness_world(label_world)

    var undressed_world: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(undressed_world)
    var pm_ud: Node = undressed_world.get_meta("party_manager")
    var ud_ent: Node = _add_living_entity_member(pm_ud, "Clotted")
    ud_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
    var move_msg: String = _MapBleedPolicy.map_move_blocked_message(undressed_world)
    if not move_msg.contains("Dress wounds") or not move_msg.contains("1 part"):
        _fail(failures, "Camp-2.1: undressed-only map block should mention dressing got '%s'" % move_msg)
    elif not move_msg.contains("bandage"):
        _fail(failures, "Camp-2.1: map block should cite MARCH chain got '%s'" % move_msg)
    else:
        _pass()
    var hud_ud: String = _MapBleedPolicy.hud_bleed_hint(undressed_world)
    if not hud_ud.contains("Dress wounds"):
        _fail(failures, "Camp-2.1: HUD should hint dress when clotted but undressed got '%s'" % hud_ud)
    elif not hud_ud.contains("pressure"):
        _fail(failures, "Camp-2.1: HUD dress hint should cite MARCH chain got '%s'" % hud_ud)
    else:
        _pass()
    var complete_line: String = _CompanyState.format_field_care_complete_line(undressed_world)
    if not complete_line.contains("Camp rest unlocked"):
        _fail(failures, "Camp-2.1: field care complete line expected got '%s'" % complete_line)
    else:
        _pass()
    _release_harness_world(undressed_world)

    var step_world: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(step_world)
    var pm_st: Node = step_world.get_meta("party_manager")
    var st_ent: Node = _add_living_entity_member(pm_st, "ClotStep")
    st_ent.wounds["chest"] = [{"current_bleeding_rate": 0.0, "severity": "moderate", "clotted": true}]
    _CompanyState.set_medical_supplies(step_world, 0)
    _MapBleedPolicy.on_overworld_step(step_world)
    if not step_world.has_meta(_MapBleedPolicy.WORLD_META_BLEED_WARN):
        _fail(failures, "Camp-2.1: overworld step should warn when clotted but undressed")
    else:
        var warn_msg: String = str(step_world.get_meta(_MapBleedPolicy.WORLD_META_BLEED_WARN))
        if not warn_msg.contains("need dressing"):
            _fail(failures, "Camp-2.1: clotted step warn should mention need dressing got '%s'" % warn_msg)
        elif not warn_msg.contains("0-med"):
            _fail(failures, "Camp-2.1: clotted step warn at 0 med should mention 0-med bandages got '%s'" % warn_msg)
        else:
            _pass()
    var settle_hint: String = _CompanyState.format_settlement_field_care_hint(step_world)
    if not settle_hint.contains("1 part") or not settle_hint.contains("Party"):
        _fail(failures, "Camp-2.1: settlement field care hint missing got '%s'" % settle_hint)
    elif not settle_hint.contains("0 med"):
        _fail(failures, "Camp-2.1: settlement field care hint at 0 med should cite dress note got '%s'" % settle_hint)
    else:
        _pass()
    (
        step_world
        . set_meta(
            _CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
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
    var worst_settle: Dictionary = _RowFormatter.worst_triage_from_member_rows(
        _CampaignBridge.party_member_snapshots(step_world)
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
    var clot_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "ClotStep", "node_ref": st_ent})
    var settle_next: String = _MapFieldCare.format_next_field_care_action(step_world, clot_snap)
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
    var persist_member: Dictionary = _Snapshot.snapshot_from_member({"name": "Persist", "node_ref": persist_ent})
    _MapFieldCare.try_field_pressure(persist_world, persist_member)
    if not _EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
        _fail(failures, "Camp-2.1: field pressure should set compression before step")
    else:
        _pass()
    var held_line: String = _MapFieldCare.format_member_pressure_held_line(persist_member)
    if not held_line.contains("Chest"):
        _fail(failures, "Camp-2.1: pressure held line should name part got '%s'" % held_line)
    else:
        _pass()
    _CampaignBridge.advance_party_overworld_minute(persist_world)
    if not _EntityMedical.has_direct_pressure_on_part(persist_ent, "chest"):
        _fail(failures, "Camp-2.1: overworld step must retain field pressure until dressed")
    else:
        _pass()
    _release_harness_world(persist_world)

    _OperationalLog.begin_play_session("headless://camp_field_care_done", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var log_world: Node2D = _make_world(1)
    var pm_log: Node = log_world.get_meta("party_manager")
    var log_ent: Node = _add_living_entity_member(pm_log, "LogDress")
    log_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    log_ent.apply_direct_pressure("chest")
    var log_member: Dictionary = _Snapshot.snapshot_from_member({"name": "LogDress", "node_ref": log_ent})
    _CompanyState.set_medical_supplies(log_world, 2)
    var dressed: bool = false
    for attempt in range(24):
        log_ent.bandaged_parts.erase("chest")
        if log_ent.self_direct_pressure_part != "chest":
            log_ent.apply_direct_pressure("chest")
        seed(90210 + attempt)
        if _MapFieldCare.try_field_bandage(log_world, log_member):
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
    var sim_seconds_s: String = "seconds=%.0f" % _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
    for line in _OperationalLog.get_captured_lines():
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
    if _CompanyState.try_camp_heal(log_world, true):
        _pass()
    else:
        _fail(failures, "Camp-2.1: camp heal should succeed after all_dressed log test")
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("camp_heal") and str(line).contains("all_dressed=true"):
            camp_logged = true
            break
    if not camp_logged:
        _fail(failures, "Camp-2.1: camp heal success should log all_dressed=true")
    else:
        _pass()
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    _release_harness_world(log_world)

    _OperationalLog.begin_play_session("headless://camp_heal_blocked", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var block_world: Node2D = _make_world(1)
    _CompanyState.set_medical_supplies(block_world, 3)
    var pm_block: Node = block_world.get_meta("party_manager")
    var block_ent: Node = _add_living_entity_member(pm_block, "BlockCamp")
    block_ent.wounds["chest"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    if _CompanyState.try_camp_heal(block_world, true):
        _fail(failures, "Camp-2.1: camp heal should fail when wounds undressed")
    else:
        _pass()
    var block_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("camp_heal blocked:") and s.contains("parts_need=1"):
            block_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not block_logged:
        _fail(failures, "Camp-2.1: camp heal blocked log should include parts_need")
    else:
        _pass()
    _release_harness_world(block_world)

    var healthy_world: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(healthy_world)
    _CompanyState.set_medical_supplies(healthy_world, 0)
    if _CompanyState.should_show_party_camp_rest_button(healthy_world):
        _fail(failures, "Camp-2.1: healthy roster at 0 med should hide camp rest button")
    else:
        _pass()
    _release_harness_world(healthy_world)

    _OperationalLog.begin_play_session("headless://field_care_hint_zero_med", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var zero_hint_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_medical_supplies(zero_hint_world, 0)
    var pm_zh: Node = zero_hint_world.get_meta("party_manager")
    var zh_ent: Node = _add_living_entity_member(pm_zh, "ZeroHint")
    zh_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    _CampaignBridge.on_return_from_combat(zero_hint_world, "player")
    var zero_hint_ok: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("0-med bandages OK"):
            zero_hint_ok = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not zero_hint_ok:
        _fail(failures, "Camp-2.2: post-fight field_care hint at 0 med should mention 0-med bandages")
    else:
        _pass()
    _release_harness_world(zero_hint_world)

    _OperationalLog.begin_play_session("headless://contract_victory_triage", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var pay_world: Node2D = _make_world(1)
    _CompanyState.set_active_contract(
        pay_world, {"contract_title": "Escort", "pay_gold": 100, "contract_type": "escort"}
    )
    var pm_pay: Node = pay_world.get_meta("party_manager")
    var pay_ent: Node = _add_living_entity_member(pm_pay, "PayBleed")
    pay_ent.wounds["chest"] = [{"current_bleeding_rate": 0.3, "severity": "moderate"}]
    _CompanyState.apply_contract_victory_pay(pay_world)
    var pay_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("contract_victory triage"):
            pay_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not pay_logged:
        _fail(failures, "Camp-2.1: contract victory should log triage budget when wounds remain")
    else:
        _pass()
    _release_harness_world(pay_world)

    var mgr_cnt: Node = _MgrScript.new()
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
    if _MedicalPhase.winner_side_untreated_part_count(mgr_cnt) != 1:
        _fail(failures, "Camp-2.1: winner_side_untreated_part_count want 1")
    else:
        _pass()
    _HarnessFixtures._free_manager(mgr_cnt)

    var bleed_sim_world: Node2D = _make_world(1)
    var pm_bleed: Node = bleed_sim_world.get_meta("party_manager")
    var bleed_sim_ent: Node = _add_living_entity_member(pm_bleed, "BleedSim")
    bleed_sim_ent.wounds["chest"] = [
        {"current_bleeding_rate": 1.2, "is_arterial": true, "severity": "severe"},
    ]
    bleed_sim_ent.apply_direct_pressure("chest")
    var bv_before_pressure: float = float(bleed_sim_ent.blood_volume)
    var cut_before: float = float(bleed_sim_ent.body_cutting.get("chest", 0.0))
    var bleed_member: Dictionary = _Snapshot.snapshot_from_member({"name": "BleedSim", "node_ref": bleed_sim_ent})
    _MapFieldCare.try_field_pressure(bleed_sim_world, bleed_member)
    if float(bleed_sim_ent.blood_volume) > bv_before_pressure + 0.01:
        _fail(failures, "Camp-2.1: field care must not recover blood during active hemorrhage")
    else:
        _pass()
    if float(bleed_sim_ent.body_cutting.get("chest", 0.0)) > cut_before + 0.01:
        _fail(failures, "Camp-2.1: field care procedure must not run tissue healing")
    else:
        _pass()
    _release_harness_world(bleed_sim_world)

    _OperationalLog.begin_play_session("headless://camp_field_care_hint", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var hint_world: Node2D = _make_world(1, 0, true)
    var pm_h: Node = hint_world.get_meta("party_manager")
    var bleeder: Node = _add_living_entity_member(pm_h, "HintBleed")
    bleeder.wounds["right_arm"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    _CampaignBridge.on_return_from_combat(hint_world, "player")
    var hint_found: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("Camp rest"):
            hint_found = true
            if not str(line).contains("bandage_med_est="):
                _fail(failures, "Camp-2.2: field_care hint should log med budget estimates")
            if not str(line).contains("med_shortfall="):
                _fail(failures, "Camp-2.2: field_care hint should log med_shortfall")
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not hint_found:
        _fail(failures, "Camp-2.2: on_return_from_combat should log field-care hint when untreated")
    else:
        _pass()
    _release_harness_world(hint_world)

    var triage: String = _RowFormatter.format_triage_line(72.0, 1.2)
    if not triage.contains("Class II") or not triage.contains("Bleeding"):
        _fail(failures, "Camp-3.2: triage line should include ATLS band and bleed rate")
    else:
        _pass()
    var eta: String = _RowFormatter.format_danger_eta_phrase(40.0, 2.0)
    if eta.is_empty() or not eta.contains("danger"):
        _fail(failures, "Camp-3.2: danger ETA phrase missing for bleeding ally")
    else:
        _pass()

    var debt_world: Node2D = _make_world(2)
    _CompanyState.set_gold(debt_world, 5)
    _CompanyState.try_advance_day(debt_world)
    if _CompanyState.get_gold(debt_world) >= 0:
        _fail(failures, "Camp-2.6: wages should drive gold negative when underfunded")
    else:
        _pass()
    _release_harness_world(debt_world)

    var soft_world: Node2D = _make_world(1, 0, true)
    soft_world.set_script(_CampaignWorldScript)
    _add_player_at_camp(soft_world)
    _CompanyState.set_gold(soft_world, 77)
    var rng := RandomNumberGenerator.new()
    rng.seed = 42
    soft_world.set_meta("rng", rng)
    soft_world.set_meta("enemy_scene", load(ResourcePaths.ENEMY_SCENE) as PackedScene)
    var lost: Dictionary = _ContractSpawner.build_encounter_config(_ContractSpawner.TUTORIAL_TEMPLATE)
    _CombatFlow.resume_overworld_after_soft_defeat(soft_world, lost)
    if _CompanyState.get_gold(soft_world) != 77:
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
    _CompanyState.apply_battle_lost_mood(mood_world)
    var after: float = float(pm_mood.members[0].get("company_mood", 50.0))
    if not is_equal_approx(after, 49.55):
        _fail(failures, "Camp-2.6 B3: battle loss mood should be -0.45 on living roster got %.2f" % after)
    else:
        _pass()
    _release_harness_world(mood_world)

    var death_mood_world: Node2D = _make_world(1, 1)
    var pm_death: Node = death_mood_world.get_meta("party_manager")
    pm_death.members[0]["company_mood"] = 50.0
    _CampaignBridge.build_last_battle_summary(death_mood_world)
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
    _CampaignBridge.build_last_battle_summary(multi_death_world)
    var multi_mood: float = float(pm_multi_death.members[0].get("company_mood", 50.0))
    if not is_equal_approx(multi_mood, 49.5):
        _fail(failures, "Camp-2.6 B3: two deaths should be -0.50 on survivor got %.2f" % multi_mood)
    else:
        _pass()
    _release_harness_world(multi_death_world)

    var r3_mood_world: Node2D = _make_world(1, 1)
    var pm_r3: Node = r3_mood_world.get_meta("party_manager")
    pm_r3.members[0]["company_mood"] = 50.0
    _CompanyState.set_active_contract(
        r3_mood_world, {"pay_gold": 100, "contract_type": "skirmish", "contract_title": "Paid"}
    )
    _CampaignBridge.build_last_battle_summary(r3_mood_world, "enemy")
    var r3_survivor: float = float(pm_r3.members[0].get("company_mood", 50.0))
    if not is_equal_approx(r3_survivor, 50.0):
        _fail(failures, "Camp-2.6 B3: R3 loss should skip death witness mood before reload got %.2f" % r3_survivor)
    else:
        _pass()
    _release_harness_world(r3_mood_world)

    var restart_world: Node2D = _make_world(1, 0, true)
    restart_world.set_script(_CampaignWorldScript)
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

    _run_camp_4_contract_flavor(failures)
    _run_encounter_entry_rollback(failures)
    _run_combat_start_abort_cleanup(failures)


static func _run_combat_start_abort_cleanup(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1, 0, true)
    world.set_script(_CampaignWorldScript)
    _add_player_at_camp(world)
    var pm: Node = world.get_meta("party_manager")
    if pm is Node and "members" in pm and pm.members.size() > 0:
        var dead_ref: Variant = pm.members[0].get("node_ref")
        if dead_ref is Node:
            (dead_ref as Node).set_script(load("res://scripts/_harness_dead_stub.gd") as Script)
    _CompanyState.set_active_contract(world, {"contract_title": "Abort Test", "pay_gold": 50})
    world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"tutorial": false})
    var dummy: Node2D = Node2D.new()
    dummy.name = "SpawnedEnemyStub"
    world.add_child(dummy)
    world.set_meta("_combat_enemies", [dummy])
    _CombatFlow.start_combat(world, [])
    if world.has_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT):
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
    world.set_script(_CampaignWorldScript)
    var rng := RandomNumberGenerator.new()
    var enc: Node2D = _EncounterNodeScript.new()
    enc.enemy_count = 0
    enc.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.TUTORIAL_TEMPLATE)
    world.add_child(enc)
    var before_children: int = world.get_child_count()
    var enemies: Array = _CampaignBridge.begin_contract_encounter(world, enc, rng)
    if not enemies.is_empty():
        _fail(failures, "Camp-1.4: zero-count encounter should return no enemies")
    else:
        _pass()
    if world.has_meta(_CompanyState.WORLD_META_ACTIVE_CONTRACT):
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
    _CampaignBridge.refresh_party_formation_meta(world)
    var pf: Dictionary = world.get_meta("party_formation", {}) as Dictionary
    if int(pf.get("files", 0)) != 7:
        _fail(failures, "Camp-3/III-4: player_front_count=7 want files=7 got %d" % int(pf.get("files", 0)))
    elif int(pf.get("ranks", 0)) != 1:
        _fail(failures, "Camp-3/III-4: player_front_count=7 want ranks=1 got %d" % int(pf.get("ranks", 0)))
    else:
        _pass()
    world.free()


static func _run_camp_4_contract_flavor(failures: PackedStringArray) -> void:
    var _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
    var _CombatConstants := preload("res://combat/CombatConstants.gd")
    var skirmish: Dictionary = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
    if str(skirmish.get(_SoakPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")) != "SWORD":
        _fail(failures, "Camp-4.3: skirmish should force SWORD")
    else:
        _pass()
    if int(skirmish.get(_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 7:
        _fail(failures, "Camp-4/III-4: Border Skirmish template want player_front_count=7")
    else:
        _pass()
    if (
        str(skirmish.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != _CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "Camp-4/III-4: Border Skirmish should set enemy pinch_center doctrine")
    else:
        _pass()
    var world_sk: Node2D = _make_world(7)
    var enc_sk: Node2D = _EncounterNodeScript.new()
    enc_sk.encounter_config = skirmish
    _CampaignBridge.prepare_combat_from_encounter(world_sk, enc_sk)
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
    var escort: Dictionary = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[1])
    if (
        str(escort.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != _CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "Camp-4.2: escort should set enemy pinch_center doctrine")
    else:
        _pass()
    if float(escort.get("flee_line_cohesion_max_enemy", 0.0)) <= 0.0:
        _fail(failures, "Camp-4.2: escort should set flee_line_cohesion_max_enemy")
    else:
        _pass()
    if int(escort.get(_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT, 0)) != 5:
        _fail(failures, "Camp-4/III-4: Escort template want player_front_count=5 (Formation 5x2, not Skirmish 7-wide)")
    else:
        _pass()
    var world_esc: Node2D = _make_world(7)
    world_esc.set_meta(
        _CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {_CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 5}
    )
    _CampaignBridge.refresh_party_formation_meta(world_esc)
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
    var enc_esc: Node2D = _EncounterNodeScript.new()
    enc_esc.encounter_config = escort
    _CampaignBridge.prepare_combat_from_encounter(world_esc_pc, enc_esc)
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
    var enc: Node2D = _EncounterNodeScript.new()
    enc.encounter_config = escort
    var meta_world: Node2D = _make_world(1)
    _CampaignBridge.prepare_combat_from_encounter(meta_world, enc)
    var got: Dictionary = meta_world.get_meta(_CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if got.is_empty() or not got.has(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY):
        _fail(failures, "Camp-4.2: escort doctrine should reach combat meta")
    else:
        _pass()
    meta_world.free()
    enc.free()
    var lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[1])
    if not lbl.contains("Escort") and not lbl.contains("120"):
        _fail(failures, "Camp-4: escort marker label should show title/pay")
    elif not lbl.contains("5-wide"):
        _fail(failures, "Camp-4/III-4: escort marker label should show 5-wide formation hint")
    else:
        _pass()
    var skirmish_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.CONTRACT_TEMPLATES[0])
    if not skirmish_lbl.contains("7-wide"):
        _fail(failures, "Camp-4/III-4: skirmish marker label should show 7-wide formation hint")
    else:
        _pass()
    var tut_default: Dictionary = FormationPreset.default_for_count(7)
    var world_fresh_tut: Node2D = _make_world(7)
    _ContractSpawner._spawn_contract_at_tile(world_fresh_tut, Vector2i(1, 0), _ContractSpawner.TUTORIAL_TEMPLATE, null)
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
        _CampaignBridge.prepare_combat_from_encounter(world_fresh_tut, fresh_enc)
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
    var tut_lbl: String = _ContractSpawner.format_marker_label(_ContractSpawner.TUTORIAL_TEMPLATE)
    if not tut_lbl.contains("Tutorial") or not tut_lbl.contains("2 foes"):
        _fail(failures, "Camp-4/III-4: tutorial marker label should show tutorial title and foe count")
    else:
        _pass()
    if _ContractSpawner.TUTORIAL_TEMPLATE.has(CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT):
        _fail(failures, "Camp-4/III-4: tutorial template must not pin player_front_count")
    else:
        _pass()
    var old_save_tut: Dictionary = _ContractSpawner.TUTORIAL_TEMPLATE.duplicate(true)
    old_save_tut[CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT] = 2
    old_save_tut[CombatConstants.ENCOUNTER_KEY_PLAYER_FORMATION] = {"files": 2, "ranks": 4}
    var world_saved_tut: Node2D = _make_world(7)
    _ContractSpawner.spawn_saved_encounter_at_tile(
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
        _CampaignBridge.prepare_combat_from_encounter(world_saved_tut, saved_enc)
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
    _OperationalLog.set_capture_enabled(true)
    if _OperationalLog.is_play_session_active():
        _OperationalLog.end_play_session()
    var silent_ok: bool = false
    for seed_try in range(8000):
        seed(seed_try)
        _OperationalLog.clear_capture()
        var silent_world: Node2D = _make_world(1)
        var pm_silent: Node = silent_world.get_meta("party_manager")
        for raw in pm_silent.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 10.0
        _CompanyState._run_daily_desertion_pass(silent_world)
        var summary_logged: bool = false
        for line in _OperationalLog.get_captured_lines():
            if str(line).contains("desertion summary="):
                summary_logged = true
                break
        if _CompanyState.is_bankrupt(silent_world) and not summary_logged:
            silent_ok = true
        _release_harness_world(silent_world)
        if silent_ok:
            break
    _OperationalLog.set_capture_enabled(false)
    if not silent_ok:
        _fail(failures, "Camp-5: desertion should collapse roster without desertion summary outside play session")
    else:
        _pass()

    _OperationalLog.begin_play_session("headless://camp_debt_warn", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var debt_world: Node2D = _make_world(2, 0, true)
    _CompanyState.set_gold(debt_world, 5)
    _CompanyState.try_advance_day(debt_world)
    var debt_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("Company is in debt"):
            debt_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not debt_logged:
        _fail(failures, "Camp-5: try_advance_day should log debt warning when gold negative")
    else:
        _pass()
    _release_harness_world(debt_world)

    _OperationalLog.begin_play_session("headless://camp_settlement_continue", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var settle_world: Node2D = _make_world(1)
    _CompanyState.mark_tutorial_completed(settle_world)
    (
        _CompanyState
        . set_active_contract(
            settle_world,
            {
                "pay_gold": 120,
                "contract_title": "Border Skirmish",
                "contract_type": "skirmish",
            }
        )
    )
    var settle_contract: Dictionary = _CompanyState.get_active_contract(settle_world)
    var settle_pay: int = _CompanyState.apply_contract_victory_pay(settle_world)
    _OperationalLog.play_world(
        _SettlementPanel.format_settlement_continue_log(settle_world, settle_contract, settle_pay)
    )
    var victory_logged: bool = false
    var continue_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("contract_victory pay=") and s.contains("gold="):
            victory_logged = true
        if s.contains("settlement_continue pay=") and s.contains("tutorial=false"):
            continue_logged = true
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
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
    _CompanyState.set_active_contract(
        tut_settle_world, _ContractSpawner.build_encounter_config(_ContractSpawner.TUTORIAL_TEMPLATE)
    )
    var tut_contract: Dictionary = _CompanyState.get_active_contract(tut_settle_world)
    _OperationalLog.begin_play_session("headless://camp_tutorial_settlement", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var tut_pay: int = _CompanyState.apply_contract_victory_pay(tut_settle_world)
    _OperationalLog.play_world(_SettlementPanel.format_settlement_continue_log(tut_settle_world, tut_contract, tut_pay))
    var tut_victory_logged: bool = false
    var tut_continue_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("contract_victory tutorial"):
            tut_victory_logged = true
        if s.contains("settlement_continue pay=0") and s.contains("tutorial=true"):
            tut_continue_logged = true
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
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

    _OperationalLog.begin_play_session("headless://camp_field_care_pressure", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var press_world: Node2D = _make_world(1, 0, true)
    var leader_ent: Node = _harness_core_entity()
    leader_ent.name = "Character"
    press_world.add_child(leader_ent)
    var pm_press: Node = press_world.get_meta("party_manager")
    var press_patient: Node = _harness_core_entity()
    press_patient.wounds["right_arm"] = [{"current_bleeding_rate": 0.4, "severity": "moderate"}]
    pm_press.add_child(press_patient)
    pm_press.members.append({"name": "PressBro", "node_ref": press_patient, "company_mood": 50.0})
    var press_member: Dictionary = _Snapshot.snapshot_from_member({"name": "PressBro", "node_ref": press_patient})
    if not _MapFieldCare.try_field_pressure(press_world, press_member):
        _fail(failures, "Camp-5: field pressure action should succeed on ally arm wound")
    else:
        _pass()
    var pressure_logged: bool = false
    var pressure_sim_seconds_logged: bool = false
    var field_care_sim_seconds_s: String = "seconds=%.0f" % _MapFieldCare.FIELD_CARE_SIM_ADVANCE_SECONDS
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("field_care pressure part=right_arm"):
            pressure_logged = true
        if s.contains("field_care pressure") and s.contains(field_care_sim_seconds_s):
            pressure_sim_seconds_logged = true
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not pressure_logged:
        _fail(failures, "Camp-5: field pressure success should log field_care pressure part=")
    else:
        _pass()
    if not pressure_sim_seconds_logged:
        _fail(failures, "Camp-2.1: field pressure log should report sim advance %s" % field_care_sim_seconds_s)
    else:
        _pass()
    _release_harness_world(press_world)

    _OperationalLog.begin_play_session("headless://camp_field_care_hint", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var hint_world: Node2D = _make_world(1)
    var pm_hint: Node = hint_world.get_meta("party_manager")
    var hint_ent: Node = _add_living_entity_member(pm_hint, "HintBro")
    hint_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    var hint_line: String = _CompanyState.format_post_fight_field_care_world_log(hint_world)
    if not hint_line.begins_with("field_care:"):
        _fail(failures, "Camp-5: post-fight field care hint should begin with field_care:")
    else:
        _pass()
    _OperationalLog.play_world(hint_line)
    var hint_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("field_care:") and str(line).contains("need dressing"):
            hint_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not hint_logged:
        _fail(failures, "Camp-5: field_care hint should log need dressing on map return")
    else:
        _pass()
    _release_harness_world(hint_world)

    _OperationalLog.begin_play_session("headless://camp_company_day", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var day_world: Node2D = _make_world(2, 0, true)
    var day_before: int = _CompanyState.get_day_index(day_world)
    _CompanyState.try_advance_day(day_world)
    var day_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if (
            s.contains("company_day_advanced day=%d" % (day_before + 1))
            and s.contains("wages_paid=")
            and s.contains("living=2")
        ):
            day_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not day_logged:
        _fail(failures, "Camp-5: try_advance_day should log company_day_advanced day=%d living=2" % (day_before + 1))
    else:
        _pass()
    _release_harness_world(day_world)

    _OperationalLog.begin_play_session("headless://camp_rest_day_advance", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var rest_world: Node2D = _make_world(1, 0, true)
    _CompanyState.mark_tutorial_completed(rest_world)
    _CompanyState.set_medical_supplies(rest_world, 3)
    var pm_rest: Node = rest_world.get_meta("party_manager")
    var rest_ent: Node = _add_living_entity_member(pm_rest, "CampRest")
    rest_ent.wounds["chest"] = [{"current_bleeding_rate": 0.5, "severity": "moderate"}]
    rest_ent.apply_direct_pressure("chest")
    var rest_member: Dictionary = _Snapshot.snapshot_from_member({"name": "CampRest", "node_ref": rest_ent})
    var rest_dressed: bool = false
    for attempt in range(24):
        rest_ent.bandaged_parts.erase("chest")
        if rest_ent.self_direct_pressure_part != "chest":
            rest_ent.apply_direct_pressure("chest")
        seed(90300 + attempt)
        if _MapFieldCare.try_field_bandage(rest_world, rest_member):
            rest_dressed = true
            break
    if not rest_dressed:
        _fail(failures, "Camp-5: camp rest day test could not dress chest")
    else:
        _pass()
    var rest_day_before: int = _CompanyState.get_day_index(rest_world)
    if not _CompanyState.try_camp_heal(rest_world, true):
        _fail(failures, "Camp-5: camp rest should succeed when all wounds dressed")
    else:
        _pass()
    var camp_day_logged: bool = false
    var camp_heal_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_day_advanced day=%d" % (rest_day_before + 1)) and s.contains("wages_paid="):
            camp_day_logged = true
        if s.contains("camp_heal") and s.contains("all_dressed=true"):
            camp_heal_logged = true
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not camp_day_logged:
        _fail(failures, "Camp-5: Party camp rest should log company_day_advanced day=%d" % (rest_day_before + 1))
    else:
        _pass()
    if not camp_heal_logged:
        _fail(failures, "Camp-5: Party camp rest should log camp_heal all_dressed=true")
    else:
        _pass()
    _release_harness_world(rest_world)

    _OperationalLog.begin_play_session("headless://camp_bankrupt_collapse", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var bankrupt_collapse: bool = false
    for seed_try in range(8000):
        seed(seed_try)
        _OperationalLog.clear_capture()
        var broke_world: Node2D = _make_world(1)
        var pm_broke: Node = broke_world.get_meta("party_manager")
        for raw in pm_broke.members:
            if raw is Dictionary:
                (raw as Dictionary)["company_mood"] = 10.0
        _CompanyState._run_daily_desertion_pass(broke_world)
        if not _CompanyState.is_bankrupt(broke_world):
            _release_harness_world(broke_world)
            continue
        if _CompanyState.count_living_roster(broke_world) > 0:
            _release_harness_world(broke_world)
            continue
        _OperationalLog.play_world(_CompanyRunEndPanel.format_company_run_end_log("bankrupt"))
        var desertion_seen: bool = false
        var bankrupt_log_seen: bool = false
        for line in _OperationalLog.get_captured_lines():
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
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not bankrupt_collapse:
        _fail(failures, "Camp-5: total desertion should set bankrupt and log reason=bankrupt reload=true")
    else:
        _pass()

    _OperationalLog.begin_play_session("headless://camp_run_end_logs", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    for reason in ["contract_failed", "tutorial_failed", "soft_defeat_resume"]:
        _OperationalLog.play_world(_CompanyRunEndPanel.format_company_run_end_log(reason))
    var paid_logged: bool = false
    var tut_logged: bool = false
    var soft_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        var s: String = str(line)
        if s.contains("company_run_end reason=contract_failed reload=true"):
            paid_logged = true
        if s.contains("company_run_end reason=tutorial_failed reload=false"):
            tut_logged = true
        if s.contains("company_run_end reason=soft_defeat_resume reload=false"):
            soft_logged = true
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
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

    _OperationalLog.begin_play_session("headless://camp_party_triage", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var triage_world: Node2D = _make_world(1, 0, true)
    var pm_triage: Node = triage_world.get_meta("party_manager")
    _add_living_entity_member(pm_triage, "OkBro")
    var wound_bro: Node = _add_living_entity_member(pm_triage, "WoundBro")
    wound_bro.wounds["chest"] = [{"current_bleeding_rate": 0.6, "severity": "moderate"}]
    var roster: Array = []
    for raw in pm_triage.members:
        if raw is Dictionary:
            roster.append(_Snapshot.snapshot_from_member(raw as Dictionary))
    var menu: PopupPanel = _new_party_menu()
    triage_world.add_child(menu)
    menu.show_party(triage_world, roster)
    var triage_open_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
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
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    menu.queue_free()
    _release_harness_world(triage_world)


static func _collect_control_label_texts(root: Node) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    if root is Label:
        out.append((root as Label).text)
    for child in root.get_children():
        out.append_array(_collect_control_label_texts(child))
    return out


static func _run_persistence_roundtrip(failures: PackedStringArray) -> void:
    if _Persistence.active_save_path() == _Persistence.SAVE_PATH:
        _fail(failures, "P2 persistence: harness should use isolated save slot")
    else:
        _pass()
    if not _Persistence.active_save_path().contains("fallen_paths_harness"):
        _fail(failures, "P2 persistence: isolated path token missing got '%s'" % _Persistence.active_save_path())
    else:
        _pass()
    _Persistence.clear_slot()
    var world: Node2D = _make_world(0, 0, true)
    _add_player_at_camp(world)
    var pm: Node = world.get_meta("party_manager")
    var ent: Node = _add_living_entity_member(pm, "Brother0")
    ent.wounds["chest"] = [{"current_bleeding_rate": 0.6, "is_arterial": false, "severity": "moderate"}]
    ent.blood_volume = 82.0
    _EncounterSpawner.equip_weapon_id(ent, "SWORD")
    _CompanyState.set_gold(world, 777)
    _CompanyState.set_medical_supplies(world, 2)
    _CompanyState.set_renown(world, 3)
    _CompanyState.mark_tutorial_completed(world)
    world.set_meta("party_formation", {"files": 1, "ranks": 1, "density": 1.0})
    world.set_meta(_Persistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, true)
    _Persistence.mark_consumed_contract_tile(world, Vector2i(1, 0))
    var enc: Node2D = _EncounterNodeScript.new()
    enc.encounter_config = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
    enc.enemy_count = 3
    enc.contract_marker_label = "Border Skirmish"
    enc.marker_kind = "contract"
    enc.position = Vector2(160, 32)
    world.add_child(enc)
    world.get_node("Character").position = Vector2(160, 32)
    if not _Persistence.save_slot(world):
        _fail(failures, "P2 persistence: save_slot failed")
    else:
        _pass()
    var loaded: Dictionary = _Persistence.load_save()
    if int(loaded.get("version", 0)) != _Persistence.SAVE_VERSION:
        _fail(
            failures, "P2 persistence: save version want %d got %s" % [_Persistence.SAVE_VERSION, loaded.get("version")]
        )
    else:
        _pass()
    var state: Variant = loaded.get("company_state", {})
    if state is not Dictionary or int((state as Dictionary).get("gold", 0)) != 777:
        _fail(failures, "P2 persistence: JSON gold want 777 got %s" % state)
    else:
        _pass()
    var consumed: Variant = loaded.get("consumed_contract_tiles", [])
    if consumed is not Array or (consumed as Array).is_empty():
        _fail(failures, "P2 persistence: consumed_contract_tiles missing in save")
    else:
        _pass()
    var fresh: Node2D = _make_world(0, 0, true)
    _add_player_at_camp(fresh)
    var pm_fresh: Node = fresh.get_meta("party_manager")
    _add_living_entity_member(pm_fresh, "Brother0")
    var rng := RandomNumberGenerator.new()
    rng.seed = 1
    _Persistence.apply_save(fresh, loaded, rng, null)
    if _CompanyState.get_gold(fresh) != 777:
        _fail(failures, "P2 persistence: apply_save gold want 777 got %d" % _CompanyState.get_gold(fresh))
    else:
        _pass()
    if _CompanyState.get_medical_supplies(fresh) != 2:
        _fail(failures, "P2 persistence: apply_save med want 2 got %d" % _CompanyState.get_medical_supplies(fresh))
    else:
        _pass()
    if not _CompanyState.is_tutorial_completed(fresh):
        _fail(failures, "P2 persistence: tutorial_completed not restored")
    else:
        _pass()
    var pf: Dictionary = fresh.get_meta("party_formation", {}) as Dictionary
    if int(pf.get("files", 0)) != 1:
        _fail(failures, "P2 persistence: party_formation files want 1 got %d" % int(pf.get("files", 0)))
    else:
        _pass()
    var restored_ent: Node = null
    for m in pm_fresh.members:
        if m is Dictionary and str((m as Dictionary).get("name", "")) == "Brother0":
            var nr: Variant = (m as Dictionary).get("node_ref")
            if is_instance_valid(nr):
                restored_ent = _CampaignBridge.health_entity_from_character(nr as Node)
            break
    if restored_ent == null or absf(float(restored_ent.blood_volume) - 82.0) > 0.01:
        _fail(
            failures,
            (
                "P2 persistence: wound blood want 82 got %s"
                % (restored_ent.blood_volume if restored_ent != null else "null")
            )
        )
    else:
        _pass()
    if restored_ent == null or float(restored_ent.consciousness) >= 99.5:
        _fail(
            failures,
            (
                "P2 persistence: consciousness should reflect restored blood got %.1f"
                % (float(restored_ent.consciousness) if restored_ent != null else -1.0)
            )
        )
    else:
        _pass()
    if _EncounterSpawner.weapon_id_from_entity(restored_ent) != "SWORD":
        _fail(
            failures, "P2 persistence: weapon want SWORD got %s" % _EncounterSpawner.weapon_id_from_entity(restored_ent)
        )
    else:
        _pass()
    if not bool(fresh.get_meta(_Persistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, false)):
        _fail(failures, "P2 persistence: camp_heal_hint_shown not restored")
    else:
        _pass()
    var markers: int = 0
    for child in fresh.get_children():
        if child.get_script() == _EncounterNodeScript:
            markers += 1
    if markers != 1:
        _fail(failures, "P2 persistence: remaining_encounters want 1 marker got %d" % markers)
    else:
        _pass()
    if _Persistence.normalize_marker_kind_for_restore("practice", {"tutorial": false}) != "contract":
        _fail(failures, "P2 persistence: pre-marker_kind practice marker should restore as contract")
    else:
        _pass()
    if _Persistence.normalize_marker_kind_for_restore("practice", {"tutorial": true}) != "tutorial":
        _fail(failures, "P2 persistence: pre-marker_kind practice+tutorial config should restore as tutorial")
    else:
        _pass()
    var legacy_world: Node2D = _make_world(0, 0, true)
    _add_player_at_camp(legacy_world)
    var pm_legacy: Node = legacy_world.get_meta("party_manager")
    _add_living_entity_member(pm_legacy, "Brother0")
    var legacy_cfg: Dictionary = _ContractSpawner.build_encounter_config(_ContractSpawner.CONTRACT_TEMPLATES[0])
    legacy_cfg[_ContractSpawner.COMPATIBILITY_ENCOUNTER_CONFIG_KEY_TRAINING] = true
    var legacy_save: Dictionary = {
        "version": _Persistence.SAVE_VERSION,
        "company_state": {"gold": 50},
        "roster": [{"name": "Brother0", "company_mood": 50.0, "entity": {}}],
        "remaining_encounters":
        [
            {
                "tile": [1, 0],
                "encounter_config": legacy_cfg,
                "enemy_count": 2,
                "enemy_formation": {},
                "contract_marker_label": "Legacy",
                "marker_kind": "practice",
            }
        ],
        "player_tile": [0, 0],
    }
    var leg_rng := RandomNumberGenerator.new()
    leg_rng.seed = 9
    _Persistence.apply_save(legacy_world, legacy_save, leg_rng, null)
    var legacy_marker: Node2D = null
    for child in legacy_world.get_children():
        if child.get_script() == _EncounterNodeScript:
            legacy_marker = child
            break
    if legacy_marker == null:
        _fail(failures, "P2 persistence: apply_save should restore pre-marker_kind practice encounter marker")
    elif str(legacy_marker.marker_kind) != "contract":
        _fail(
            failures,
            "P2 persistence: pre-marker_kind practice marker_kind want contract got %s" % str(legacy_marker.marker_kind)
        )
    else:
        _pass()
    if (
        legacy_marker != null
        and (legacy_marker.encounter_config as Dictionary).has(
            _ContractSpawner.COMPATIBILITY_ENCOUNTER_CONFIG_KEY_TRAINING
        )
    ):
        _fail(failures, "P2 persistence: restored encounter_config should drop pre-marker_kind training flag")
    else:
        _pass()
    _release_harness_world(legacy_world)
    _Persistence.clear_slot()
    FileAccess.open(_Persistence.active_save_path(), FileAccess.WRITE).store_string('{"version":999}')
    if not _CompanyState.load_campaign_autosave_for_boot().is_empty():
        _fail(failures, "P2 persistence: load_campaign_autosave_for_boot should reject invalid save")
    else:
        _pass()
    if _Persistence.has_save():
        _fail(failures, "P2 persistence: invalid boot save should clear slot")
    else:
        _pass()
    var restore_world: Node2D = _make_world(1, 0, true)
    restore_world.set_meta(_CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, true)
    if _CompanyState.format_hud_persistence_line(restore_world) != "Restored":
        _fail(failures, "P2 persistence: HUD line want Restored after boot restore meta")
    else:
        _pass()
    _release_harness_world(restore_world)
    var autosave_world: Node2D = _make_world(1, 0, true)
    _CompanyState.set_gold(autosave_world, 321)
    if not _CompanyState.try_autosave(autosave_world):
        _fail(failures, "P2 persistence: try_autosave should write slot when P2")
    else:
        _pass()
    if autosave_world.has_meta(_CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
        autosave_world.set_meta(_CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, true)
        if not _CompanyState.try_autosave(autosave_world):
            _fail(failures, "P2 persistence: try_autosave should succeed with restored meta set")
        elif autosave_world.has_meta(_CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
            _fail(failures, "P2 persistence: try_autosave should clear restored meta after write")
        else:
            _pass()
    if _CompanyState.format_hud_persistence_line(autosave_world) != "Saved":
        _fail(
            failures,
            (
                "P2 persistence: HUD line want Saved after autosave got '%s'"
                % _CompanyState.format_hud_persistence_line(autosave_world)
            )
        )
    else:
        _pass()
    var autosave_loaded: Dictionary = _Persistence.load_save()
    var autosave_state: Variant = autosave_loaded.get("company_state", {})
    if autosave_state is not Dictionary or int((autosave_state as Dictionary).get("gold", 0)) != 321:
        _fail(failures, "P2 persistence: try_autosave gold want 321 got %s" % autosave_state)
    else:
        _pass()
    _Persistence.clear_slot()
    _release_harness_world(autosave_world)
    var day_world: Node2D = _make_world(2, 0, true)
    var day_before: int = _CompanyState.get_day_index(day_world)
    _CompanyState.try_advance_day(day_world)
    if not _Persistence.has_save():
        _fail(failures, "P2 persistence: try_advance_day should autosave when P2")
    else:
        _pass()
    var day_loaded: Dictionary = _Persistence.load_save()
    var day_state: Variant = day_loaded.get("company_state", {})
    if day_state is not Dictionary or int((day_state as Dictionary).get("day_index", 0)) != day_before + 1:
        _fail(failures, "P2 persistence: day autosave day_index want %d got %s" % [day_before + 1, day_state])
    else:
        _pass()
    _OperationalLog.begin_play_session("headless://p2_day_autosave_log", "", false, false)
    _OperationalLog.set_capture_enabled(true)
    var log_world: Node2D = _make_world(2, 0, true)
    _CompanyState.try_advance_day(log_world)
    var day_autosave_logged: bool = false
    for line in _OperationalLog.get_captured_lines():
        if str(line).contains("company_day_advanced") and str(line).contains("autosave=true"):
            day_autosave_logged = true
            break
    _OperationalLog.set_capture_enabled(false)
    _OperationalLog.end_play_session()
    if not day_autosave_logged:
        _fail(failures, "P2 persistence: company_day_advanced should log autosave=true")
    else:
        _pass()
    _release_harness_world(log_world)
    _Persistence.clear_slot()
    _release_harness_world(day_world)
    if _Persistence.has_save():
        _fail(failures, "P2 persistence: clear_slot should remove save file")
    else:
        _pass()
    FileAccess.open(_Persistence.active_save_path(), FileAccess.WRITE).store_string(
        '{"version":1,"company_state":{},"roster":[{}]}'
    )
    if _Persistence.is_valid_save(_Persistence.load_save()):
        _fail(failures, "P2 persistence: save version 1 should not validate")
    else:
        _pass()
    FileAccess.open(_Persistence.active_save_path(), FileAccess.WRITE).store_string('{"version":999}')
    if _Persistence.is_valid_save(_Persistence.load_save()):
        _fail(failures, "P2 persistence: wrong version should not validate")
    else:
        _pass()
    if _Persistence.has_save():
        _Persistence.clear_slot()
    _release_harness_world(world)
    _release_harness_world(fresh)
    _cleanup_harness_ui_overlay()
