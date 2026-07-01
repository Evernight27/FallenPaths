class_name TuningConfigData
extends RefCounted

## Serializable config structures for the combat tuning scene.
## Each combatant has species, stats, weapon, form, guard.

const _Bp := preload("res://core/BodyPartConstants.gd")
const _ArmorConst := preload("res://armor/ArmorConstants.gd")

const SPECIES_OPTIONS: Array[String] = [
	"res://species/human.tres",
	"res://species/goblin.tres",
]

# Body part order used for display and serialization.
const BODY_PARTS: Array[String] = [
	_Bp.PART_HEAD,
	_Bp.PART_CHEST,
	_Bp.PART_RIGHT_ARM,
	_Bp.PART_LEFT_ARM,
	_Bp.PART_RIGHT_LEG,
	_Bp.PART_LEFT_LEG,
]

## Per-combatant config: what to spawn and how to configure it.
class TuningCombatantConfig:
	var display_name: String = "Attacker"
	var species_tres_path: String = "res://species/human.tres"
	var strength: int = 100
	var agility: int = 100
	var intelligence: int = 100
	var endurance: int = 100
	var perception: int = 100
	var weapon_id: String = "SWORD"
	var form: String = "balanced"
	var guard_line: String = "high"
	var armor_overrides: Dictionary = {}  # part -> armor_resource_path

	var _randomize_stats: bool = false
	var _randomize_weapon: bool = false
	var _randomize_form: bool = false
	var _randomize_guard: bool = false
	var _randomize_armor: bool = false
	var _armor_count: int = 0

	func _init(
		p_name: String = "Attacker",
		p_weapon: String = "SWORD",
		p_form: String = "balanced",
		p_guard: String = "high",
		p_str: int = 100, p_agi: int = 100, p_int: int = 100, p_end: int = 100, p_per: int = 100
	):
		display_name = p_name
		weapon_id = p_weapon
		form = p_form
		guard_line = p_guard
		strength = p_str
		agility = p_agi
		intelligence = p_int
		endurance = p_end
		perception = p_per

	func randomize() -> void:
		display_name = ["Warrior", "Mercenary", "Sellsword", "Veteran", "Rogue", "Berserker", "Shield-bearer", "Skirmisher"][randi() % 8]

		strength = randi() % 61 + 70  # 70-130
		agility = randi() % 61 + 70
		intelligence = randi() % 61 + 70
		endurance = randi() % 61 + 70
		perception = randi() % 61 + 70

		var weapons := ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
		weapon_id = weapons[randi() % weapons.size()]

		var forms := ["balanced", "wrath", "plow", "fool", "ox", "wall", "tempest"]
		form = forms[randi() % forms.size()]

		var guards := ["high", "low", "left", "right"]
		guard_line = guards[randi() % guards.size()]

		species_tres_path = SPECIES_OPTIONS[randi() % SPECIES_OPTIONS.size()]

		armor_overrides.clear()
		_armor_count = randi() % 3  # 0-2 armor pieces
		var all_parts := ["head", "chest", "right_arm", "left_arm", "right_leg", "left_leg"]
		var parts_to_armor := []
		for i in _armor_count:
			if parts_to_armor.size() >= all_parts.size():
				break
			var available := []
			for p in all_parts:
				if not p in parts_to_armor:
					available.append(p)
			if available.is_empty():
				break
			parts_to_armor.append(available[randi() % available.size()])
		for part in parts_to_armor:
			var options: Array = _ArmorConst.get_armor_options_by_part().get(part, [])
			if not options.is_empty():
				armor_overrides[part] = options[randi() % options.size()]

	static func random_configs_pair() -> Array[TuningCombatantConfig]:
		var atk := TuningCombatantConfig.new("Attacker")
		var def := TuningCombatantConfig.new("Defender")
		atk.randomize()
		def.randomize()
		return [atk, def]

	func to_dict() -> Dictionary:
		return {
			"display_name": display_name,
			"species_tres_path": species_tres_path,
			"strength": strength,
			"agility": agility,
			"intelligence": intelligence,
			"endurance": endurance,
			"perception": perception,
			"weapon_id": weapon_id,
			"form": form,
			"guard_line": guard_line,
			"armor_overrides": armor_overrides.duplicate(),
		}

	static func from_dict(d: Dictionary) -> TuningCombatantConfig:
		var c := TuningCombatantConfig.new(
			d.get("display_name", "Fighter"),
			d.get("weapon_id", "SWORD"),
			d.get("form", "balanced"),
			d.get("guard_line", "high"),
			d.get("strength", 100),
			d.get("agility", 100),
			d.get("intelligence", 100),
			d.get("endurance", 100),
			d.get("perception", 100)
		)
		c.species_tres_path = d.get("species_tres_path", "res://species/human.tres")
		var ao: Variant = d.get("armor_overrides", {})
		if ao is Dictionary:
			c.armor_overrides = (ao as Dictionary).duplicate()
		return c

## Default attacker: sword, balanced form, 110/100/105/105/95 stats.
static func default_attacker_config() -> TuningCombatantConfig:
	var c := TuningCombatantConfig.new(
		"Attacker", "SWORD", "balanced", "high",
		110, 100, 105, 105, 95
	)
	c._randomize_stats = false
	c._randomize_weapon = false
	c._randomize_form = false
	c._randomize_guard = false
	c._randomize_armor = false
	return c

## Default defender: sword, plow form (defensive), 100/100/100/100/100 stats.
static func default_defender_config() -> TuningCombatantConfig:
	var c := TuningCombatantConfig.new(
		"Defender", "SWORD", "plow", "middle",
		100, 100, 100, 100, 100
	)
	c._randomize_stats = false
	c._randomize_weapon = false
	c._randomize_form = false
	c._randomize_guard = false
	c._randomize_armor = false
	return c

## Standard heavy vs light scenario.
static func heavy_vs_light_configs() -> Array[TuningCombatantConfig]:
	return [
		TuningCombatantConfig.new("Heavy", "MACE", "wrath", "high", 140, 80, 90, 130, 80),
		TuningCombatantConfig.new("Light", "SWORD", "fool", "low", 80, 140, 100, 80, 120),
	]

## Spear vs sword.
static func spear_vs_sword_configs() -> Array[TuningCombatantConfig]:
	return [
		TuningCombatantConfig.new("Spear", "SPEAR", "ox", "middle", 110, 100, 100, 100, 100),
		TuningCombatantConfig.new("Sword", "SWORD", "balanced", "high", 100, 100, 100, 100, 100),
	]
