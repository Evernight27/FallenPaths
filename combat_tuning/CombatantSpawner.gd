class_name CombatantSpawner
extends RefCounted

## Creates and configures CoreEntity combatants for the tuning scene.
## Wraps the 1v1 setup pattern from CombatRegressionHarnessProficiency1v1Tail.

const _CoreEntity := preload("res://core/CoreEntity.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
static var _entity_access_cache: Variant = null

static func _get_entity_access() -> GDScript:
	if CombatantSpawner._entity_access_cache == null:
		CombatantSpawner._entity_access_cache = load("res://combat/CombatantEntityAccess.gd")
	return CombatantSpawner._entity_access_cache
const _WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _StatsSync := preload("res://combat/CombatantStatsSync.gd")
const _ConfigData := preload("res://combat_tuning/TuningConfigData.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
## Returns {attacker_entity, defender_entity, attacker_id, defender_id}.
static func spawn_1v1(
	manager: Node,
	attacker_cfg: Variant,
	defender_cfg: Variant
) -> Dictionary:
	var atk_ent: Node = _create_entity(attacker_cfg)
	var def_ent: Node = _create_entity(defender_cfg)

	var atk_id: int = manager.register(atk_ent, "player")
	var def_id: int = manager.register(def_ent, "enemy")

	return {
		"attacker_entity": atk_ent,
		"defender_entity": def_ent,
		"attacker_id": atk_id,
		"defender_id": def_id,
		"attacker_config": attacker_cfg,
		"defender_config": defender_cfg,
	}

## Creates a single CoreEntity from config.
static func _create_entity(cfg: Variant) -> Node:
	var e := _CoreEntity.new()
	if not cfg.species_tres_path.is_empty() and ResourceLoader.exists(cfg.species_tres_path):
		e.species = load(cfg.species_tres_path)
	e.apply_species()
	e.name = cfg.display_name
	var hands: Array[String] = ["right_arm", "left_arm"]
	e.dominant_hand = hands[randi() % hands.size()]
	e.offhand_functionality = 1.0
	e._proficiency_bonus = {"strength": 0, "endurance": 0, "intelligence": 0, "agility": 0, "perception": 0}

	e.strength = cfg.strength
	e.agility = cfg.agility
	e.intelligence = cfg.intelligence
	e.endurance = cfg.endurance
	e.perception = cfg.perception

	var w := _Weapon.create_from_definition(cfg.weapon_id)
	if w != null:
		e.equip_weapon(w)

	# Apply armor from config overrides
	for part in cfg.armor_overrides:
		var armor_def := _ArmorPiece.create_from_definition(cfg.armor_overrides[part])
		if armor_def != null:
			e.equip_armor(str(part), armor_def)

	print("[Tuning] Entity '%s': body_cutting=%s body_blunt=%s dominant_hand=%s weapon=%s armor=%s" % [
		e.name, str(e.body_cutting), str(e.body_blunt), e.dominant_hand, "yes" if w != null else "no", str(cfg.armor_overrides)
	])

	return e

## Full reset: heal entity, reset combatant dicts, restore form/guard.
static func reset_combatants(
	manager: Node,
	atk_ent: Node, def_ent: Node,
	atk_id: int, def_id: int,
	atk_cfg: Variant,
	def_cfg: Variant
) -> void:
	_heal_entity(atk_ent)
	_heal_entity(def_ent)

	for c in manager.combatants:
		c.state = _CombatConstants.STATE_WAITING
		c.stamina = _CombatConstants.STAMINA_MAX
		c.pending_attack = {}

	var atk_c: Dictionary = _get_entity_access().manager_get_combatant(manager, atk_id)
	var def_c: Dictionary = _get_entity_access().manager_get_combatant(manager, def_id)

	if not atk_c.is_empty():
		_WeaponForm.assign_form(manager, atk_c, atk_cfg.form, "harness_baseline")
		atk_c["guard_line"] = atk_cfg.guard_line
		_StatsSync.sync_from_entity(atk_ent, _get_entity_access().stats_dict_for_mutation(atk_c))

	if not def_c.is_empty():
		_WeaponForm.assign_form(manager, def_c, def_cfg.form, "harness_baseline")
		def_c["guard_line"] = def_cfg.guard_line
		_StatsSync.sync_from_entity(def_ent, _get_entity_access().stats_dict_for_mutation(def_c))

## Restores entity to full health across all body parts.
static func _heal_entity(e: Node) -> void:
	if e == null or not is_instance_valid(e):
		return
	for part in _ConfigData.BODY_PARTS:
		if part in e.body_max:
			e.body_cutting[part] = e.body_max[part]
		if part in e.body_blunt:
			e.body_blunt[part] = e.body_max[part]
		if part in e.bone_max:
			e.bone_health[part] = e.bone_max[part]
	e.blood_volume = 100.0
	e.consciousness = 100.0
	e.effective_consciousness = 100.0
	# Clear wounds
	e.wounds = {}
	# Reset pain/shock
	e._pain_shock_until_time = -1.0
	e._last_hit_impact = 0.0
	e._ambient_pain_shock_accum = 0.0
	e._consciousness_dirty = true
	e.ensure_consciousness_current()
