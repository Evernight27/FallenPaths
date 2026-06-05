class_name ContractSpawner
extends RefCounted

## Campaign contract markers (Camp-1.4). Tutorial + two paid jobs per run when not in dev soak mode.
const _EncounterNodeScript := preload("res://world/EncounterNode.gd")
const _CompanyState := preload("res://world/CompanyState.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _CombatConstants := preload("res://combat/CombatConstants.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const CAMP_TILE := Vector2i(0, 0)
const TUTORIAL_TILE := Vector2i(1, 0)

const TUTORIAL_TEMPLATE: Dictionary = {	"contract_type": "tutorial",
	"contract_title": "Training Drills",
	"tutorial": true,
	"pay_gold": 0,
	"difficulty_rating": 1,
	"enemy_count": 2,
	"map_bleed_mult": 0.25,
}

## §18 SHIP_PLAN — EA paid deck (two jobs per run).
const CONTRACT_TEMPLATES: Array = [
	{
		"contract_type": "skirmish",
		"contract_title": "Border Skirmish",
		"pay_gold": 100,
		"difficulty_rating": 1,
		"enemy_count": 3,
		"map_bleed_mult": 1.0,
		"enemy_species_pool": [ResourcePaths.HUMAN_SPECIES],
		"soak_force_weapon_id": "SWORD",
		CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT: 7,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: CombatConstants.DOCTRINE_PINCH_CENTER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
	},
	{
		"contract_type": "escort",
		"contract_title": "Escort Duty",
		"pay_gold": 120,
		"difficulty_rating": 2,
		"enemy_count": 5,
		"map_bleed_mult": 0.85,
		"enemy_species_pool": [ResourcePaths.HUMAN_SPECIES],
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
		"flee_line_cohesion_max_enemy": 0.42,
		"flee_casualty_ratio_min_enemy": 0.35,
	},
]

static func spawn_campaign_contracts(
	parent: Node2D, rng: RandomNumberGenerator, enemy_scene: PackedScene
) -> void:
	if parent == null or rng == null:
		return
	var reserved: Array = _reserve_tiles(parent)
	if not _CompanyState.is_tutorial_completed(parent):
		var t_tile: Vector2i = TUTORIAL_TILE if TUTORIAL_TILE not in reserved else _first_free_tile(reserved)
		if t_tile.x >= 0:
			reserved.append(t_tile)
			_spawn_contract_at_tile(parent, t_tile, TUTORIAL_TEMPLATE, enemy_scene)
	var free_tiles: Array = _free_contract_tiles(parent, reserved)
	free_tiles.shuffle()
	var placed: int = 0
	for i in range(CONTRACT_TEMPLATES.size()):
		if placed >= free_tiles.size():
			break
		var tile: Vector2i = free_tiles[placed] as Vector2i
		placed += 1
		var scaled: Dictionary = scale_template_for_renown(parent, CONTRACT_TEMPLATES[i])
		_spawn_contract_at_tile(parent, tile, scaled, enemy_scene)


static func get_template_count() -> int:
	return CONTRACT_TEMPLATES.size()


## After soft defeat (tutorial), re-place marker if the tile is empty.
static func ensure_special_encounter_present(
	parent: Node2D, _rng: RandomNumberGenerator, enemy_scene: PackedScene, contract: Dictionary
) -> void:
	if parent == null or contract.is_empty():
		return
	if not bool(contract.get("tutorial", false)):
		return
	var reserved: Array = _reserve_tiles(parent)
	if _encounter_on_tile(parent, TUTORIAL_TILE):
		return
	var tile: Vector2i = TUTORIAL_TILE if TUTORIAL_TILE not in reserved else _first_free_tile(reserved)
	if tile.x < 0:
		return
	_spawn_contract_at_tile(parent, tile, TUTORIAL_TEMPLATE, enemy_scene)


static func build_encounter_config(template: Dictionary) -> Dictionary:
	return template.duplicate(true)


## Camp-1.7: later-run contracts spawn more enemies (renown / 2 floored, cap +2).
static func scale_template_for_renown(parent: Node, template: Dictionary) -> Dictionary:
	var out: Dictionary = template.duplicate(true)
	if bool(out.get("tutorial", false)) or bool(out.get("training", false)):
		return out
	if parent == null:
		return out
	var renown: int = _CompanyState.get_renown(parent)
	var bonus: int = mini(maxi(0, renown >> 1), 2)
	var base_n: int = int(out.get("enemy_count", 3))
	out["enemy_count"] = mini(base_n + bonus, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
	return out


static func format_marker_label(template: Dictionary, world: Node = null) -> String:
	if bool(template.get("tutorial", false)):
		return "Tutorial\n2v2 · learn basics"
	var title: String = str(template.get("contract_title", "Job"))
	var pay: int = int(template.get("pay_gold", 0))
	var skulls: int = int(template.get("difficulty_rating", 1))
	var pay_line: String = "%dg" % pay
	if world != null and pay > 0:
		var renown: int = _CompanyState.get_renown(world)
		if renown > 0:
			var scaled: int = int(
				round(float(pay) * (1.0 + float(renown) * _CompanyState.RENOWN_PAY_SCALE))
			)
			if scaled > pay:
				pay_line = "%dg (renown ~%dg)" % [pay, scaled]
	var enemy_n: int = int(template.get("enemy_count", 0))
	var enemy_hint: String = ""
	if enemy_n > 0:
		enemy_hint = " · %d foes" % enemy_n
	var bleed_mult: float = float(template.get("map_bleed_mult", 1.0))
	var bleed_hint: String = ""
	if bleed_mult < 0.99 and not bool(template.get("tutorial", false)):
		bleed_hint = " · map bleed ×%.0f%%" % (bleed_mult * 100.0)
	var flavor_hint: String = _format_combat_flavor_hint(template)
	return "%s\n%s · %s%s%s%s" % [
		title,
		pay_line,
		"★".repeat(mini(3, maxi(1, skulls))),
		enemy_hint,
		bleed_hint,
		flavor_hint,
	]


static func _format_combat_flavor_hint(template: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	var weapon_id: String = str(
		template.get(_SoakPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID, "")
	).strip_edges()
	if not weapon_id.is_empty():
		bits.append(weapon_id.to_lower())
	var doctrine: String = str(
		template.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, "")
	).strip_edges()
	if doctrine.is_empty():
		doctrine = str(template.get(_CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT, "")).strip_edges()
	if not doctrine.is_empty():
		bits.append("foes " + doctrine.replace("_", " "))
	var depth: Variant = template.get(_CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY, {})
	if depth is Dictionary and not (depth as Dictionary).is_empty():
		bits.append("depth spears")
	if bits.is_empty():
		return ""
	return "\n" + " · ".join(bits)


static func build_enemy_formation_for_template(template: Dictionary) -> Dictionary:
	var n: int = mini(int(template.get("enemy_count", 1)), CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
	if bool(template.get("tutorial", false)):
		return {"files": 2, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
	return FormationPreset.default_for_count(n)


## Restore one saved encounter marker (D-persistence P2 load).
static func spawn_saved_encounter_at_tile(
	parent: Node,
	tile: Vector2i,
	encounter_config: Dictionary,
	enemy_count: int,
	enemy_formation: Dictionary,
	contract_marker_label: String,
	marker_kind: String,
	enemy_scene: PackedScene
) -> void:
	if parent == null or tile.x < 0:
		return
	var scene := enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	var encounter = _EncounterNodeScript.new()
	encounter.position = _CampaignBridge.overworld_tile_center(tile)
	encounter.enemy_count = mini(enemy_count, CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP)
	if scene != null:
		encounter.enemy_scene = scene
	encounter.encounter_config = encounter_config.duplicate(true)
	if enemy_formation.is_empty():
		encounter.enemy_formation = build_enemy_formation_for_template(encounter_config)
	else:
		encounter.enemy_formation = enemy_formation.duplicate(true)
	encounter.contract_marker_label = contract_marker_label
	encounter.marker_kind = marker_kind
	parent.add_child(encounter)


static func _spawn_contract_at_tile(
	parent: Node,
	tile: Vector2i,
	template: Dictionary,
	enemy_scene: PackedScene
) -> void:
	var scene := enemy_scene
	if scene == null:
		scene = load(ResourcePaths.ENEMY_SCENE) as PackedScene
	var encounter = _EncounterNodeScript.new()
	encounter.position = _CampaignBridge.overworld_tile_center(tile)
	encounter.enemy_count = mini(
		int(template.get("enemy_count", 3)), CombatConstants.FORMATION_UNIT_COUNT_HARD_CAP
	)
	if scene != null:
		encounter.enemy_scene = scene
	encounter.encounter_config = build_encounter_config(template)
	encounter.enemy_formation = build_enemy_formation_for_template(template)
	encounter.contract_marker_label = format_marker_label(template, parent)
	encounter.marker_kind = "tutorial" if bool(template.get("tutorial", false)) else "contract"
	parent.add_child(encounter)


static func _encounter_on_tile(parent: Node, tile: Vector2i) -> bool:
	if parent == null or tile.x < 0:
		return false
	for child in parent.get_children():
		if child.get_script() == _EncounterNodeScript and _CampaignBridge.overworld_tile_from_position(child.position) == tile:
			return true
	return false


static func _reserve_tiles(parent: Node) -> Array:
	var used: Array = [CAMP_TILE]
	if parent.has_node("Character"):
		used.append(_CampaignBridge.overworld_tile_from_position(parent.get_node("Character").position))
	for child in parent.get_children():
		if child.get_script() == _EncounterNodeScript:
			used.append(_CampaignBridge.overworld_tile_from_position(child.position))
	return used


static func _free_contract_tiles(_parent: Node, reserved: Array) -> Array:
	var out: Array = []
	for x in range(3):
		for y in range(3):
			var t := Vector2i(x, y)
			if t not in reserved:
				out.append(t)
	return out


static func _first_free_tile(reserved: Array) -> Vector2i:
	for x in range(3):
		for y in range(3):
			var t := Vector2i(x, y)
			if t not in reserved:
				return t
	return Vector2i(-1, -1)
