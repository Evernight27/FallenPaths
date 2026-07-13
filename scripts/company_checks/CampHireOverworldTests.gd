class_name CompanyChecksCampHireOverworldTests
extends CompanyChecksCore
## Headless Camp-1 economy loop + Camp-2 spot checks + XCamp-3.x + P2 persistence roundtrip.
## Run: .\scripts\run_company_state_checks.ps1
## Labels: Camp-1.x / XCamp-3.x in failure messages map to SHIP_PLAN S Camp-1 / EXPANSION_PLAN Exp-3.
## Gate: stdout `FP_HARNESS_OK: CompanyStateChecks` (test count in message; sync `scripts/README.md`).
## P2 rows use `CampaignPersistence.begin_harness_isolated_save()`  -  production `user://fallen_paths_slot0.json`
## untouched.
## Fails if any `SCRIPT_ERROR` is logged during the run (`FallenPathsErrorLogger` tally).

const CHARACTER_SCRIPT := preload("res://character.gd")
const HARNESS_NAME := "CompanyStateChecks"


static func _run_hire_rookie(failures: PackedStringArray) -> void:
    var world: Node2D = _instantiate_main_hire_world(true)
    _trim_party_to_leader(world)
    if CompanyState.count_living_roster(world) != 1:
        _fail(failures, "XCamp-3.1: trimmed roster want 1 living got %d" % CompanyState.count_living_roster(world))
    else:
        _pass()
    if PartySetup.find_vacant_companion_node(world) == null:
        _fail(failures, "XCamp-3.1: vacant companion slot expected after trim")
    else:
        _pass()
    CompanyState.set_gold(world, CompanyState.HIRE_GOLD_COST + 50)
    var rng := RandomNumberGenerator.new()
    rng.seed = 99
    if not CompanyState.try_hire_rookie(world, rng, true):
        _fail(failures, "XCamp-3.1: hire should succeed from Party menu with gold and vacant slot")
    else:
        _pass()
    if CompanyState.count_living_roster(world) != 2:
        _fail(failures, "XCamp-3.1: roster after hire want 2 living got %d" % CompanyState.count_living_roster(world))
    else:
        _pass()
    if CompanyState.get_gold(world) != 50:
        _fail(failures, "XCamp-3.1: gold after hire want 50 got %d" % CompanyState.get_gold(world))
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
    if not CompanyState.roster_has_hire_room(world):
        _fail(failures, "XCamp-3.1: roster should still have hire room after one replacement")
    else:
        _pass()
    if PartySetup.find_vacant_companion_node(world) == null:
        _fail(failures, "XCamp-3.1: additional vacant companion slots expected after one hire")
    else:
        _pass()
    CompanyState.set_gold(world, 0)
    if CompanyState.can_offer_hire(world, true):
        _fail(failures, "XCamp-3.1: broke company should not offer hire")
    else:
        _pass()
    var broke_reason: String = CompanyState.format_hire_block_reason(world, true)
    if not broke_reason.contains("need"):
        _fail(failures, "XCamp-3.1: broke hire reason should mention gold got '%s'" % broke_reason)
    else:
        _pass()
    var full_world: Node2D = _instantiate_main_hire_world(true)
    if CompanyState.count_living_roster(full_world) != CompanyState.ROSTER_MAX_LIVING:
        _fail(
            failures,
            (
                "XCamp-3.1: full roster want %d living got %d"
                % [CompanyState.ROSTER_MAX_LIVING, CompanyState.count_living_roster(full_world)]
            )
        )
    else:
        _pass()
    if CompanyState.can_offer_hire(full_world, true):
        _fail(failures, "XCamp-3.1: full roster should block hire")
    else:
        _pass()
    _free_harness_world(full_world)
    _free_harness_world(world)

    CampaignPersistence.clear_slot()
    var persist_world: Node2D = _instantiate_main_hire_world(true)
    var pm_persist: Node = persist_world.get_meta("party_manager")
    for trim_i in range(2, 7):
        pm_persist.remove_member_by_name("Companion" + str(trim_i))
    CompanyState.set_gold(persist_world, 500)
    var persist_rng := RandomNumberGenerator.new()
    persist_rng.seed = 77
    if not CompanyState.try_hire_rookie(persist_world, persist_rng, true):
        _fail(failures, "XCamp-3.1 P2: hire before save should succeed")
    else:
        _pass()
    if not CampaignPersistence.save_slot(persist_world):
        _fail(failures, "XCamp-3.1 P2: save_slot after hire failed")
    else:
        _pass()
    var hire_loaded: Dictionary = CampaignPersistence.load_save()
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
    CampaignPersistence.apply_save(fresh_hire, hire_loaded, restore_rng, null)
    if CompanyState.count_living_roster(fresh_hire) != 3:
        _fail(failures, "XCamp-3.1 P2: restore living want 3 got %d" % CompanyState.count_living_roster(fresh_hire))
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _free_harness_world(persist_world)
    _free_harness_world(fresh_hire)


# --- XCamp-3.2 overworld map ---


static func _run_overworld_map_5x5(failures: PackedStringArray) -> void:
    if OverworldMap.MAP_TILES != 5:
        _fail(failures, "XCamp-3.2: MAP_TILES want 5 got %d" % OverworldMap.MAP_TILES)
    else:
        _pass()
    if OverworldMap.all_tiles().size() != 25:
        _fail(failures, "XCamp-3.2: all_tiles want 25 got %d" % OverworldMap.all_tiles().size())
    else:
        _pass()
    if not OverworldMap.is_tile_in_bounds(Vector2i(4, 4)):
        _fail(failures, "XCamp-3.2: tile (4,4) should be in bounds")
    else:
        _pass()
    if OverworldMap.is_tile_in_bounds(Vector2i(5, 0)):
        _fail(failures, "XCamp-3.2: tile (5,0) should be out of bounds")
    else:
        _pass()
    var spawn_world: Node2D = _make_overworld_spawn_world(true)
    CompanyState.attach_to_world(spawn_world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 5151
    ContractSpawner.spawn_campaign_contracts(spawn_world, rng, null)
    var markers: int = _count_encounter_markers(spawn_world)
    var want_markers: int = 1 + ContractSpawner.get_template_count()
    if markers != want_markers:
        _fail(failures, "XCamp-3.2: contract markers want %d (tutorial + paid) got %d" % [want_markers, markers])
    else:
        _pass()
    var markers_ok: bool = true
    for child in spawn_world.get_children():
        if child.get_script() != EncounterNode:
            continue
        var tile: Vector2i = spawn_world.call("_tile_coords", child.position) as Vector2i
        if not OverworldMap.is_tile_in_bounds(tile, spawn_world):
            _fail(failures, "XCamp-3.2: marker tile OOB %s" % tile)
            markers_ok = false
            break
        if tile == ContractSpawner.CAMP_TILE:
            _fail(failures, "XCamp-3.2: contract should not spawn on camp tile")
            markers_ok = false
            break
    if markers_ok:
        _pass()
    CampaignPersistence.clear_slot()
    CompanyState.set_gold(spawn_world, 888)
    spawn_world.get_node("Character").position = OverworldMap.tile_center(Vector2i(3, 2))
    if not CampaignPersistence.save_slot(spawn_world):
        _fail(failures, "XCamp-3.2 P2: save on 5- - 5 map failed")
    else:
        _pass()
    var map_loaded: Dictionary = CampaignPersistence.load_save()
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
    CompanyState.attach_to_world(fresh_map)
    CampaignPersistence.apply_save(fresh_map, map_loaded, rng, null)
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
    CampaignPersistence.clear_slot()
    _free_harness_world(spawn_world)
    _free_harness_world(fresh_map)


static func _run_contract_deck_refresh(failures: PackedStringArray) -> void:
    var world: Node2D = _make_overworld_spawn_world(true)
    var pm: Node = _new_party_manager()
    world.add_child(pm)
    world.set_meta("party_manager", pm)
    _add_living_entity_member(pm, "DeckBro")
    CompanyState.attach_to_world(world)
    CompanyState.mark_tutorial_completed(world)
    var rng := RandomNumberGenerator.new()
    rng.seed = 3333
    ContractSpawner.spawn_campaign_contracts(world, rng, null)
    if ContractSpawner.count_paid_contract_markers(world) != ContractSpawner.get_template_count():
        _fail(
            failures,
            (
                "XCamp-3.3: initial paid markers want %d got %d"
                % [
                    ContractSpawner.get_template_count(),
                    ContractSpawner.count_paid_contract_markers(world),
                ]
            )
        )
    else:
        _pass()
    if ContractSpawner.try_refresh_contract_deck(world, null) != 0:
        _fail(failures, "XCamp-3.3: refresh should not run while paid markers remain")
    else:
        _pass()
    _clear_paid_contract_markers(world)
    if ContractSpawner.count_paid_contract_markers(world) != 0:
        _fail(failures, "XCamp-3.3: harness should clear paid markers")
    else:
        _pass()
    var deck_hint: String = ContractSpawner.format_settlement_deck_refresh_hint(world)
    if not deck_hint.contains("new jobs"):
        _fail(failures, "XCamp-3.3: deck refresh hint expected got '%s'" % deck_hint)
    else:
        _pass()
    var placed: int = ContractSpawner.try_refresh_contract_deck(world, null)
    if placed != ContractSpawner.get_template_count():
        _fail(
            failures, "XCamp-3.3: deck refresh want %d placed got %d" % [ContractSpawner.get_template_count(), placed]
        )
    else:
        _pass()
    if CompanyState.get_contract_deck_index(world) != 1:
        _fail(failures, "XCamp-3.3: contract_deck_index want 1 got %d" % CompanyState.get_contract_deck_index(world))
    else:
        _pass()
    if ContractSpawner.try_refresh_contract_deck(world, null) != 0:
        _fail(failures, "XCamp-3.3: second refresh should not run until wave cleared")
    else:
        _pass()
    CampaignPersistence.clear_slot()
    if not CampaignPersistence.save_slot(world):
        _fail(failures, "XCamp-3.3 P2: save with deck_index failed")
    else:
        _pass()
    var deck_loaded: Dictionary = CampaignPersistence.load_save()
    var deck_state: Variant = deck_loaded.get("company_state", {})
    if deck_state is not Dictionary or int((deck_state as Dictionary).get("contract_deck_index", 0)) != 1:
        _fail(failures, "XCamp-3.3 P2: contract_deck_index not saved got %s" % deck_state)
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _free_harness_world(world)


static func _run_xcamp_34_affliction_catalog(failures: PackedStringArray) -> void:
    if CampaignAfflictions.CATALOG_IDS.size() < 6:
        _fail(failures, "XCamp-3.4: affliction catalog want >= 6 ids")
    else:
        _pass()
    var lung: Dictionary = CampaignAfflictions.catalog_def(CampaignAfflictions.AFFLICTION_PARTLY_COLLAPSED_LUNG)
    if float(lung.get("stamina_mult", 1.0)) > 0.86:
        _fail(failures, "XCamp-3.4: collapsed lung stamina debuff expected")
    else:
        _pass()
    var grip: Dictionary = CampaignAfflictions.catalog_def(CampaignAfflictions.AFFLICTION_SHAKY_GRIP, "right_arm")
    if str(grip.get("label", "")) != "Shaky grip":
        _fail(failures, "XCamp-3.4: shaky grip label")
    else:
        _pass()
    var scar_line: String = CampaignAfflictions.format_scar_line("Brother", lung)
    if not scar_line.contains("Stamina"):
        _fail(failures, "XCamp-3.4: scar line should include stamina effect got '%s'" % scar_line)
    else:
        _pass()
    var ent: Node = _harness_core_entity()
    ent.apply_species()
    if CampaignAfflictions._bone_affliction_id("left_arm") != CampaignAfflictions.AFFLICTION_SHAKY_GRIP:
        _fail(failures, "XCamp-3.4: crippled arm should map to shaky_grip")
    else:
        _pass()
    if CampaignAfflictions._bone_affliction_id("left_leg") != CampaignAfflictions.AFFLICTION_LIMPING_LIMB:
        _fail(failures, "XCamp-3.4: crippled leg should map to limping_limb")
    else:
        _pass()
    if CampaignAfflictions._bone_affliction_id("chest") != CampaignAfflictions.AFFLICTION_CRACKED_RIBS:
        _fail(failures, "XCamp-3.4: crippled chest should map to cracked_ribs")
    else:
        _pass()
    if not ent._add_campaign_affliction(lung):
        _fail(failures, "XCamp-3.4: should add catalog affliction")
    else:
        _pass()
    if ent._add_campaign_affliction(lung):
        _fail(failures, "XCamp-3.4: duplicate affliction id should be rejected")
    else:
        _pass()
    var aff_world: Node2D = _make_world(1, 0, true)
    CompanyState.attach_to_world(aff_world)
    var pm: Node = aff_world.get_meta("party_manager")
    var bro: Node = _add_living_entity_member(pm, "ScarBro")
    bro._add_campaign_affliction(CampaignAfflictions.catalog_def(CampaignAfflictions.AFFLICTION_OLD_WOUND_ACHE))
    if CampaignAfflictions.count_scarred_brothers(aff_world) != 1:
        _fail(
            failures,
            "XCamp-3.4: count_scarred_brothers want 1 got %d" % CampaignAfflictions.count_scarred_brothers(aff_world)
        )
    else:
        _pass()
    CampaignPersistence.clear_slot()
    if not CampaignPersistence.save_slot(aff_world):
        _fail(failures, "XCamp-3.4 P2: save with afflictions failed")
    else:
        _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
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
    CampaignPersistence.clear_slot()
    _free_harness_core_entity(ent)
    _release_harness_world(aff_world)


static func _run_xcamp_35_camp_tavern_mood(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(0, 0, true)
    CompanyState.attach_to_world(world)
    var pm: Node = world.get_meta("party_manager")
    var bro_a: Node = _add_living_entity_member(pm, "TavernA")
    var bro_b: Node = _add_living_entity_member(pm, "TavernB")
    pm.members[0]["company_mood"] = 49.0
    pm.members[1]["company_mood"] = 50.0
    _add_player_at_camp(world)
    CompanyState.set_medical_supplies(world, 2)
    if not CompanyState.try_camp_heal(world, true):
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
    var label: String = CompanyState.format_camp_rest_button_label(world, true)
    if not label.contains("+1 mood"):
        _fail(failures, "XCamp-3.5: camp rest label should mention mood got '%s'" % label)
    else:
        _pass()
    _release_harness_world(world)


static func _run_xcamp_36_provisions(failures: PackedStringArray) -> void:
    var fed_world: Node2D = _make_world(2)
    CompanyState.attach_to_world(fed_world)
    CompanyState.set_food_supplies(fed_world, 2)
    var pm_fed: Node = fed_world.get_meta("party_manager")
    for raw in pm_fed.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 50.0
    if not CompanyState.try_advance_day(fed_world):
        _fail(failures, "XCamp-3.6: try_advance_day should succeed")
    else:
        _pass()
    if CompanyState.get_food_supplies(fed_world) != 0:
        _fail(
            failures, "XCamp-3.6: fed roster should consume 2 food got %d" % CompanyState.get_food_supplies(fed_world)
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
    CompanyState.attach_to_world(short_world)
    CompanyState.set_food_supplies(short_world, 1)
    var pm_short: Node = short_world.get_meta("party_manager")
    for raw in pm_short.members:
        if raw is Dictionary:
            (raw as Dictionary)["company_mood"] = 50.0
    if not CompanyState.try_advance_day(short_world):
        _fail(failures, "XCamp-3.6: day tick with short food should still advance day")
    else:
        _pass()
    if CompanyState.get_food_supplies(short_world) != 0:
        _fail(failures, "XCamp-3.6: short food should consume remaining rations")
    else:
        _pass()
    var short_mood: float = float(pm_short.members[0].get("company_mood", 50.0))
    if not is_equal_approx(short_mood, 49.0):
        _fail(failures, "XCamp-3.6: not fed mood want 49 got %.2f" % short_mood)
    else:
        _pass()
    var prov_end_world: Node2D = _make_world(2)
    CompanyState.attach_to_world(prov_end_world)
    CompanyState.set_food_supplies(prov_end_world, 0)
    var prov_end_lbl: String = CompanyState.format_end_day_button_label(prov_end_world)
    if not prov_end_lbl.contains("rations short"):
        _fail(failures, "XCamp-3.6: End day button should warn when rations short got '%s'" % prov_end_lbl)
    else:
        _pass()
    var prov_camp_world: Node2D = _make_world(2)
    CompanyState.attach_to_world(prov_camp_world)
    CompanyState.set_food_supplies(prov_camp_world, 0)
    var prov_camp_lbl: String = CompanyState.format_camp_rest_button_label(prov_camp_world, true)
    if not prov_camp_lbl.contains("rations short"):
        _fail(failures, "XCamp-3.6: Camp rest button should warn when rations short got '%s'" % prov_camp_lbl)
    else:
        _pass()
    var prov_hud_suffix: String = CompanyState.format_hud_provisions_suffix(prov_camp_world)
    if not prov_hud_suffix.contains("rations short"):
        _fail(failures, "XCamp-3.6: Party title provisions suffix expected got '%s'" % prov_hud_suffix)
    else:
        _pass()
    var prov_hud_hints: PackedStringArray = CompanyState.format_hud_economy_hint_lines(
        CompanyState.get_state(prov_camp_world), 2, prov_camp_world
    )
    if prov_hud_hints.is_empty() or not str(prov_hud_hints[0]).contains("rations"):
        _fail(failures, "XCamp-3.6: HUD economy hint should include rations got %s" % str(prov_hud_hints))
    else:
        _pass()
    _release_harness_world(prov_camp_world)
    CampaignPersistence.clear_slot()
    CompanyState.set_food_supplies(short_world, 7)
    if not CampaignPersistence.save_slot(short_world):
        _fail(failures, "XCamp-3.6 P2: save with food failed")
    else:
        _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
    var food_state: Variant = (loaded.get("company_state", {}) as Dictionary).get("food_supplies", -1)
    if int(food_state) != 7:
        _fail(failures, "XCamp-3.6 P2: food_supplies want 7 got %s" % str(food_state))
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _release_harness_world(short_world)


static func _run_xcamp_37_burial_costs(failures: PackedStringArray) -> void:
    var world: Node2D = _make_world(1)
    CompanyState.set_gold(world, 100)
    (
        world
        . set_meta(
            CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {"deaths": [{"name": "Brother0", "part": "chest", "cause": "exsanguination"}]},
        )
    )
    var lines: PackedStringArray = CompanyState.apply_settlement_burial_costs(world)
    if CompanyState.get_gold(world) != 100 - CompanyState.BURIAL_GOLD_COST:
        _fail(
            failures,
            (
                "XCamp-3.7: burial cost want gold %d got %d"
                % [
                    100 - CompanyState.BURIAL_GOLD_COST,
                    CompanyState.get_gold(world),
                ]
            )
        )
    else:
        _pass()
    if lines.is_empty() or not str(lines[0]).contains("Burial"):
        _fail(failures, "XCamp-3.7: burial line expected got %s" % str(lines))
    else:
        _pass()
    if CompanyState.compute_settlement_burial_cost(world) != CompanyState.BURIAL_GOLD_COST:
        _fail(
            failures,
            (
                "XCamp-3.7: compute_settlement_burial_cost want %d got %d"
                % [CompanyState.BURIAL_GOLD_COST, CompanyState.compute_settlement_burial_cost(world)]
            )
        )
    else:
        _pass()
    var debt_preview_world: Node2D = _make_world(1)
    CompanyState.set_gold(debt_preview_world, 10)
    (
        debt_preview_world
        . set_meta(
            CompanyState.WORLD_META_LAST_BATTLE_SUMMARY,
            {"deaths": [{"name": "Brother0", "part": "chest", "cause": "exsanguination"}]},
        )
    )
    var debt_warn: String = CompanyState.format_settlement_burial_debt_warning(debt_preview_world)
    if not debt_warn.contains("Burial") or not debt_warn.contains("debt"):
        _fail(failures, "XCamp-3.7: burial debt warning expected got '%s'" % debt_warn)
    else:
        _pass()
    _release_harness_world(debt_preview_world)
    var no_death_world: Node2D = _make_world(1)
    CompanyState.set_gold(no_death_world, 50)
    no_death_world.set_meta(CompanyState.WORLD_META_LAST_BATTLE_SUMMARY, {"deaths": []})
    if not CompanyState.apply_settlement_burial_costs(no_death_world).is_empty():
        _fail(failures, "XCamp-3.7: no deaths should not charge burial")
    else:
        _pass()
    if CompanyState.get_gold(no_death_world) != 50:
        _fail(failures, "XCamp-3.7: gold should be unchanged without deaths")
    else:
        _pass()
    _release_harness_world(world)
    _release_harness_world(no_death_world)


static func _run_xcamp_38_ms_camp_bridge(failures: PackedStringArray) -> void:
    if CompanyState.stance_preference_for_campaign_mood(10.0) != CombatWeaponForm.FORM_WALL:
        _fail(failures, "XCamp-3.8: low mood should map to wall")
    else:
        _pass()
    if CompanyState.stance_preference_for_campaign_mood(80.0) != CombatWeaponForm.FORM_WRATH:
        _fail(failures, "XCamp-3.8: high mood should map to wrath")
    else:
        _pass()
    if CompanyState.stance_preference_for_campaign_mood(50.0) != CombatWeaponForm.FORM_BALANCED:
        _fail(failures, "XCamp-3.8: mid mood should map to balanced")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    var pm: Node = world.get_meta("party_manager")
    var char_script: Script = CHARACTER_SCRIPT as Script
    var fighter := CharacterBody2D.new()
    fighter.set_script(char_script)
    fighter.name = "MoodFighter"
    pm.add_child(fighter)
    pm.members[0]["node_ref"] = fighter
    pm.members[0]["company_mood"] = 12.0
    CampaignEncounterBridge.apply_campaign_mood_stance_preferences(world)
    if str(fighter.get("stance_preference")) != CombatWeaponForm.FORM_WALL:
        _fail(
            failures,
            "XCamp-3.8: bridge should stamp wall for angry mood got '%s'" % str(fighter.get("stance_preference"))
        )
    else:
        _pass()
    fighter.set("stance_preference", "fool")
    pm.members[0]["company_mood"] = 12.0
    CampaignEncounterBridge.apply_campaign_mood_stance_preferences(world)
    if str(fighter.get("stance_preference")) != "fool":
        _fail(failures, "XCamp-3.8: explicit stance_preference should not be overwritten")
    else:
        _pass()
    var stance_hint: String = CompanyState.format_settlement_low_mood_stance_hint(world)
    if not stance_hint.contains("wall"):
        _fail(failures, "XCamp-3.8: low mood settlement hint expected got '%s'" % stance_hint)
    else:
        _pass()
    _release_harness_world(world)


## XCamp-3.9: campaign mood bias -> mental stack weight multipliers via bridge meta.


## XCamp-3.9: campaign mood bias -> mental stack weight multipliers via bridge meta.
static func _run_xcamp_39_mood_bias_to_ms(failures: PackedStringArray) -> void:
    var MoodBias := preload("res://combat/CombatCampaignMoodBias.gd")
    # Basic multiplier boundaries: low mood (<=25) -> defensive bias, high mood (>=70) -> aggressive bias.
    if MoodBias.wait_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should increase wait weight above 1.0")
    else:
        _pass()
    if MoodBias.wait_action_weight_mult(25.0) != 1.0:
        _fail(failures, "XCamp-3.9: mood=25 should be neutral for wait (1.0)")
    else:
        _pass()
    if MoodBias.wait_action_weight_mult(70.0) < 1.0 or MoodBias.wait_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should be neutral for wait (1.0)")
    else:
        _pass()
    if MoodBias.offense_action_weight_mult(0.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should damp offense below 1.0")
    else:
        _pass()
    if MoodBias.offense_action_weight_mult(25.0) != 1.0:
        _fail(failures, "XCamp-3.9: mood=25 should be neutral for offense (1.0)")
    else:
        _pass()
    if MoodBias.offense_action_weight_mult(70.0) <= 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should boost offense above 1.0")
    else:
        _pass()
    if MoodBias.focus_line_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost focus above 1.0")
    else:
        _pass()
    if MoodBias.focus_line_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp focus below 1.0")
    else:
        _pass()
    if MoodBias.flee_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost flee above 1.0")
    else:
        _pass()
    if MoodBias.flee_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp flee below 1.0")
    else:
        _pass()
    if MoodBias.disengage_action_weight_mult(0.0) < 1.0:
        _fail(failures, "XCamp-3.9: mood=0 should boost disengage above 1.0")
    else:
        _pass()
    if MoodBias.disengage_action_weight_mult(70.0) > 1.0:
        _fail(failures, "XCamp-3.9: mood=70 should damp disengage below 1.0")
    else:
        _pass()
    # Batch compute returns all multipliers.
    var batch: Dictionary = MoodBias.compute_all_multipliers(50.0)
    if not batch.has("wait_mult") or not batch.has("offense_mult"):
        _fail(failures, "XCamp-3.9: compute_all_multipliers should return wait_mult and offense_mult")
    else:
        _pass()
    var world: Node2D = _make_world(1)
    world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1})
    var pm: Node = world.get_meta("party_manager")
    var char_script := CHARACTER_SCRIPT as Script
    var fighter := CharacterBody2D.new()
    fighter.set_script(char_script)
    fighter.name = "MoodBiasFighter"
    pm.add_child(fighter)
    pm.members[0]["node_ref"] = fighter
    pm.members[0]["company_mood"] = 15.0
    CampaignEncounterBridge.apply_campaign_mood_bias_to_encounter(world)
    var enc: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if not enc.has(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER):
        _fail(failures, "XCamp-3.9: encounter meta should have mood bias key")
    else:
        _pass()
    var biased_val: float = float(enc.get(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER, 50.0))
    if biased_val > 20.0:
        _fail(failures, "XCamp-3.9: mood bias should reflect low roster mood (~=15) got %.1f" % biased_val)
    else:
        _pass()
    pm.members[0]["company_mood"] = 85.0
    CampaignEncounterBridge.apply_campaign_mood_bias_to_encounter(world)
    var enc2: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var high_val: float = float(enc2.get(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_PLAYER, 50.0))
    if high_val < 80.0:
        _fail(failures, "XCamp-3.9: mood bias should reflect high roster mood (~=85) got %.1f" % high_val)
    else:
        _pass()
    # Enemy side: default 50.0 when no enemy_mood_bias in encounter config.
    var world2: Node2D = _make_world(1)
    world2.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1})
    CampaignEncounterBridge.apply_campaign_mood_bias_to_encounter(world2)
    var enc3: Dictionary = world2.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_default: float = float(enc3.get(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_default != 50.0:
        _fail(failures, "XCamp-3.9: enemy mood bias default should be 50.0 (neutral), got %.1f" % enemy_default)
    else:
        _pass()
    # Enemy side: explicit enemy_mood_bias from encounter config.
    var world3: Node2D = _make_world(1)
    world3.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1, "enemy_mood_bias": 10.0})
    CampaignEncounterBridge.apply_campaign_mood_bias_to_encounter(world3)
    var enc4: Dictionary = world3.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_low: float = float(enc4.get(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_low < 5.0 or enemy_low > 15.0:
        _fail(failures, "XCamp-3.9: enemy mood bias should reflect encounter config (~=10), got %.1f" % enemy_low)
    else:
        _pass()
    # Enemy side: clamp at 100 boundary.
    var world4: Node2D = _make_world(1)
    world4.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {"difficulty_rating": 1, "enemy_mood_bias": 200.0})
    CampaignEncounterBridge.apply_campaign_mood_bias_to_encounter(world4)
    var enc5: Dictionary = world4.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    var enemy_clamped: float = float(enc5.get(MoodBias.ENCOUNTER_KEY_MOOD_BIAS_ENEMY, -1.0))
    if enemy_clamped != 100.0:
        _fail(failures, "XCamp-3.9: enemy mood bias should clamp at 100 (got %.1f)" % enemy_clamped)
    else:
        _pass()
    _release_harness_world(world2)
    _release_harness_world(world3)
    _release_harness_world(world4)

# --- Camp-2+ (spot checks; full gates in combat harness) ---
