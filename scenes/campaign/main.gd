extends Node2D

## Overworld -> `CombatFlow.start_combat` -> `BattleScene` / `CombatManager`.

const WORLD_META_CAMP_HEAL_HINT_SHOWN := "camp_heal_hint_shown"
@export var enemy_scene: PackedScene
## F5 soak: `ii2b`/`ii4d`/`ii3`/`ii5`/`ii6`/`ii8`  -  Output grep **`soak_guide`** + **`soak_guide human`** at session
## start, **`soak=`** on encounter_begin.
@export_enum("off: ", "ii2b", "ii3", "ii5", "ii6", "ii8", "ii4d", "ii_envelop") var dev_soak_encounter: String = ""
## Track Q1: per-hit **`research_feel`** lines in Output (no `COMBAT_DEV_VERBOSE` const edit). Use with **`ii2b`** duel.
@export var dev_research_feel: bool = false
## F5: grep **`hit_resolve reason=`** / **`hit_outcome_stats`** per strike (default on). Off = quieter Output.
@export var dev_hit_summary: bool = true

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var tilemap: TileMap = $TileMap
@onready var player: Node2D = $Character


func _tile_coords(pos: Vector2) -> Vector2i:
    return OverworldMap.tile_coords_from_pos(pos)


func _ready():
    # --tuning CLI flag loads the combat tuning scene instead of the campaign.
    if OS.get_cmdline_args().has("--tuning"):
        get_tree().change_scene_to_file("res://tools/combat_tuning/combat_tuning.tscn")
        return

    var soak_id: String = dev_soak_encounter.strip_edges().to_lower()
    if soak_id == "off":
        soak_id = ""
    if dev_research_feel:
        CombatConstants.set_combat_dev_verbose_override(true)
    if OS.has_feature("editor"):
        OperationalLog.begin_play_session(CombatConstants.PATH_MAIN_SCENE, soak_id, dev_research_feel, dev_hit_summary)
        CombatF5SoakTrace.log_session_plan(soak_id, dev_research_feel)
        CombatF5SoakTrace.reset_session_camp_trace()
        CombatF5SoakTrace.prepare_fight_end_log()
    # Match FallenFramework: fill screen  -  maximized window + stretch to viewport
    var main_window = get_tree().root
    main_window.content_scale_size = Vector2i(1920, 1080)
    main_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    main_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    main_window.mode = Window.MODE_MAXIMIZED

    # Generate tile texture if it doesn't exist
    TilesetSetup.generate_tile_texture_if_needed()

    # Wait a frame for texture to be ready
    await get_tree().process_frame

    # Create tileset programmatically
    TilesetSetup.setup_tileset(tilemap)

    # Fill the overworld grid with tiles (XCamp-3.2: 5- - 5 default).
    OverworldMap.stamp_world_map_size(self)
    var source_id = 0
    var atlas_coords = Vector2i(0, 0)
    var map_n: int = OverworldMap.map_tiles_for_world(self)
    for x in range(map_n):
        for y in range(map_n):
            var coords = Vector2i(x, y)
            tilemap.set_cell(0, coords, source_id, atlas_coords)

    CombatDebug.world_session("overworld ready (%s grid, encounters spawned)" % OverworldMap.format_map_label(self))

    # Randomize RNG: cyan preset marker first (when set), then red 7v7 tiles (#4 #7 II-5a/b/c).
    rng.randomize()
    var soak_tile: Variant = null
    if not soak_id.is_empty():
        # Prefer far tiles from player start (0,0) so cyan preset marker is easy to find in F5.
        var soak_tile_prefs: Array = [
            Vector2i(4, 4),
            Vector2i(4, 3),
            Vector2i(3, 4),
            Vector2i(4, 2),
            Vector2i(2, 2),
            Vector2i(2, 1),
            Vector2i(1, 2),
            Vector2i(2, 0),
        ]
        soak_tile = EncounterSpawner.spawn_soak_encounter_marker(self, soak_id, rng, enemy_scene, [], soak_tile_prefs)
        if soak_tile != null:
            CombatDebug.world_session("dev soak encounter '%s' at tile=%s (cyan)" % [soak_id, soak_tile])
        else:
            OperationalLog.warn("dev_soak_encounter '%s' failed to spawn  -  grid full or unknown preset" % soak_id)
    var boot_save: Dictionary = {}
    var restoring_campaign_save: bool = false
    if soak_id.is_empty():
        if not CompanyState.persistence_uses_disk_autosave():
            CampaignPersistence.clear_slot()
        boot_save = CompanyState.load_campaign_autosave_for_boot()
        restoring_campaign_save = not boot_save.is_empty()
        if not restoring_campaign_save:
            ContractSpawner.spawn_campaign_contracts(self, rng, enemy_scene)
            CombatDebug.world_session(
                "campaign contracts spawned paid=%d (+ tutorial when incomplete)" % ContractSpawner.get_template_count()
            )
            if OperationalLog.is_play_session_active():
                OperationalLog.play_world("campaign_boot fresh=true reason=no_save")
    else:
        EncounterSpawner.spawn_encounters(self, rng, 1, 7, enemy_scene)
    # Assign player and companion resources/species/equipment before party setup so party UI shows correct stats
    PlayerCompanionSetup.setup_player_and_companion(self, rng)
    var party_weapon: String = SoakEncounterPresets.party_weapon_id_for_preset(soak_id)
    if not party_weapon.is_empty():
        PlayerCompanionSetup.equip_party_weapons(self, party_weapon)
    # Setup party manager, party menu, and Party button (after species so snapshot has correct stats)
    PartySetup.setup_party(self)
    if restoring_campaign_save:
        CompanyState.restore_campaign_autosave_on_main(self, boot_save, rng, enemy_scene)
        CombatDebug.world_session("campaign restored from %s" % CampaignPersistence.SAVE_PATH)
        if OperationalLog.is_play_session_active():
            (
                OperationalLog
                . play_world(
                    (
                        "campaign_restore path=%s gold=%d day=%d testing_restore=%s"
                        % [
                            CampaignPersistence.SAVE_PATH,
                            CompanyState.get_gold(self),
                            CompanyState.get_day_index(self),
                            str(CompanyState.persistence_restore_on_main_restart()).to_lower(),
                        ]
                    )
                )
            )
    set_meta("camp_tile", CompanyState.DEFAULT_CAMP_TILE)
    SoakEncounterPresets.apply_world_post_setup(self, soak_id)
    SoakEncounterPresets.emit_f5_soak_guide(soak_id, soak_tile)
    # Connect to player moved signal to detect encounters
    if has_node("Character"):
        set_meta("last_player_tile", _tile_coords(player.position))
        if player.has_signal("moved") and not player.moved.is_connected(Callable(self, "_on_player_moved")):
            player.connect("moved", Callable(self, "_on_player_moved"))


func _on_party_button_pressed() -> void:
    var pm = self.get_meta("party_manager")
    var menu = self.get_meta("party_menu")
    if pm and menu:
        menu.show_party(self, pm.get_members())


func _revert_player_move(_player: Node2D, prev_tile: Vector2i) -> void:
    CampaignEncounterBridge.place_player_on_overworld_tile(self, prev_tile)


func _on_player_moved():
    var p_tile = _tile_coords(player.position)
    var prev_tile: Vector2i = get_meta("last_player_tile") as Vector2i if has_meta("last_player_tile") else p_tile
    # Detect encounter on tile (one marker per encounter; enemies spawn when combat starts)
    var encounter = _get_encounter_on_tile(p_tile)
    if encounter != null:
        var can_enter: Dictionary = CampaignEncounterBridge.can_enter_combat(self)
        if not can_enter.get("ok", false):
            CombatDebug.world_session(str(can_enter.get("message", "Cannot enter combat.")))
            _revert_player_move(player, prev_tile)
            return
        if MapBleedPolicy.should_block_entering_combat(self):
            CombatDebug.world_session(MapBleedPolicy.map_move_blocked_message(self))
            _revert_player_move(player, prev_tile)
            return
        if CampaignEncounterBridge.party_has_untreated_wounds(self):
            var parts: int = CampaignEncounterBridge.party_untreated_part_count(self)
            OperationalLog.play_world(
                (
                    "Untreated wounds  -  %d part(s) need dressing in Party (%s) before fighting."
                    % [parts, CompanyState.format_field_care_march_chain()]
                )
            )
        var marker: String = str(encounter.contract_marker_label).strip_edges()
        if marker.is_empty() and encounter.has_method("get_combat_encounter_dict"):
            var enc_dict: Dictionary = encounter.get_combat_encounter_dict()
            marker = enc_dict.get("contract_title", "")
        if not marker.is_empty():
            OperationalLog.play_world("Contract  -  %s" % marker.replace("\n", " . "))
        var enemies: Array = CampaignEncounterBridge.begin_contract_encounter(self, encounter, rng)
        if enemies.is_empty():
            OperationalLog.warn(
                "No enemies spawned  -  contract entry rolled back (marker kept). Check encounter config."
            )
            _revert_player_move(player, prev_tile)
            return
        CombatDebug.world_session("entering combat tile=%s enemies=%d" % [p_tile, enemies.size()])
        set_meta("last_player_tile", p_tile)
        await CombatFlow.start_combat(self, enemies)
        return
    if MapBleedPolicy.should_block_map_move(self):
        CombatDebug.world_session(MapBleedPolicy.map_move_blocked_message(self))
        _revert_player_move(player, prev_tile)
        return
    CampaignEncounterBridge.advance_party_overworld_minute(self)
    MapBleedPolicy.on_overworld_step(self)
    CompanyState.on_overworld_step(self)
    set_meta("last_player_tile", p_tile)
    _maybe_camp_tile_hint(p_tile)
    CompanyState.refresh_hud(self)


func _maybe_camp_tile_hint(p_tile: Vector2i) -> void:
    var camp: Vector2i = get_meta("camp_tile") as Vector2i if has_meta("camp_tile") else CompanyState.DEFAULT_CAMP_TILE
    if p_tile != camp:
        return
    if bool(get_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, false)):
        return
    set_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, true)
    if CampaignEncounterBridge.party_has_untreated_wounds(self):
        var parts: int = CampaignEncounterBridge.party_untreated_part_count(self)
        var budget: Dictionary = CompanyState.triage_med_budget(self)
        CombatDebug.world_session(
            (
                "Camp: %d part(s) need dressing  -  Party -> field care, then Camp rest (-1 med . +1 day . +1 mood)."
                % parts
            )
        )
        if budget.get("med_shortfall", 0) > 0:
            CombatDebug.world_session(
                (
                    "Camp: med shortfall %d  -  bandage at reduced efficacy or win contracts (+4 med)."
                    % budget.get("med_shortfall", 0)
                )
            )
    elif CompanyState.camp_heal_ready(self, true):
        CombatDebug.world_session("Camp: Party -> Camp rest (-1 med . +1 day . +1 mood) or End day.")
    elif CompanyState.can_offer_end_day(self):
        CombatDebug.world_session("Camp: Party -> End day (wages) or Camp rest if wounded.")
    elif CompanyState.roster_has_hire_room(self):
        CombatDebug.world_session(
            "Camp: Party -> Hire rookie (-%dg) when roster has room after losses." % CompanyState.HIRE_GOLD_COST
        )
    else:
        CombatDebug.world_session("Camp tile  -  wages and rest are managed from the Party menu.")
    if CompanyState.should_show_next_provisions_hint(self):
        CombatDebug.world_session(CompanyState.format_next_provisions_hint(self))
    if CompanyState.count_desertion_risk_roster(self) > 0:
        CombatDebug.world_session(CompanyState.format_party_desertion_risk_footer(self))
    if CompanyState.persistence_uses_disk_autosave():
        CombatDebug.world_session("Camp: autosave on settlement continue, End day, Camp rest, and soft-defeat return.")


func _tile_center(tile: Vector2i) -> Vector2:
    return OverworldMap.tile_center(tile)


func _get_encounter_on_tile(tile: Vector2i) -> Node:
    for child in get_children():
        if child.get_script() == EncounterNode and _tile_coords(child.position) == tile:
            return child
    return null


func _exit_tree() -> void:
    if OS.has_feature("editor"):
        OperationalLog.end_play_session()


func _on_battle_ended(winner: String, defeated: Node):
    await CombatFlow.handle_battle_ended(self, winner, defeated)


func _company_run_end(reason: String):
    var RunEnd := preload("res://ui/company/CompanyRunEndPanel.gd")
    await RunEnd.show_and_await(self, reason)


func _print_node_tree(node: Node, indent: String = "") -> void:
    if node == null:
        return
    print(indent, node.name, "<", node.get_class(), ">")
    for child in node.get_children():
        _print_node_tree(child, indent + "  ")
