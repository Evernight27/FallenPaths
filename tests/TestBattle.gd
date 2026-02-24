extends Node

## Test battle scene: exercises severance, mangled/destroyed parts, wounds, bleeding, and healing.

const WeaponClass := preload("res://weapon/Weapon.gd")
## Run this scene as main (Project > Run Main Scene, or set run/main_scene to res://tests/TestBattle.tscn)
## to verify damage, armor, bone/tissue split, stump wounds, clotting, bandage, and tissue/bone/blood healing.

const BLEED_TICK_S: float = 10.0
const HEAL_TICK_S: float = 3600.0  # 1 hour game time

var _test_dummy: Node = null
var _battle: Node = null
var _phase: String = "scripted"  # "scripted" | "combat" | "post_heal" | "done"

func _ready() -> void:
	print("========================================")
	print("  TEST BATTLE: Severance, Wounds, Bleeding, Healing")
	print("========================================")
	_run_scripted_tests()

func _run_scripted_tests() -> void:
	# Create a single entity (CoreEntity) for controlled tests
	var enemy_scene: PackedScene = load("res://enemy/Enemy.tscn") as PackedScene
	if enemy_scene == null:
		print("[TestBattle] ERROR: Could not load Enemy.tscn")
		_finish()
		return
	_test_dummy = enemy_scene.instantiate()
	add_child(_test_dummy)

	var species: Resource = load("res://species/goblin.tres") as Resource
	if species != null:
		_test_dummy.set("species", species)
	if _test_dummy.has_method("apply_species"):
		_test_dummy.apply_species()
	_test_dummy.set("name", "TestDummy")

	# Ensure we have CoreEntity API (Enemy is CoreEntity root)
	var entity = _test_dummy
	if not entity.has_method("take_damage_split"):
		print("[TestBattle] ERROR: TestDummy has no take_damage_split (not a CoreEntity?)")
		_finish()
		return

	_log_state(entity, "Initial state")

	# --- 1) Mangled limb: tissue 0, bone > 0 (part not targetable, not severed) ---
	print("\n--- Test 1: Mangled limb (right_arm: reduce tissue, keep bone) ---")
	var part: String = "right_arm"
	# Apply small repeated hits to wear down tissue; stop before severing
	var hits: int = 0
	while hits < 50:
		var cut_left: float = entity.body_cutting.get(part, 0.0)
		var blunt_left: float = entity.body_blunt.get(part, 0.0)
		var bone_left: float = entity.bone_health.get(part, 0.0) if entity.get("bone_health") else 0.0
		if cut_left <= 0.0 and blunt_left <= 0.0:
			break
		if bone_left <= 0.0:
			print("  [TestBattle] right_arm severed during test (bone=0); stopping.")
			break
		entity.take_damage_split(2.0, 2.0, part, 2.0)
		hits += 1
	var cut_after: float = entity.body_cutting.get(part, 0.0)
	var blunt_after: float = entity.body_blunt.get(part, 0.0)
	var bone_after: float = entity.bone_health.get(part, 0.0) if entity.get("bone_health") else 0.0
	var targetable: Array = entity.get_targetable_parts() if entity.has_method("get_targetable_parts") else []
	var is_mangled: bool = (cut_after <= 0.0 and blunt_after <= 0.0 and bone_after > 0.0)
	print("  right_arm after %d hits: cut=%.2f blunt=%.2f bone=%.2f | targetable=%s | mangled=%s" % [hits, cut_after, blunt_after, bone_after, str(targetable), is_mangled])

	# --- 2) Severed limb (left_leg): tissue 0, bone 0, stump wound ---
	print("\n--- Test 2: Severed limb (left_leg) + stump wound ---")
	part = "left_leg"
	hits = 0
	while hits < 30:
		if entity.has_method("_is_part_severed") and entity._is_part_severed(part):
			break
		if entity.has_method("_is_part_destroyed") and entity._is_part_destroyed(part):
			break
		entity.take_damage_split(6.0, 6.0, part, 3.0)
		hits += 1
	var severed: bool = entity._is_part_severed(part) if entity.has_method("_is_part_severed") else false
	var wounds: Dictionary = entity.get_wounds() if entity.has_method("get_wounds") else {}
	var stump_wounds: Array = wounds.get(part, [])
	var bleeding_rate: float = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	print("  left_leg severed=%s | wounds on part=%d | total_bleeding_rate=%.3f" % [severed, stump_wounds.size(), bleeding_rate])

	# --- 3) Chest wounds (cut + blunt) ---
	print("\n--- Test 3: Chest wounds (cut + blunt) ---")
	entity.take_damage_split(5.0, 3.0, "chest", 2.5)
	wounds = entity.get_wounds() if entity.has_method("get_wounds") else {}
	bleeding_rate = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	var blood_before: float = entity.get("blood_volume") if entity.get("blood_volume") != null else entity.blood_volume
	print("  chest wounds count=%d | total_bleeding_rate=%.3f | blood_volume=%.1f" % [wounds.get("chest", []).size(), bleeding_rate, blood_before])

	# --- 4) Bleeding tick + blood loss ---
	print("\n--- Test 4: process_bleeding(%.0f) + process_blood_loss(%.0f) ---" % [BLEED_TICK_S, BLEED_TICK_S])
	if entity.has_method("process_bleeding"):
		entity.process_bleeding(BLEED_TICK_S)
	if entity.has_method("process_blood_loss"):
		entity.process_blood_loss(BLEED_TICK_S)
	var blood_after: float = entity.get("blood_volume") if entity.get("blood_volume") != null else entity.blood_volume
	bleeding_rate = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	print("  after tick: blood_volume=%.1f | total_bleeding_rate=%.3f" % [blood_after, bleeding_rate])

	# --- 5) Bandage chest ---
	print("\n--- Test 5: apply_bandage(chest, 1.0) ---")
	if entity.has_method("apply_bandage"):
		entity.apply_bandage("chest", 1.0)
	bleeding_rate = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	print("  after bandage: total_bleeding_rate=%.3f" % bleeding_rate)
	if entity.has_method("process_bleeding"):
		entity.process_bleeding(5.0)
	bleeding_rate = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	print("  after 5s more clotting: total_bleeding_rate=%.3f" % bleeding_rate)

	# --- 6) Healing advance (tissue, bone, blood, wound resolution) ---
	print("\n--- Test 6: process_healing(%.0f s game time) ---" % HEAL_TICK_S)
	if entity.has_method("process_healing"):
		entity.process_healing(HEAL_TICK_S)
	_log_state(entity, "After healing tick")

	print("\n========================================")
	print("  Scripted tests done. Starting live combat.")
	print("========================================\n")
	# Defer so we're not inside _ready() when adding children (avoids "parent node is busy")
	_start_combat.call_deferred()

func _log_state(entity: Node, label: String) -> void:
	if entity == null:
		return
	var parts: Array = []
	if entity.has_method("_get_body_part_list"):
		parts = entity._get_body_part_list()
	elif entity.get("species") != null and "BODY_PARTS" in entity.get("species"):
		parts = (entity.get("species") as Resource).get("BODY_PARTS").duplicate()
	else:
		parts = ["head", "chest", "right_arm", "left_arm", "left_leg", "right_leg"]
	var targetable: Array = entity.get_targetable_parts() if entity.has_method("get_targetable_parts") else []
	var blood: float = entity.get("blood_volume") if entity.get("blood_volume") != null else entity.blood_volume
	var bleed_rate: float = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	var wounds: Dictionary = entity.get_wounds() if entity.has_method("get_wounds") else {}
	var game_time: float = entity.get_game_time_seconds() if entity.has_method("get_game_time_seconds") else 0.0
	print("[State] %s" % label)
	print("  targetable_parts=%s" % str(targetable))
	print("  blood_volume=%.1f | total_bleeding_rate=%.3f | game_time=%.0f s" % [blood, bleed_rate, game_time])
	for p in parts:
		var c: float = entity.body_cutting.get(p, 0.0)
		var b: float = entity.body_blunt.get(p, 0.0)
		var bo: float = entity.bone_health.get(p, 0.0) if entity.get("bone_health") else 0.0
		var cm: int = entity.body_max.get(p, 0)
		var bm: int = entity.bone_max.get(p, 0) if entity.get("bone_max") else 0
		var wcount: int = wounds.get(p, []).size()
		print("  %s: cut=%.2f blunt=%.2f bone=%.2f (max c/b %d/%d) wounds=%d" % [p, c, b, bo, cm, bm, wcount])

func _start_combat() -> void:
	# Remove test dummy from tree (we'll create fresh entities for combat)
	if _test_dummy != null:
		_test_dummy.queue_free()
		_test_dummy = null

	var enemy_scene: PackedScene = load("res://enemy/Enemy.tscn") as PackedScene
	if enemy_scene == null:
		print("[TestBattle] ERROR: Could not load Enemy.tscn for combat")
		_finish()
		return

	var human: Resource = load("res://species/human.tres") as Resource
	var goblin: Resource = load("res://species/goblin.tres") as Resource
	var sword: RefCounted = null
	if WeaponClass:
		sword = WeaponClass.create_from_definition("short_sword")
	if sword == null:
		print("[TestBattle] WARNING: No weapon for combat; attacks may use fallback damage.")

	var player_entity: Node = enemy_scene.instantiate()
	player_entity.set("name", "TestPlayer")
	player_entity.set("species", human)
	if player_entity.has_method("apply_species"):
		player_entity.apply_species()
	if player_entity.has_method("equip_weapon") and sword != null:
		player_entity.equip_weapon(sword)
	add_child.call_deferred(player_entity)

	var enemy_entity: Node = enemy_scene.instantiate()
	enemy_entity.set("name", "TestEnemy")
	enemy_entity.set("species", goblin)
	if enemy_entity.has_method("apply_species"):
		enemy_entity.apply_species()
	if enemy_entity.has_method("equip_weapon") and sword != null:
		enemy_entity.equip_weapon(sword)
	add_child.call_deferred(enemy_entity)

	var battle_script: GDScript = load("res://ui/BattleScene.gd") as GDScript
	if battle_script == null:
		print("[TestBattle] ERROR: Could not load BattleScene.gd")
		_finish()
		return
	_battle = battle_script.new()
	_battle.set("parent_scene", self)
	get_tree().root.add_child.call_deferred(_battle)
	if _battle.has_signal("battle_ended"):
		_battle.battle_ended.connect(_on_battle_ended)
	# Wait one frame so battle is ready, then start
	await get_tree().process_frame
	if _battle.has_method("start"):
		_battle.start(player_entity, enemy_entity)
	_phase = "combat"

func _on_battle_ended(winner: String, defeated: Node) -> void:
	print("\n[TestBattle] Combat ended. Winner: %s" % winner)
	if defeated != null:
		print("  Defeated: %s" % defeated.name)
	# Optionally log survivor state and run a healing tick
	var survivor: Node = null
	for child in get_children():
		if child is Node2D and child != _battle:
			if child.has_method("is_dead") and not child.is_dead():
				survivor = child
				break
	if survivor != null and _phase == "combat":
		_log_state(survivor, "Survivor after combat")
		print("\n--- Post-combat healing (1 hour game time) ---")
		if survivor.has_method("process_healing"):
			survivor.process_healing(HEAL_TICK_S)
		_log_state(survivor, "Survivor after healing")
	_phase = "done"
	_finish()

func _finish() -> void:
	print("\n[TestBattle] Test run complete. Close the window or run main scene for normal game.")
	# Don't quit automatically; let user read output
