extends Node2D

## Breach / incursion phase harness: 3v3, depth 2, heavy spear + boosted stats.
## Determinism: fixed RNG seed, queued crash contest rolls (always succeed while queue lasts), and crash-first AI
## (CombatConstants.is_incursion_breach_harness_active). Asserts crash_success + defender breached_files before battle ends.
## Revert project main_scene to res://main.tscn when done.
##
## Godot / harness lessons (keep when extending this scene):
## - Root `add_child` during scene setup can fail with "Parent node is busy"; use `add_child.call_deferred` and then
##   wait until the node `is_inside_tree()` before logic that assumes the parent chain (future-proof vs a single `await`).
## - Connecting with `Callable(self, "fn").bind(mgr)` for `action_resolved` can invoke `fn` with only signal args, so the
##   first parameter receives `attacker_id` (int) instead of `mgr`. Prefer lambdas that close over `mgr` and forward args.

const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _CombatFlow := preload("res://world/CombatFlow.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _CharacterScript := preload("res://character.gd")
const _CoreEntityScript := preload("res://core/CoreEntity.gd")
const _ResourcePaths := preload("res://core/ResourcePaths.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _FormationBreachRules := preload("res://combat/FormationBreachRules.gd")

const _HARNESS_RNG_SEED := 0x1CA501

## BattleScene.parent_scene is get_tree().current_scene (see CombatFlow), not the node that calls start_combat.
var _harness_meta_host: Node = null

func _configure_window() -> void:
	var mw: Window = get_tree().root
	mw.content_scale_size = Vector2i(1920, 1080)
	mw.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	mw.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	mw.mode = Window.MODE_MAXIMIZED

func _clear_harness_connect_meta() -> void:
	if _harness_meta_host != null and is_instance_valid(_harness_meta_host):
		if _harness_meta_host.has_meta("incursion_breach_harness_connect"):
			_harness_meta_host.remove_meta("incursion_breach_harness_connect")
	_harness_meta_host = null

func _exit_tree() -> void:
	_clear_harness_connect_meta()
	_end_incursion_harness()

func _begin_incursion_harness() -> void:
	set_meta("_harness_ok_breach", false)
	set_meta("_incursion_harness_finished", false)
	set_meta("_harness_monitor_connected", false)
	seed(_HARNESS_RNG_SEED)
	_CombatConstants.set_incursion_breach_harness_active(true)
	_CombatConstants.begin_breach_crash_test_rolls(256)

func _end_incursion_harness() -> void:
	set_meta("_harness_monitor_connected", false)
	_CombatConstants.set_incursion_breach_harness_active(false)
	_CombatConstants.clear_breach_crash_test_rolls()

func _root_has_battle_with_manager() -> bool:
	for c in get_tree().root.get_children():
		var m: Variant = (c as Node).get("manager")
		if m != null and m is Node:
			return true
	return false

## Called from BattleScene.start() before CombatManager.start() (meta `incursion_breach_harness_connect`).
func _connect_incursion_harness_monitor(mgr: Node) -> void:
	if mgr == null:
		push_error("IncursionBreachTest: harness hook received null manager.")
		return
	if get_meta("_harness_monitor_connected", false):
		push_warning("IncursionBreachTest: harness monitor already connected.")
		return
	set_meta("_harness_monitor_connected", true)
	# Lambdas capture `mgr`; do not use Callable.bind(mgr) here — signal args are not prepended to bound callables reliably.
	mgr.action_resolved.connect(
		func(attacker_id: int, target_id: int, result: Dictionary) -> void:
			_harness_on_action_resolved(mgr, attacker_id, target_id, result)
	)
	mgr.combat_ended.connect(
		func(winner: String, defeated: Variant) -> void:
			_harness_on_combat_ended(mgr, winner, defeated as Node)
	)

func _harness_on_action_resolved(mgr: Node, _attacker_id: int, target_id: int, result: Dictionary) -> void:
	if str(result.get("outcome", "")) != "crash_success":
		return
	if not mgr.has_method("_get_by_id"):
		push_error("IncursionBreachTest: manager missing _get_by_id")
		return
	var def: Variant = mgr._get_by_id(target_id)
	if def == null:
		push_error("IncursionBreachTest: crash_success but defender id=%d not found" % target_id)
		return
	var fid_def: String = str(def.get("formation_id", ""))
	var fm: Variant = mgr.get("formations")
	var form: Dictionary = (fm as Dictionary).get(fid_def, {}) if fm != null and typeof(fm) == TYPE_DICTIONARY else {}
	var bf: Dictionary = form.get("breached_files", {})
	if bf.is_empty():
		push_error(
			"IncursionBreachTest: crash_success but breached_files empty for defender formation_id=%s (breach state not applied?)"
			% fid_def
		)
		return
	var clogs: bool = _FormationBreachRules.breach_clogs_open_lanes(form)
	var pressure: float = float(form.get("incursion_pressure", 0.0))
	var lane_stress: Dictionary = form.get("lane_stress_by_file", {})
	if not clogs:
		push_error(
			"IncursionBreachTest: non-empty breached_files but breach_clogs_open_lanes=false (FormationBreachRules out of sync?). bf=%s"
			% bf
		)
	set_meta("_harness_ok_breach", true)
	print(
		"[IncursionBreachTest] Harness: crash_success + breached_files fid=%s bf=%s breach_clogs_open_lanes=%s incursion_pressure=%.3f lane_stress=%s"
		% [fid_def, bf, clogs, pressure, lane_stress]
	)

func _harness_on_combat_ended(_mgr: Node, _winner: String, _defeated: Node) -> void:
	if get_meta("_incursion_harness_finished", false):
		return
	set_meta("_incursion_harness_finished", true)
	if not get_meta("_harness_ok_breach", false):
		push_error(
			"IncursionBreachTest: combat ended without a validated breach (need crash_success and non-empty defender breached_files)."
		)
	else:
		print("[IncursionBreachTest] Harness finished: breach assertion passed.")
	_clear_harness_connect_meta()
	_end_incursion_harness()

func _ready() -> void:
	_begin_incursion_harness()
	_configure_window()
	var pm_script: Variant = load(_ResourcePaths.PARTY_MANAGER)
	if pm_script == null:
		push_error("IncursionBreachTest: PartyManager missing")
		_end_incursion_harness()
		return
	var pm: Node = pm_script.new()
	# Root can be "busy" during this scene's _ready; deferred add runs on idle before typical first await.
	get_tree().root.add_child.call_deferred(pm)
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

	var _wait_pm_tree: int = 0
	while not pm.is_inside_tree():
		await get_tree().process_frame
		_wait_pm_tree += 1
		if _wait_pm_tree > 60:
			push_error("IncursionBreachTest: PartyManager never entered tree after deferred add_child.")
			_end_incursion_harness()
			return
	pm.add_member(main_ch)
	pm.add_member(c1)
	pm.add_member(c2)

	var enemies: Array = _spawn_test_enemies(3)
	set_meta("_combat_enemies", enemies)
	if enemies.is_empty():
		push_error("IncursionBreachTest: no enemies spawned (check ENEMY_SCENE / resources). Aborting.")
		_end_incursion_harness()
		return
	print(
		"[IncursionBreachTest] 3v3 heavy spear, depth 2. Deterministic: seed=%s, crash roll queue, crash-first AI. "
		% str(_HARNESS_RNG_SEED)
		+ "COMBAT_EVENT_DEBUG: [Combat.Flow] contest_crash, incursion_snapshot, breach_clogs; errors if no breach before battle end. "
		+ "Revert main_scene to res://main.tscn when done."
	)
	_harness_meta_host = get_tree().current_scene
	if _harness_meta_host == null:
		push_error("IncursionBreachTest: get_tree().current_scene is null; BattleScene.parent_scene hook cannot run.")
		_end_incursion_harness()
		return
	_harness_meta_host.set_meta(
		"incursion_breach_harness_connect",
		Callable(self, "_connect_incursion_harness_monitor")
	)
	await get_tree().process_frame
	await _CombatFlow.start_combat(self, enemies)
	if not _root_has_battle_with_manager():
		push_error(
			"IncursionBreachTest: combat did not start (no BattleScene with manager under root — empty party, missing battle script, etc.). Clearing harness."
		)
		_clear_harness_connect_meta()
		_end_incursion_harness()

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
