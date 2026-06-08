extends Node2D

## Overworld → `CombatFlow.start_combat` → `BattleScene` / `CombatManager`.

const _EncounterNode := preload("res://world/EncounterNode.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _ContractSpawner := preload("res://world/ContractSpawner.gd")
const _CampaignPersistence := preload("res://world/CampaignPersistence.gd")
const _MapBleedPolicy := preload("res://world/MapBleedPolicy.gd")
const _OverworldMap := preload("res://world/OverworldMap.gd")

const WORLD_META_CAMP_HEAL_HINT_SHOWN := "camp_heal_hint_shown"
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")

@onready var tilemap: TileMap = $TileMap

@export var enemy_scene: PackedScene
## F5 soak: `ii2b`/`ii4d`/`ii3`/`ii5`/`ii6`/`ii8` — Output grep **`soak_guide`** + **`soak_guide human`** at session start, **`soak=`** on encounter_begin.
@export_enum("off: ", "ii2b", "ii3", "ii5", "ii6", "ii8", "ii4d", "ii_envelop") var dev_soak_encounter: String = ""
## Track Q1: per-hit **`research_feel`** lines in Output (no `COMBAT_DEV_VERBOSE` const edit). Use with **`ii2b`** duel.
@export var dev_research_feel: bool = false
## F5: grep **`hit_resolve reason=`** / **`hit_outcome_stats`** per strike (default on). Off = quieter Output.
@export var dev_hit_summary: bool = true

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _tile_coords(pos: Vector2) -> Vector2i:
	return _OverworldMap.tile_coords_from_pos(pos)

func _ready():
	var soak_id: String = dev_soak_encounter.strip_edges().to_lower()
	if soak_id == "off":
		soak_id = ""
	if dev_research_feel:
		_CombatConstants.set_combat_dev_verbose_override(true)
	if OS.has_feature("editor"):
		_OperationalLog.begin_play_session("res://main.tscn", soak_id, dev_research_feel, dev_hit_summary)
		_F5SoakTrace.log_session_plan(soak_id, dev_research_feel)
		_F5SoakTrace.reset_session_camp_trace()
		_F5SoakTrace.prepare_fight_end_log()
	# Match FallenFramework: fill screen — maximized window + stretch to viewport
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
	
	# Fill the overworld grid with tiles (XCamp-3.2: 5×5 default).
	_OverworldMap.stamp_world_map_size(self)
	var source_id = 0
	var atlas_coords = Vector2i(0, 0)
	var map_n: int = _OverworldMap.map_tiles_for_world(self)
	for x in range(map_n):
		for y in range(map_n):
			var coords = Vector2i(x, y)
			tilemap.set_cell(0, coords, source_id, atlas_coords)
	
	_CombatDebug.world_session(
		"overworld ready (%s grid, encounters spawned)" % _OverworldMap.format_map_label(self)
	)
	
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
		soak_tile = EncounterSpawner.spawn_soak_encounter_marker(
			self, soak_id, rng, enemy_scene, [], soak_tile_prefs
		)
		if soak_tile != null:
			_CombatDebug.world_session("dev soak encounter '%s' at tile=%s (cyan)" % [soak_id, soak_tile])
		else:
			_OperationalLog.warn(
				"dev_soak_encounter '%s' failed to spawn — grid full or unknown preset" % soak_id
			)
	var boot_save: Dictionary = {}
	var restoring_campaign_save: bool = false
	if soak_id.is_empty():
		if _CompanyState.read_stub_persistence_mode() == "P1":
			_CampaignPersistence.clear_slot()
		boot_save = _CompanyState.load_campaign_autosave_for_boot()
		restoring_campaign_save = not boot_save.is_empty()
		if not restoring_campaign_save:
			_ContractSpawner.spawn_campaign_contracts(self, rng, enemy_scene)
			_CombatDebug.world_session(
				"campaign contracts spawned paid=%d (+ tutorial when incomplete)"
				% _ContractSpawner.get_template_count()
			)
			if _OperationalLog.is_play_session_active():
				_OperationalLog.play_world("campaign_boot fresh=true reason=no_save")
	else:
		EncounterSpawner.spawn_encounters(self, rng, 1, 7, enemy_scene)
	# Assign player and companion species/equipment before party setup so party UI shows correct stats
	PlayerCompanionSetup.setup_player_and_companion(self, rng)
	var party_weapon: String = SoakEncounterPresets.party_weapon_id_for_preset(soak_id)
	if not party_weapon.is_empty():
		PlayerCompanionSetup.equip_party_weapons(self, party_weapon)
	# Setup party manager, party menu, and Party button (after species so snapshot has correct stats)
	PartySetup.setup_party(self)
	if restoring_campaign_save:
		_CompanyState.restore_campaign_autosave_on_main(self, boot_save, rng, enemy_scene)
		_CombatDebug.world_session("campaign restored from %s" % _CampaignPersistence.SAVE_PATH)
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_world(
				"campaign_restore path=%s gold=%d day=%d testing_restore=%s"
				% [
					_CampaignPersistence.SAVE_PATH,
					_CompanyState.get_gold(self),
					_CompanyState.get_day_index(self),
					str(_CompanyState.persistence_restore_on_main_restart()).to_lower(),
				]
			)
	set_meta("camp_tile", _CompanyState.DEFAULT_CAMP_TILE)
	SoakEncounterPresets.apply_world_post_setup(self, soak_id)
	SoakEncounterPresets.emit_f5_soak_guide(soak_id, soak_tile)
	# Connect to player moved signal to detect encounters
	if has_node("Character"):
		var player = $Character
		set_meta("last_player_tile", _tile_coords(player.position))
		if player.has_signal("moved"):
			player.connect("moved", Callable(self, "_on_player_moved"))

func _on_party_button_pressed() -> void:
	var pm = self.get_meta("party_manager")
	var menu = self.get_meta("party_menu")
	if pm and menu:
		menu.show_party(self, pm.get_members())

func _revert_player_move(_player: Node2D, prev_tile: Vector2i) -> void:
	_CampaignBridge.place_player_on_overworld_tile(self, prev_tile)


func _on_player_moved():
	var player = $Character
	var p_tile = _tile_coords(player.position)
	var prev_tile: Vector2i = (
		get_meta("last_player_tile") as Vector2i
		if has_meta("last_player_tile")
		else p_tile
	)
	# Detect encounter on tile (one marker per encounter; enemies spawn when combat starts)
	var encounter = _get_encounter_on_tile(p_tile)
	if encounter != null:
		var can_enter: Dictionary = _CampaignBridge.can_enter_combat(self)
		if not bool(can_enter.get("ok", false)):
			_CombatDebug.world_session(str(can_enter.get("message", "Cannot enter combat.")))
			_revert_player_move(player, prev_tile)
			return
		if _MapBleedPolicy.should_block_entering_combat(self):
			_CombatDebug.world_session(_MapBleedPolicy.map_move_blocked_message(self))
			_revert_player_move(player, prev_tile)
			return
		if _CampaignBridge.party_has_untreated_wounds(self):
			var parts: int = _CampaignBridge.party_untreated_part_count(self)
			_OperationalLog.play_world(
				"Untreated wounds — %d part(s) need dressing in Party (%s) before fighting."
				% [parts, _CompanyState.format_field_care_march_chain()]
			)
		var marker: String = str(encounter.contract_marker_label).strip_edges()
		if marker.is_empty() and encounter.has_method("get_combat_encounter_dict"):
			var enc_dict: Dictionary = encounter.get_combat_encounter_dict()
			marker = str(enc_dict.get("contract_title", ""))
		if not marker.is_empty():
			_OperationalLog.play_world("Contract — %s" % marker.replace("\n", " · "))
		var enemies: Array = _CampaignBridge.begin_contract_encounter(self, encounter, rng)
		if enemies.is_empty():
			_OperationalLog.warn(
				"No enemies spawned — contract entry rolled back (marker kept). Check encounter config."
			)
			_revert_player_move(player, prev_tile)
			return
		_CombatDebug.world_session("entering combat tile=%s enemies=%d" % [p_tile, enemies.size()])
		set_meta("last_player_tile", p_tile)
		await CombatFlow.start_combat(self, enemies)
		return
	if _MapBleedPolicy.should_block_map_move(self):
		_CombatDebug.world_session(_MapBleedPolicy.map_move_blocked_message(self))
		_revert_player_move(player, prev_tile)
		return
	_CampaignBridge.advance_party_overworld_minute(self)
	_MapBleedPolicy.on_overworld_step(self)
	_CompanyState.on_overworld_step(self)
	set_meta("last_player_tile", p_tile)
	_maybe_camp_tile_hint(p_tile)
	_CompanyState.refresh_hud(self)


func _maybe_camp_tile_hint(p_tile: Vector2i) -> void:
	var camp: Vector2i = (
		get_meta("camp_tile") as Vector2i
		if has_meta("camp_tile")
		else _CompanyState.DEFAULT_CAMP_TILE
	)
	if p_tile != camp:
		return
	if bool(get_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, false)):
		return
	set_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, true)
	if _CampaignBridge.party_has_untreated_wounds(self):
		var parts: int = _CampaignBridge.party_untreated_part_count(self)
		var budget: Dictionary = _CompanyState.triage_med_budget(self)
		_CombatDebug.world_session(
			"Camp: %d part(s) need dressing — Party → field care, then Camp rest (−1 med · +1 day · +1 mood)."
			% parts
		)
		if int(budget.get("med_shortfall", 0)) > 0:
			_CombatDebug.world_session(
				"Camp: med shortfall %d — bandage at reduced efficacy or win contracts (+4 med)."
				% int(budget.get("med_shortfall", 0))
			)
	elif _CompanyState.camp_heal_ready(self, true):
		_CombatDebug.world_session("Camp: Party → Camp rest (−1 med · +1 day · +1 mood) or End day.")
	elif _CompanyState.can_offer_end_day(self):
		_CombatDebug.world_session("Camp: Party → End day (wages) or Camp rest if wounded.")
	elif _CompanyState.roster_has_hire_room(self):
		_CombatDebug.world_session(
			"Camp: Party → Hire rookie (−%dg) when roster has room after losses."
			% _CompanyState.HIRE_GOLD_COST
		)
	else:
		_CombatDebug.world_session("Camp tile — wages and rest are managed from the Party menu.")
	if _CompanyState.should_show_next_provisions_hint(self):
		_CombatDebug.world_session(_CompanyState.format_next_provisions_hint(self))
	if _CompanyState.count_desertion_risk_roster(self) > 0:
		_CombatDebug.world_session(_CompanyState.format_party_desertion_risk_footer(self))
	if _CompanyState.persistence_uses_disk_autosave():
		_CombatDebug.world_session(
			"Camp: autosave on settlement continue, End day, Camp rest, and soft-defeat return."
		)


func _tile_center(tile: Vector2i) -> Vector2:
	return _OverworldMap.tile_center(tile)

func _get_encounter_on_tile(tile: Vector2i) -> Node:
	for child in get_children():
		if child.get_script() == _EncounterNode and _tile_coords(child.position) == tile:
			return child
	return null

func _exit_tree() -> void:
	if OS.has_feature("editor"):
		_OperationalLog.end_play_session()


func _on_battle_ended(winner: String, defeated: Node) -> void:
	await CombatFlow.handle_battle_ended(self, winner, defeated)


func _company_run_end(reason: String) -> void:
	const _RunEnd := preload("res://ui/CompanyRunEndPanel.gd")
	await _RunEnd.show_and_await(self, reason)

func _print_node_tree(node: Node, indent: String = "") -> void:
	if node == null:
		return
	print(indent, node.name, "<", node.get_class(), ">")
	for child in node.get_children():
		_print_node_tree(child, indent + "  ")
