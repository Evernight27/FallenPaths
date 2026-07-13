class_name CompanyStateChecksHarnessPartE
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


static func _run_persistence_roundtrip(failures: PackedStringArray) -> void:
    if CampaignPersistence.active_save_path() == CampaignPersistence.SAVE_PATH:
        _fail(failures, "P2 persistence: harness should use isolated save slot")
    else:
        _pass()
    if not CampaignPersistence.active_save_path().contains("fallen_paths_harness"):
        _fail(failures, "P2 persistence: isolated path token missing got '%s'" % CampaignPersistence.active_save_path())
    else:
        _pass()
    CampaignPersistence.clear_slot()
    var world: Node2D = _make_world(0, 0, true)
    _add_player_at_camp(world)
    var pm: Node = world.get_meta("party_manager")
    var ent: Node = _add_living_entity_member(pm, "Brother0")
    ent.wounds["chest"] = [{"current_bleeding_rate": 0.6, "is_arterial": false, "severity": "moderate"}]
    ent.blood_volume = 82.0
    EncounterSpawner.equip_weapon_id(ent, "SWORD")
    CompanyState.set_gold(world, 777)
    CompanyState.set_medical_supplies(world, 2)
    CompanyState.set_renown(world, 3)
    CompanyState.mark_tutorial_completed(world)
    world.set_meta("party_formation", {"files": 1, "ranks": 1, "density": 1.0})
    world.set_meta(CampaignPersistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, true)
    CampaignPersistence.mark_consumed_contract_tile(world, Vector2i(1, 0))
    var enc: Node2D = EncounterNode.new()
    enc.encounter_config = ContractSpawner.build_encounter_config(ContractSpawner.CONTRACT_TEMPLATES[0])
    enc.enemy_count = 3
    enc.contract_marker_label = "Border Skirmish"
    enc.marker_kind = "contract"
    enc.position = Vector2(160, 32)
    world.add_child(enc)
    world.get_node("Character").position = Vector2(160, 32)
    if not CampaignPersistence.save_slot(world):
        _fail(failures, "P2 persistence: save_slot failed")
    else:
        _pass()
    var loaded: Dictionary = CampaignPersistence.load_save()
    if int(loaded.get("version", 0)) != CampaignPersistence.SAVE_VERSION:
        _fail(
            failures,
            "P2 persistence: save version want %d got %s" % [CampaignPersistence.SAVE_VERSION, loaded.get("version")]
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
    CampaignPersistence.apply_save(fresh, loaded, rng, null)
    if CompanyState.get_gold(fresh) != 777:
        _fail(failures, "P2 persistence: apply_save gold want 777 got %d" % CompanyState.get_gold(fresh))
    else:
        _pass()
    if CompanyState.get_medical_supplies(fresh) != 2:
        _fail(failures, "P2 persistence: apply_save med want 2 got %d" % CompanyState.get_medical_supplies(fresh))
    else:
        _pass()
    if not CompanyState.is_tutorial_completed(fresh):
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
                restored_ent = CampaignEncounterBridge.health_entity_from_character(nr as Node)
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
    if EncounterSpawner.weapon_id_from_entity(restored_ent) != "SWORD":
        _fail(
            failures, "P2 persistence: weapon want SWORD got %s" % EncounterSpawner.weapon_id_from_entity(restored_ent)
        )
    else:
        _pass()
    if not bool(fresh.get_meta(CampaignPersistence.WORLD_META_CAMP_HEAL_HINT_SHOWN, false)):
        _fail(failures, "P2 persistence: camp_heal_hint_shown not restored")
    else:
        _pass()
    var markers: int = 0
    for child in fresh.get_children():
        if child.get_script() == EncounterNode:
            markers += 1
    if markers != 1:
        _fail(failures, "P2 persistence: remaining_encounters want 1 marker got %d" % markers)
    else:
        _pass()
    if CampaignPersistence.normalize_marker_kind_for_restore("practice", {"tutorial": false}) != "contract":
        _fail(failures, "P2 persistence: pre-marker_kind practice marker should restore as contract")
    else:
        _pass()
    if CampaignPersistence.normalize_marker_kind_for_restore("practice", {"tutorial": true}) != "tutorial":
        _fail(failures, "P2 persistence: pre-marker_kind practice+tutorial config should restore as tutorial")
    else:
        _pass()
    var legacy_world: Node2D = _make_world(0, 0, true)
    _add_player_at_camp(legacy_world)
    var pm_legacy: Node = legacy_world.get_meta("party_manager")
    _add_living_entity_member(pm_legacy, "Brother0")
    var legacy_cfg: Dictionary = ContractSpawner.build_encounter_config(ContractSpawner.CONTRACT_TEMPLATES[0])
    legacy_cfg[ContractSpawner.COMPATIBILITY_ENCOUNTER_CONFIG_KEY_TRAINING] = true
    var legacy_save: Dictionary = {
        "version": CampaignPersistence.SAVE_VERSION,
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
    CampaignPersistence.apply_save(legacy_world, legacy_save, leg_rng, null)
    var legacy_marker: Node2D = null
    for child in legacy_world.get_children():
        if child.get_script() == EncounterNode:
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
            ContractSpawner.COMPATIBILITY_ENCOUNTER_CONFIG_KEY_TRAINING
        )
    ):
        _fail(failures, "P2 persistence: restored encounter_config should drop pre-marker_kind training flag")
    else:
        _pass()
    _release_harness_world(legacy_world)
    CampaignPersistence.clear_slot()
    FileAccess.open(CampaignPersistence.active_save_path(), FileAccess.WRITE).store_string('{"version":999}')
    if not CompanyState.load_campaign_autosave_for_boot().is_empty():
        _fail(failures, "P2 persistence: load_campaign_autosave_for_boot should reject invalid save")
    else:
        _pass()
    if CampaignPersistence.has_save():
        _fail(failures, "P2 persistence: invalid boot save should clear slot")
    else:
        _pass()
    var restore_world: Node2D = _make_world(1, 0, true)
    restore_world.set_meta(CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, true)
    if CompanyState.format_hud_persistence_line(restore_world) != "Restored":
        _fail(failures, "P2 persistence: HUD line want Restored after boot restore meta")
    else:
        _pass()
    _release_harness_world(restore_world)
    var autosave_world: Node2D = _make_world(1, 0, true)
    CompanyState.set_gold(autosave_world, 321)
    if not CompanyState.try_autosave(autosave_world):
        _fail(failures, "P2 persistence: try_autosave should write slot when P2")
    else:
        _pass()
    if autosave_world.has_meta(CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
        autosave_world.set_meta(CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE, true)
        if not CompanyState.try_autosave(autosave_world):
            _fail(failures, "P2 persistence: try_autosave should succeed with restored meta set")
        elif autosave_world.has_meta(CompanyState.WORLD_META_CAMPAIGN_RESTORED_FROM_SAVE):
            _fail(failures, "P2 persistence: try_autosave should clear restored meta after write")
        else:
            _pass()
    if CompanyState.format_hud_persistence_line(autosave_world) != "Saved":
        _fail(
            failures,
            (
                "P2 persistence: HUD line want Saved after autosave got '%s'"
                % CompanyState.format_hud_persistence_line(autosave_world)
            )
        )
    else:
        _pass()
    var autosave_loaded: Dictionary = CampaignPersistence.load_save()
    var autosave_state: Variant = autosave_loaded.get("company_state", {})
    if autosave_state is not Dictionary or int((autosave_state as Dictionary).get("gold", 0)) != 321:
        _fail(failures, "P2 persistence: try_autosave gold want 321 got %s" % autosave_state)
    else:
        _pass()
    CampaignPersistence.clear_slot()
    _release_harness_world(autosave_world)
    var day_world: Node2D = _make_world(2, 0, true)
    var day_before: int = CompanyState.get_day_index(day_world)
    CompanyState.try_advance_day(day_world)
    if not CampaignPersistence.has_save():
        _fail(failures, "P2 persistence: try_advance_day should autosave when P2")
    else:
        _pass()
    var day_loaded: Dictionary = CampaignPersistence.load_save()
    var day_state: Variant = day_loaded.get("company_state", {})
    if day_state is not Dictionary or int((day_state as Dictionary).get("day_index", 0)) != day_before + 1:
        _fail(failures, "P2 persistence: day autosave day_index want %d got %s" % [day_before + 1, day_state])
    else:
        _pass()
    OperationalLog.begin_play_session("headless://p2_day_autosave_log", "", false, false)
    OperationalLog.set_capture_enabled(true)
    var log_world: Node2D = _make_world(2, 0, true)
    CompanyState.try_advance_day(log_world)
    var day_autosave_logged: bool = false
    for line in OperationalLog.get_captured_lines():
        if str(line).contains("company_day_advanced") and str(line).contains("autosave=true"):
            day_autosave_logged = true
            break
    OperationalLog.set_capture_enabled(false)
    OperationalLog.end_play_session()
    if not day_autosave_logged:
        _fail(failures, "P2 persistence: company_day_advanced should log autosave=true")
    else:
        _pass()
    _release_harness_world(log_world)
    CampaignPersistence.clear_slot()
    _release_harness_world(day_world)
    if CampaignPersistence.has_save():
        _fail(failures, "P2 persistence: clear_slot should remove save file")
    else:
        _pass()
    FileAccess.open(CampaignPersistence.active_save_path(), FileAccess.WRITE).store_string(
        '{"version":1,"company_state":{},"roster":[{}]}'
    )
    if CampaignPersistence.is_valid_save(CampaignPersistence.load_save()):
        _fail(failures, "P2 persistence: save version 1 should not validate")
    else:
        _pass()
    FileAccess.open(CampaignPersistence.active_save_path(), FileAccess.WRITE).store_string('{"version":999}')
    if CampaignPersistence.is_valid_save(CampaignPersistence.load_save()):
        _fail(failures, "P2 persistence: wrong version should not validate")
    else:
        _pass()
    if CampaignPersistence.has_save():
        CampaignPersistence.clear_slot()
    _release_harness_world(world)
    _release_harness_world(fresh)
    _cleanup_harness_ui_overlay()
