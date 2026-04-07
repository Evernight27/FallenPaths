extends Node2D

## Deterministic harness for incursion plan: crash viability (heavy kit + stats), 3v3 formations with
## depth 2 (swap / fall back vs breach block), spear reach. Revert project main_scene to res://main.tscn when done.

const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _CombatFlow := preload("res://world/CombatFlow.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _CharacterScript := preload("res://character.gd")
const _CoreEntityScript := preload("res://core/CoreEntity.gd")
const _ResourcePaths := preload("res://core/ResourcePaths.gd")

func _configure_window() -> void:
	var mw: Window = get_tree().root
	mw.content_scale_size = Vector2i(1920, 1080)
	mw.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	mw.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	mw.mode = Window.MODE_MAXIMIZED

func _ready() -> void:
	_configure_window()
	var pm_script: Variant = load(_ResourcePaths.PARTY_MANAGER)
	if pm_script == null:
		push_error("IncursionBreachTest: PartyManager missing")
		return
	var pm: Node = pm_script.new()
	get_tree().root.add_child(pm)
	set_meta("party_manager", pm)
	set_meta(
		"party_formation",
		_FormationPreset.for_front_count(3, 2, _FormationPreset.DENSITY_NORMAL)
	)
	set_meta(
		"enemy_formation",
		_FormationPreset.for_front_count(3, 2, _FormationPreset.DENSITY_NORMAL)
	)

	var human: Resource = load(_ResourcePaths.HUMAN_SPECIES) as Resource
	var main_ch: CharacterBody2D = _build_character_body("Character", human, true)
	add_child(main_ch)
	var c1: CharacterBody2D = _build_character_body("Companion", human, false)
	var c2: CharacterBody2D = _build_character_body("Companion2", human, false)
	main_ch.add_child(c1)
	main_ch.add_child(c2)

	await get_tree().process_frame
	main_ch.apply_species()
	c1.apply_species()
	c2.apply_species()
	for unit in [main_ch, c1, c2]:
		_boost_stats_for_crash_viability(unit)
		_equip_heavy_spear_humanoid(unit)

	pm.add_member(main_ch)
	pm.add_member(c1)
	pm.add_member(c2)

	var enemies: Array = _spawn_test_enemies(3)
	set_meta("_combat_enemies", enemies)
	print(
		"[IncursionBreachTest] 3v3 heavy spear, formation depth 2 — expect crash in action list, breach_diag after crash, "
		+ "enemy formation moves blocked when breached_files active. Revert main_scene to res://main.tscn in project.godot when done."
	)
	await get_tree().process_frame
	await _CombatFlow.start_combat(self, enemies)

func _build_character_body(unit_name: String, species_res: Resource, with_camera: bool) -> CharacterBody2D:
	var ch := CharacterBody2D.new()
	ch.name = unit_name
	var cb := Node2D.new()
	cb.name = "CombatBody"
	cb.set_script(_CoreEntityScript)
	ch.add_child(cb)
	ch.set_script(_CharacterScript)
	ch.species = species_res
	if with_camera:
		var cam := Camera2D.new()
		cam.enabled = true
		ch.add_child(cam)
	return ch

func _boost_stats_for_crash_viability(ch: Node) -> void:
	var cb: Node = ch.get_node_or_null("CombatBody")
	if cb != null:
		cb.strength = 120
		cb.agility = 118
		cb.perception = 115

func _boost_core_stats(e: Node) -> void:
	if e.get_script() == _CoreEntityScript:
		e.strength = 108
		e.agility = 105
		e.perception = 102

func _equip_heavy_spear_humanoid(ch: Node) -> void:
	var ids: Dictionary = {
		"head": "KETTLE_HELM",
		"chest": "CUIRASS",
		"right_arm": "VAMBRACES",
		"left_arm": "VAMBRACES_LEFT",
		"right_leg": "GREAVES",
		"left_leg": "GREAVES_LEFT",
	}
	for part in ids.keys():
		var piece = _ArmorPiece.create_from_definition(ids[part])
		if piece != null and ch.has_method("equip_armor"):
			ch.equip_armor(part, piece)
	var w: Variant = _Weapon.create_from_definition("SPEAR")
	if w != null and ch.has_method("equip_weapon"):
		ch.equip_weapon(w)

func _equip_heavy_spear_core_entity(e: Node) -> void:
	_equip_heavy_spear_humanoid(e)

func _spawn_test_enemies(count: int) -> Array:
	var out: Array = []
	var pscene: PackedScene = load(_ResourcePaths.ENEMY_SCENE) as PackedScene
	var goblin: Resource = load(_ResourcePaths.GOBLIN_SPECIES) as Resource
	if pscene == null:
		push_error("IncursionBreachTest: enemy scene missing")
		return out
	for i in range(count):
		var e: Node = pscene.instantiate()
		e.name = "TestEnemy%d" % (i + 1)
		add_child(e)
		if goblin != null and "species" in e:
			e.species = goblin
		if e.has_method("apply_species"):
			e.apply_species()
		_boost_core_stats(e)
		_equip_heavy_spear_core_entity(e)
		out.append(e)
	return out

func _on_battle_ended(winner: String, defeated: Node) -> void:
	await _CombatFlow.handle_battle_ended(self, winner, defeated)
	print("[IncursionBreachTest] Battle ended winner=%s — set main scene back to res://main.tscn when finished." % winner)
